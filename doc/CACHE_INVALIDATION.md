# SLA cache invalidation

## Configuration changes

Configuration callbacks capture the affected SLA IDs before saving or
destroying a record. `RedmineSla::InvalidatesSlaCache` passes those IDs to
`SlaCache.invalidate_slas`, which deletes every cache row whose level belongs
to one of those SLAs. The database foreign key also deletes the related
`SlaCacheSpent` rows. The next issue read, or the `update_sla` task, rebuilds
the calculation.

The affected SLAs are determined by the changed configuration:

- Calendars, schedules, calendar-holiday links and holidays affect the SLAs
  using the old or new calendars.
- Levels and terms affect the old and new SLAs containing those levels.
- Issue custom fields and their enumerations affect SLAs whose levels use
  those fields as priority sources.
- Deleting or reassigning a native issue priority affects SLAs with terms for
  that priority. Redmine's reassignment uses `update_all`, so issue callbacks
  do not run.

Name and description edits that do not alter calculations preserve caches.
Failed saves do not invalidate; transaction rollbacks restore cache deletions
with the configuration changes.

## Issue changes

When an issue's project, tracker, native priority or an SLA priority custom
field value changes, its cache is deleted. This applies to custom-field values
saved through `Issue#save`, after Redmine persists them. The cache and spent
time are rebuilt on the next read, rather than recalculated inside the issue
save request.

Project/tracker SLA mappings invalidate caches for the old and new
project/tracker pair. `SlaStatus` changes do not affect level selection; they
delete only the spent-time caches for the affected SLA type.

The cache deletion entry points are `SlaCache.invalidate_slas`,
`SlaCache.invalidate_project_tracker` and `SlaCache.invalidate_issue`.
Direct SQL or Active Record writes that bypass these callbacks must invalidate
the affected cache explicitly.

## Tests

`sla_cache_invalidation_test.rb` covers configuration, issue-priority,
custom-field, enumeration, project/tracker mapping and status changes.
`sla_issue_cache_freshness_test.rb` verifies that issue saves delete stale
caches without calling the SLA SQL calculation functions; the next read
recalculates the issue.
