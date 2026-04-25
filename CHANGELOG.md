# Changelog

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