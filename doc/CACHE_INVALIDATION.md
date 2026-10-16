# SLA cache invalidation

Configuration changes invalidate cached calculations without saving or touching
`SlaLevel` records. `RedmineSla::InvalidatesSlaCache` captures dependencies before
save or destruction and deletes matching `SlaCache` records afterwards, inside
the same transaction. The database foreign key deletes their `SlaCacheSpent`
records. A subsequent read recalculates the SLA level and spent time.

## Dependency rules

- Calendar, schedule and calendar-holiday changes invalidate every level of the
  SLAs using the affected calendars. A cache can reference another competing
  level (for example HO versus HNO), whose selection is now obsolete.
- Moving a schedule or calendar-holiday link includes both calendars.
- Holiday changes include every linked calendar and its competing levels.
- Creating a level invalidates existing candidates of its SLA. Changing its SLA
  or calendar invalidates candidates of both the old and new SLA. Other level
  changes and level destruction invalidate its own caches.
- Term changes invalidate their level; moving a term includes both levels.
- Issue custom field changes and deletion, and creating, changing, moving or
  deleting one of its enumeration values (with or without reassignment),
  invalidate the levels using that field. Moving a value includes its previous
  field. Other fields keep their caches.
- Calendar and holiday destruction also removes their calendar-holiday links.
  Dependencies are captured before dependent associations are destroyed.
- Validation failure preserves caches. Transaction rollback restores configuration,
  links and caches together.

## Write-path review (2026-10-11)

The controllers for calendars, schedules, calendar-holiday links, holidays,
levels and terms use Active Record save/update/destroy methods, including bulk
controller deletions and nested schedules/terms. The holiday importer (3.3.0)
uses `create!`. These paths execute the invalidation callbacks. No configuration
write bypass using `update_all`, `delete_all`, `insert_all`, `upsert_all` or
`update_columns` was found in these paths.

Direct SQL and Active Record writes that skip callbacks remain outside this
mechanism. External scripts must explicitly invalidate affected caches.
Existing orphaned calendar-holiday links are not repaired by this change.

## Validation

Validated on Redmine 6.1.4 in isolated containers with generated plugin fixtures:

| Database | Unit tests | Controller tests | SQL mode |
| --- | --- | --- | --- |
| PostgreSQL 17 | 186 passed | 435 passed | Native PostgreSQL |
| MySQL 8.0 | 186 passed | 435 passed | `STRICT_TRANS_TABLES,ONLY_FULL_GROUP_BY,NO_ENGINE_SUBSTITUTION` |
| MariaDB 10.11 | 186 passed | 435 passed | `STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION` |

The unit suite includes 27 invalidation tests, checking affected and unaffected
cache/spent rows, rollback, creation, reassignment, dependent destruction, nested
schedule deletion and a real SQL recalculation from HO to HNO on the next read.
Four regression cases failed before the corrections and passed afterwards.

Enabling `ONLY_FULL_GROUP_BY` on MariaDB exposed an existing aggregate-query
error in `sla_get_spent`, preventing cache preparation. This SQL-function issue
is separate from callback invalidation and remains unresolved. MySQL passes
with `ONLY_FULL_GROUP_BY` enabled. The 3.1.4 release then passed all five
suites on Redmine 5.1.13, 6.1.4 and 7.0.1 with each database: see
[Testing](TESTING.md#version-314-competing-level-cache-invalidation).
