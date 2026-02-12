# Changelog

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