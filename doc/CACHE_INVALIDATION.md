# SLA cache invalidation

Configuration changes invalidate cached calculations without saving or touching
`SlaLevel` records. `RedmineSla::InvalidatesSlaCache` captures dependencies before
save or destruction and deletes matching `SlaCache` records afterwards, inside
the same transaction. The database foreign key deletes their `SlaCacheSpent`
records. A subsequent read recalculates the SLA level and spent time.

## Dependency rules

- Schedule and calendar-holiday changes invalidate every level of the
  SLAs using the affected calendars. A cache can reference another competing
  level (for example HO versus HNO), whose selection is now obsolete.
- Moving a schedule or calendar-holiday link includes both calendars.
- Holiday date changes include every linked calendar and its competing levels.
  Calendar name/description and holiday name changes preserve caches and do not
  query their cache dependencies. Nested schedule changes still invalidate caches.
- Creating a level invalidates existing candidates of its SLA. Changing its SLA
  or calendar invalidates candidates of both the old and new SLA. Other level
  changes and level destruction invalidate its own caches.
- Term changes invalidate their level; moving a term includes both levels.
- Calendar and holiday destruction also removes their calendar-holiday links.
  Dependencies are captured before dependent associations are destroyed; the
  parent invalidates once and removes schedules/links in bulk with Rails
  `dependent: :delete_all`. Their only destruction callback was the redundant
  cache invalidation. Direct schedule/link destruction and nested schedule
  deletion still run their own invalidation callbacks.
- Validation failure preserves caches. Transaction rollback restores configuration,
  links and caches together. A metadata-only save also clears any dependencies
  left by an aborted destruction on the same model instance. Bulk cleanup also
  avoids reusing dependencies left by an earlier aborted child destruction.

## Write-path review (2026-10-24)

The controllers for calendars, schedules, calendar-holiday links, holidays,
levels and terms use Active Record save/update/destroy methods, including bulk
controller deletions and nested schedules/terms. These paths execute the
invalidation callbacks. The dependent schedule/link cleanup uses bulk deletion,
covered by the parent's captured dependencies. Other configuration writes in
these paths do not bypass callbacks.

Direct SQL and Active Record writes that skip callbacks remain outside this
mechanism. External scripts must explicitly invalidate affected caches.
Existing orphaned calendar-holiday links are not repaired by this change.

## Validation and query cost

The 35 invalidation tests check affected and unaffected cache/spent rows,
creation, reassignment, dependent destruction, nested edits, invalid saves,
rollback and aborted destruction. A real SQL recalculation selects HNO instead
of HO on the next read after a competing schedule changes.

The query assertions count dependency SELECTs and cache DELETEs, excluding
validation queries, child-row deletion, transactions and test verification reads.
On Redmine 6.1.4 / PostgreSQL 17, the same generated fixtures and added child
records give the following comparison against the initial 3.1.4 commit
(`a04ae8b`):

| Operation | Initial implementation | Optimized implementation |
| --- | --- | --- |
| Calendar name/description or holiday name edit | Deletes useful caches | Preserves cache/spent rows; 0 invalidation queries |
| Destroy calendar with 10 schedules and 54 holiday links (10 added) | 130 invalidation queries | 2 (resolve levels, delete caches) |
| Destroy holiday linked to all 7 fixture calendars | 17 invalidation queries | 3 (resolve calendars, resolve levels, delete caches) |

The optimized query counts are asserted on every database in the release
matrix. They stay independent of the number of dependent schedules/links;
the number of deleted rows still scales with that number, while dependent
cleanup uses one DELETE per association. These are SQL workload
measurements in isolated tests, not production latency benchmarks.

The full compatibility results and SQL modes are recorded in
[Testing](TESTING.md#version-314-competing-level-cache-invalidation).
MariaDB is tested separately from strict MySQL; its existing `sla_get_spent`
aggregate-query limitation with `ONLY_FULL_GROUP_BY` remains outside this change.
