# Changelog

## Unreleased

------------------------------------------------------------------------

## 3.0.1 - 2026-09-05

### Security

-   Scope SLA cache visibility and mutations to projects where the user has
    the corresponding `view_sla` or `manage_sla` permission, while keeping
    global purge restricted to administrators.

### Fixed

-   Validate schedule overlaps in the model so direct and nested writes are
    rejected atomically on every supported database.
-   Invalidate only the affected SLA caches after calendar, schedule, holiday,
    level or term configuration changes.
-   Reject SLA terms referencing missing issue priorities or custom-field
    enumerations.
-   Display negative-term validation errors instead of raising from a model
    translation call.
-   Restore SLA term grouping by priority label and align calendar-holiday
    ordering with holiday dates.

### Maintenance

-   Remove obsolete commented implementations and inline TODO markers; ongoing
    feature work remains tracked in the project backlog.

### Testing

-   Report real `sla_get_level` forced/cached and `sla_get_spent` calculation
    durations (`min`, `median`, `p95`, `max` and `avg`) during the unit suite,
    labelled by database engine, without imposing environment-dependent
    performance thresholds.
-   Cover project-scoped anonymous/member access, atomic calendar validation,
    cache invalidation and SLA priority reference validation.

------------------------------------------------------------------------

## 3.0.0

### Added

-   Add MySQL 8.0+ and MariaDB 10.2+ support alongside PostgreSQL. Database
    views and SLA calculation functions are selected through an explicit
    adapter dialect.
-   Provide an adapter-neutral Ruby service for the on-demand SLA explanation
    view, preserving the same diagnostic output on every supported database.

### Performance

-   Reduce repeated holiday lookups in SLA level and spent-time calculations,
    and enumerate level candidates day by day to avoid recursive CTE limits on
    long-running issues.
-   Keep cache purges efficient and portable with scoped `DELETE` operations.

### Compatibility

-   Preserve the 2.2.x cache permissions and PATCH-only mutation routes.
-   Preserve and validate the ordered, non-null `sla_types.position` migration
    on PostgreSQL, MySQL and MariaDB.

------------------------------------------------------------------------

## 2.2.2 (Stable - Redmine 6.x)

### Security

-   Require `manage_sla` on every affected project before refreshing,
    deleting or purging SLA caches; users with `view_sla` keep read-only
    access to caches belonging to issues they can see.
-   Keep global cache purges restricted to administrators and prevent a
    project-scoped request from mutating caches belonging to another project.
-   Replace state-changing cache refresh and purge `GET` routes with `PATCH`
    routes so Rails applies its normal CSRF protection.

------------------------------------------------------------------------

## 2.2.1 (Stable - Redmine 6.x)

### Fixed

-   Fix upgrades from versions created before SLA type ordering: existing
    `sla_types` now receive deterministic positions from `1` to `N` in their
    previous creation order, and the resulting column is enforced as non-null.
-   Make the position backfill work across PostgreSQL, MySQL/MariaDB and SQLite
    instead of relying on PostgreSQL-specific SQL.

------------------------------------------------------------------------

## 2.2.0 (Stable - Redmine 6.x)

### Added

-   Add: SLA types can now be reordered from a dedicated, drag-and-drop
    `/sla/types` list (Redmine core's own `reorder_handle`/
    `positionedItems`, the same mechanism used for Tracker/IssueStatus).
    The order now applies everywhere a SLA type is displayed: issue
    gauges, the "Explain" view, issue/time-entry columns, and the SLA
    Level Terms editing matrix — previously always shown in creation
    (id) order. Reordering is active only when the list is in its
    natural state (no filter, sorted by position, single page); filtering,
    sorting and CSV export keep working the rest of the time.
-   Add: the SLA Level Terms matrix now masks SLA types that have no term
    yet for the current level once it has at least one — a level being
    set up for the first time still shows every type, but a populated one
    only shows its used types by default, with a "Show hidden SLA types"
    toggle to reveal the rest.

### Changed

-   Change: rewrite the SLA Level Terms matrix to Redmine's native
    `table.list` look, dropping the hand-rolled inline-style borders and a
    colspan/rowspan corner-label trick.

### Documentation

-   Doc: documentation screenshots no longer include Redmine's `#header`/
    `#footer` chrome and are auto-trimmed to their actual content instead
    of the blank space Redmine reserves below short forms — cuts
    `doc/screenshots` from 19MB to 16MB despite adding 10 previously
    missing "Explain" screenshots.

------------------------------------------------------------------------

## 2.1.7 (Stable - Redmine 6.x)

### Refactoring

-   Refactor: `SlaCache`, `Issue` and `TimeEntry` each defined a
    `get_sla_respect_<id>` accessor (and `SlaCache` also
    `get_sla_remain/spent/term_<id>`) per `SlaType`, via `define_method`
    loops run once at boot and patched on creation through
    `SlaTypesController#post_create`/`post_destroy` — except
    `post_destroy` was never actually called from `destroy`, leaving
    dangling accessor methods on all three classes after deleting a
    SlaType. Replaced with a generic `method_missing`/`respond_to_missing?`
    on each class that resolves `get_sla_*_<id>` for any id without
    predefining it, so a SlaType works immediately whether created before
    or after the server booted.

------------------------------------------------------------------------

## 2.1.6 (Stable - Redmine 6.x)

### Documentation

-   Doc: replace `doc/images/redmine_sla_issue_patch.png`, which no longer
    matched the plugin's current rendering, with an up-to-date capture.

------------------------------------------------------------------------

## 2.1.5 (Stable - Redmine 6.x)

### Fixed

-   Fix: `bar - rounded` gauge fill rendered as a near-perfect circle
    around ~20% (its 12px `border-radius` and the filled width both
    landing close to half the bar's height at that point) — lowered the
    radius to 8px so it stays visibly rounded without ever fully closing
    into a circle. Added a 12px `min-width` floor so the fill stays a
    visible rounded pill below ~16px, and hides the fill outright under
    4% instead of showing a disproportionate sliver.
-   Fix: `pie - flat` ring widened from 6px to 10px (disc grown from 56px
    to 64px to compensate) for legibility — the narrower ring cramped the
    label, most noticeably the longer `>100%` text.

------------------------------------------------------------------------

## 2.1.4 (Stable - Redmine 6.x)

### Performance

-   Perf: `SlaCache.purge`/`SlaCacheSpent.purge` (project-scoped branch) and
    `SlaCache.destroy_by_issue_id` now use `delete_all` instead of
    `destroy_all` — neither model has callbacks, and
    `sla_cache_spents.sla_cache_id` has an `ON DELETE CASCADE` foreign key,
    so a single `DELETE` statement is equivalent and considerably faster on
    large volumes.

------------------------------------------------------------------------

## 2.1.3 (Stable - Redmine 6.x)

### Fixed

-   Fix: `IssueQueryPatch#available_filters_with_sla_issue` logged three
    routine execution traces at `error` level, polluting production logs
    with non-error noise every time the issue list filters are built.
    Downgraded to `debug`.

------------------------------------------------------------------------

## 2.1.2 (Stable - Redmine 6.x)

### Fixed

-   Fix: `SlaPriority.create(sla_level.custom_field_id).all` used instead of
    an unconditional `IssuePriority.all.index_by(&:name)` when generating
    SLA level term documentation fixtures — the previous code coincidentally
    matched native priority names against custom-field enumeration ids
    (`PG::ForeignKeyViolation` when the ids don't align), silently producing
    wrong terms for custom-field-based SLA levels like EXAMPLE-04's.

### Documentation

-   Doc: rewrite EXAMPLE-04 section 5 to reflect the real 3-custom-field
    scenario (the field actually used for SLA priority, plus two
    intentional counter-examples showing the "required, single-value"
    eligibility filter), and fix stale references throughout (old
    Bronze/Silver/Gold terminology, "SLA Priority" instead of
    `SlaPriorityScf`).
-   Doc: regenerate all screenshots in `doc/screenshots/example-{01..05}`
    now that the capture helper no longer mispositions the sticky header or
    crops full-page captures (see 2.1.1).
-   Doc: mention the `documentation` test suite in `doc/TESTING.md` (it was
    already documented in `doc/TASKS.md` but missing from the test-suite
    walkthrough).

------------------------------------------------------------------------

## 2.1.1 (Stable - Redmine 6.x)

### Added

-   Add: on-demand "Explain" diagnostic view for a single issue's SLA
    calculation (`sla_caches#explain`, linked from the issue's SLA block to
    users with `manage_sla`). Shows which SLA level/calendar matched (or why
    none did), a recap of the calendar's business hours, and a day-by-day
    breakdown of time spent per SLA type — surfacing holidays/weekends
    hidden inside a long-running status interval. Read-only, dedicated SQL
    functions (`sla_explain_level`, `sla_explain_spent`), nothing persisted,
    never called from the normal calculation path.

### Fixed

-   Fix: the day-by-day breakdown in "Explain" no longer explodes into one
    row per calendar day for an untracked trailing status interval (e.g. a
    long-closed issue, whose last interval extends to now) — collapsed to a
    single summary row since an untracked interval always contributes 0
    minutes regardless of length.
-   Fix: documentation screenshot capture (`take_doc_screenshot`) no longer
    mispositions Redmine's sticky "Jump to a project..." header or crops
    the bottom of full-page captures — the emulated viewport is now sized
    to the page's actual content height, measured at capture width.

### Documentation

-   Doc: new "Explain" section in EXAMPLE-01 with screenshots illustrating
    a same-day and a cross-day status change.

------------------------------------------------------------------------

## 2.1.0 (Stable - Redmine 6.x)

### Removed

-   Remove: the never-implemented `SlaLog` logging subsystem — model,
    `sla_log_level` setting and settings tab, `sla_log_levels` enum on
    `Sla`, and the `sla_logs`/`sla_log_level` database objects (migration
    `202111112021018`). Scaffolded in 2.0.4 but never wired to any
    calculation path.
-   Remove: the unused `sla_cache_ttl` setting and its settings tab — never
    read anywhere in the codebase.

### Documentation

-   Doc: drop the "SLA Error logs" and "SLA Cache management" sections from
    `doc/SETTINGS.md` (settings removed above).
-   Doc: update the README roadmap — remove items already implemented
    ("Group issues by SLA compliance", "Column visibility based on module
    access") and clarify that SLA export is already available (only import
    remains open).
-   Doc: remove `sla_logs` references from `doc/MCD.md`.

------------------------------------------------------------------------

## 2.0.4 (Stable - Redmine 6.x)

### Security

-   Fix: replace `User.current.admin?` with `visible?` check in context menus
    to apply proper role-based visibility (PR #43).
-   Fix: SQL injection via `sanitize_sql` in `SlaCache` and `SlaCacheSpent`
    (PR #36).

### Bug Fixes

-   Fix: duplicate `validates_uniqueness_of` in `SlaSchedule` removed (PR #42).
-   Fix: improved error handling in `refresh` action and priority lookup
    (PR #41).
-   Fix: schedule time normalization and status path resolution (PR #36).

### Performance

-   Perf: memoize `get_sla_cache`, `get_sla_term` and `get_sla_spent` on
    `Issue` to avoid redundant queries (PR #38).
-   Perf: fix N+1 queries and duplicate `default_scope` in SLA models (PR #37).

### Refactoring

-   Refactor: extract `build_sla_column` to eliminate duplication in
    `available_columns` (PR #39).

### Testing

-   Fix: replace `assert_equal` path comparison with `assert_current_path`
    in system tests (PR #40).
-   Fix: add `include Redmine::I18n` to `SlaSchedule` so the
    `sla_schedules_inconsistency` validator can call `l()` as an instance
    method (was raising `NoMethodError` in unit tests).
-   Test: comprehensive unit tests for all models — `SlaSchedule`,
    `SlaHoliday`, `SlaCalendarHoliday`, `SlaStatus`, `SlaType`,
    `SlaLevelTerm`, `SlaProjectTracker`, `SlaCache`, `SlaCacheSpent`,
    `SlaViewJournal`, `SlaLog` — covering presence, uniqueness,
    numericality, inconsistency and read-only constraints.
-   Test: version consistency suite (`sla_plugin_version_test`) verifying
    semver format, plugin registry alignment and CHANGELOG coverage.
-   Test: context\_menu authorization for `SlaCache` — non-admin users
    with `:view_sla` now correctly see the show link (regression guard for
    PR #43).
-   Test: functional test suites for `SlaSchedulesController` and
    `SlaProjectTrackersController` (both were completely untested),
    covering all CRUD actions and context\_menu across all user roles.

------------------------------------------------------------------------

## 2.0.3 (Stable - Redmine 6.x)

### Documentation

-   Major improvement of project documentation.
-   Harmonization of examples structure.
-   Alignment between YAML fixtures and rendered UI behavior.
-   Improved screenshots organization in `doc/screenshots/example-*`.

### Maintenance

-   Minor comment corrections.
-   Internal documentation cleanup.
-   Improved readability of test fixtures and examples.

------------------------------------------------------------------------

## 2.0.2 (Stable - Redmine 6.x)

### Refactoring & Stabilization

-   Complete rewrite and stabilization of the test suite.
-   Reorganization of test architecture (unit, system, documentation).
-   Improved compatibility reliability with Redmine 6.x.

### Testing

-   Introduction of documentation-driven test suite.
-   New base test classes:
    -   `ApplicationSlaDocumentationTestCase`
    -   `ApplicationSystemTestCase`
-   Improved Capybara / Selenium integration.
-   Deterministic test ordering and suite selection via `SUITE`
    environment variable.

### Internal Improvements

-   Ruby 3 keyword arguments compatibility adjustments.
-   Fixture loading refactor.
-   Various internal cleanups.

------------------------------------------------------------------------

## 2.0.1 (Stable - Redmine 6.x)

### Improvements

-   Initial Redmine 6 compatibility adjustments.
-   Structural updates preparing the 2.0 stabilization.
-   SLA computation and rendering fixes.

------------------------------------------------------------------------

## 2.0.0 (Stable - Compatible Redmine 6)

-   Official support for Redmine 6.x.
-   Rails / ActiveRecord compatibility adjustments.

------------------------------------------------------------------------

## 1.0.0 (Stable - Compatible Redmine 5)

-   First major stable release.
-   Compatibility updated for Redmine 5.x.

------------------------------------------------------------------------

## 0.0.9

-   First public development release.
