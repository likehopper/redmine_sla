# Testing

## Version 3.4.0 release matrix

Validated on **2026-11-07 and 2026-11-08** in isolated local containers, one
fresh database per suite, with no shared instance or production deployment.
Source snapshot: `release/3.4.0` at `4482c94` (icon sets, time zone parsing and
spent-time fixes). The system suites of Redmine 6 and 7 were rerun on `0453e41`,
which only changes `test/system/sla_icon_url_prefix_test.rb` (see below).

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1189 / 7409 | 1189 / 7406 | 1189 / 7406 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1249 / 7846 | 1189 / 7302 | 1189 / 7302 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1189 / 7859 | 1189 / 7856 | 1189 / 7856 |

Cells record **tests / assertions**. Total: **10,761 tests / 68,242 assertions**,
zero failures or errors, 12 expected skips (the two PostgreSQL-specific tests on
each MariaDB/MySQL combination). Each combination ran 286 unit, 470 functional,
358 integration/API, 39 Chromium system and 30 standalone icon/HTML tests, plus
6 role/project documentation tests; Redmine 6/PostgreSQL ran all 66
documentation tests instead.

Rails session SQL modes, as measured: MySQL `ONLY_FULL_GROUP_BY,
NO_AUTO_VALUE_ON_ZERO, STRICT_TRANS_TABLES, STRICT_ALL_TABLES, NO_ZERO_IN_DATE,
NO_ZERO_DATE, ERROR_FOR_DIVISION_BY_ZERO, NO_ENGINE_SUBSTITUTION`; MariaDB
`NO_AUTO_VALUE_ON_ZERO, STRICT_TRANS_TABLES, STRICT_ALL_TABLES,
ERROR_FOR_DIVISION_BY_ZERO, NO_AUTO_CREATE_USER, NO_ENGINE_SUBSTITUTION`.

**Upgrade from 3.3.4**, on each of the nine combinations: migrate a database with
3.3.4 (migration 024), load the fixtures and run `update_sla scope=all`, replace
the plugin with 3.4.0 and run `redmine:plugins:migrate`. Migrations 025 and 026
applied; the 72 SLA caches, 138 spent rows (18,455 minutes) and the
`sla_view_roll_statuses` view (397 rows) were unchanged after migration and after
a new `update_sla scope=all`.

New regression tests reproduce each fix before it: concurrent spent time
(180 instead of 90), refresh (999 kept instead of 90), counted statuses and
tracker mappings (caches left or recalculated in the request) and time zones
(`America/New_York` failing on PostgreSQL and NULL on MariaDB/MySQL,
`Etc/GMT+12` read as `Etc/GMT`). They failed on the previous code on the three
databases and pass with the fixes.

Notes on the runs:

- The first Redmine 7/PostgreSQL system run had intermittent context-menu
  failures. They came from `sla_icon_url_prefix_test.rb`, which left importmap
  module URLs cached with its `/redmine` prefix: the importmap cache sweeper only
  exists when classes reload. With seed 30488 the suite failed 7 tests with that
  file and none without it. `0453e41` clears the map directly; seeds 30488 and
  14243 then pass, and the six Redmine 6/7 system suites were rerun green.
- One Redmine 6/MySQL system run failed the URL-prefix test once while two
  browsers ran in parallel. Its seed (26232) passed three times on replay, with
  the old and new test file: a timing failure under load, not an order
  dependency.
- Rails 8.1 loads `db/schema.rb` when `db:migrate` creates a database. The
  isolated runner deletes that file before each fresh database so a schema dumped
  by a previous run does not hide the plugin migrations. Redmine upgrades migrate
  an existing database and are not affected.

Commands, from the Redmine root with `RAILS_ENV=test`, automatic test schema
loading disabled (`config.active_record.maintain_test_schema = false`) and
`GOOGLE_CHROME_OPTS_ARGS=headless,disable-gpu,no-sandbox,disable-dev-shm-usage`:

```sh
bundle exec rake db:drop db:create db:migrate redmine:plugins:migrate
bundle exec rake redmine:plugins:redmine_sla:build_fixture
bundle exec rails test plugins/redmine_sla/test/unit   # also functional, integration
bundle exec ruby -Itest -e 'files, options = ARGV.partition { |a| a.end_with?(".rb") }; ARGV.replace(options); files.each { |path| require File.expand_path(path) }' plugins/redmine_sla/test/system/*_test.rb
```

The Rake test tasks (`redmine:plugins:test:*`) reload `db/schema.rb` and drop the
plugin's SQL functions and views; use the commands above. Regenerated the two
locale screenshots, which now show the time zone note.

## Icon manifest review follow-up (2026-11-06)

After the full matrix below, manifest loading was hardened and size keys were
normalized. Targeted checks on the updated files passed in the existing isolated
PostgreSQL 17.7 installations:

| Redmine | Catalogue | HTML rendering | Chromium workflows and URL mount |
| --- | --- | --- | --- |
| 5.1.13 | 12 / 179 | 14 / 87 | 3 / 402 |
| 6.1.4 | 12 / 179 | 14 / 87 | 3 / 202 |
| 7.0.1 | 12 / 179 | 14 / 87 | 3 / 204 |

Cells record tests / assertions: **87 tests / 1,606 assertions**, zero failures,
errors or skips. The catalogue tests reject invalid YAML, empty manifests,
unsupported formats, malformed credits and invalid/duplicate sizes, while quoted
integer sizes resolve correctly and valid sets remain available.

The browser tests exercise both sets through settings and native views, plus a
real Rack mount under `/redmine`: login, settings submission, SLA views, asset URL
prefixes, HTTP responses, sprite symbols and loaded raster images. Importmap's
URL cache is cleared when changing mounts to isolate the test from other cases.
The standalone HTML tests now use Rails' actual `relative_url_root` configuration
instead of overriding `image_path`.

Run from the Redmine root with `RAILS_ENV=test` in the prepared test installation:

```sh
bundle exec ruby plugins/redmine_sla/test/standalone/icon_set_test.rb
bundle exec ruby plugins/redmine_sla/test/standalone/sla_icons_helper_test.rb
bundle exec ruby -Itest -e 'ARGV.each { |path| require File.expand_path(path) }' plugins/redmine_sla/test/system/sla_icon_sets_test.rb plugins/redmine_sla/test/system/sla_icon_url_prefix_test.rb
```

SHA-256 over the four changed Ruby files (path, NUL, contents, NUL, in the order
`icon_set.rb`, `icon_set_test.rb`, `sla_icons_helper_test.rb`,
`sla_icon_url_prefix_test.rb`): `e7a3450e5be002a7799a194e12a697aa589cdc00d00646635ca8e385a1589815`.
The full nine-cell matrix below predates this follow-up and was not rerun for
these corrections. No production deployment or publication occurred.

## Unreleased: configurable icon sets (initial matrix)

Validated on **2026-11-06** on the integration snapshot identified below, in isolated
containers and freshly migrated databases. Cells record **tests / assertions**.

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 strict | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1165 / 7012 | 1165 / 7009 | 1165 / 7009 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1225 / 7649 | 1165 / 7105 | 1165 / 7105 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1165 / 7660 | 1165 / 7657 | 1165 / 7657 |

Total: **10,545 tests / 65,863 assertions / 0 failures / 0 errors**. The 12 expected
migration skips are the two PostgreSQL-specific migration tests on each
MariaDB/MySQL combination. MySQL sessions retain `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES`. MariaDB uses strict mode without
`ONLY_FULL_GROUP_BY`.

Each combination ran 1,097 unit/functional/integration/API tests, 37 Chromium
system tests, 25 standalone icon/HTML tests and 6 role/project documentation
tests. Redmine 6/PostgreSQL ran all 66 documentation tests instead.

Image regression coverage includes asset selection and immutable resolved assets,
size variants, missing-role fallbacks, custom file/sprite sets, HTML escaping,
credits, native menu/project markers, distinct header icons and selector-only
symbols. Browser tests fetch the actual image/SVG assets. Native sorting, exports
and permission-aware project markers are covered as well.

The validation databases were migrated explicitly with SQL routines/views intact;
automatic test-schema loading was disabled after Rails initialization. The isolated
MySQL server allowed stored-function creation (`log_bin_trust_function_creators=1`).
These environment settings are not plugin configuration changes.

All **251 existing documentation screenshots** were regenerated on Redmine 6.1.4,
with **14 new icon-set illustrations**. The README issue image was refreshed.
The reference capture environment includes DejaVu Sans and FreeSerif fallback fonts.
The 151 local Markdown image references were checked; none are missing.

Implementation, asset and test-input snapshot SHA-256:
`e75fb3e6ad24c21a0b35b59e976138aa6718f757fecda3914cbfecaa682e121b`.

No merge, tag, release or production deployment. Historical results below describe
their own snapshots.

## Version 3.3.3 issue SLA block for configured trackers

Validated on **2026-10-25** in isolated local test containers, after integrating
release 3.3.2 and regenerating fixtures for each database:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1135 / 6627 | 1135 / 6624 | 1135 / 6624 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1195 / 7264 | 1135 / 6720 | 1135 / 6720 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1135 / 7274 | 1135 / 7271 | 1135 / 7271 |

Each combination ran **266 unit, 470 functional, 358 integration/API and
35 Chromium system tests**, plus **6 role/project documentation tests**.
Redmine 6.1/PostgreSQL ran all **66 documentation tests** instead.
Total: **10,275 tests / 62,395 assertions**, zero failures/errors
and 12 expected migration skips (3.1.2/3.1.3 on MariaDB/MySQL). Cells record
tests / assertions. MySQL retains `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES`
and `STRICT_ALL_TABLES`; MariaDB uses strict mode without `ONLY_FULL_GROUP_BY`.

Eight integration tests cover the issue block: unassigned trackers for admins
and managers, assignments in another project, denied view access, disabled
modules, assigned SLAs with no matching level, and read-only level display.
They also check that hidden blocks skip assignment queries and/or cache
calculation. The two unassigned-tracker regressions fail without the fix.
The no-matching-level cases use real assignments and database calculation.

No new migration, production deployment or representative performance benchmark.
Historical results below remain separate validations of their respective versions.

## Version 3.3.2 fixtures for a project without SLA

Validated on **2026-10-25** in isolated local test containers, after integrating
release 3.3.1 and regenerating fixtures for each database:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1127 / 6570 | 1127 / 6567 | 1127 / 6567 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1187 / 7207 | 1127 / 6663 | 1127 / 6663 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1127 / 7216 | 1127 / 7213 | 1127 / 7213 |

Each combination ran **266 unit, 470 functional, 350 integration/API and
35 Chromium system tests**, plus **6 role/project documentation tests**.
Redmine 6.1/PostgreSQL ran all **66 documentation tests** instead.
Total: **10,203 tests / 61,879 assertions**, zero failures/errors
and 12 expected migration skips (3.1.2/3.1.3 on MariaDB/MySQL). Cells record
tests / assertions. MySQL retains `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES`
and `STRICT_ALL_TABLES`; MariaDB uses strict mode without `ONLY_FULL_GROUP_BY`.

The new tests validate every generated time entry with Redmine's model, check
work recorded 30 minutes before every journal transition (including reopening),
and use generated records in native queries with and without SLA. The missing
reopening-entry regression fails before the correction. Selected records are
created inside test transactions; other suites keep their own time-entry data.
The original empty project remains, and the additional non-SLA project contains
one issue and supports time tracking. Project-list screenshots are refreshed.
Separate Redmine 6.1/7 MySQL CLI checks confirm unchanged default output,
UTC timestamp conversion with the source work date preserved, and reproducible
generation. The four new tests also passed a final 6.1/MySQL recheck.

No new migration, production behavior or deployment. Historical results below
remain separate validations of their respective versions.

## Version 3.3.1 roles and permissions documentation

Validated on **2026-10-25** in isolated local test containers, after integrating
release 3.3.0. This release changes documentation, screenshots and tests only.

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 738 / 2949 | 738 / 2946 | 738 / 2946 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 798 / 3516 | 738 / 2972 | 738 / 2972 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 738 / 3071 | 738 / 3068 | 738 / 3068 |

Each combination ran **262 unit and 470 functional tests**, plus **6 Chromium
documentation tests** for roles and project lists. Redmine 6.1/PostgreSQL ran
all **66 documentation tests** instead. Total: **6,702 tests /
27,508 assertions**, zero failures/errors and 12 expected migration
skips (3.1.2/3.1.3 on MariaDB/MySQL). Cells record tests / assertions.
MySQL retains `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and
`STRICT_ALL_TABLES`; MariaDB uses strict mode without `ONLY_FULL_GROUP_BY`.

The standalone roles test checks the granted and unchecked permissions for
Manager, Resolver and Reporter, verifies the Manager form, and captures both
native role screens once. A negative test refuses role administration and the
permissions report to a project manager. Existing functional tests cover the
project-scoped read/manage access documented in the guide.

API and general system suites were not repeated for this documentation release;
the full 3.3.0 matrix remains documented separately below. No migration or
production deployment.

## Version 3.3.0 public holiday import

Validated on **2026-10-24**, after integrating main's corrections, in isolated
local test containers (final Redmine 5.1/PostgreSQL unit and holiday-browser
recheck on **2026-10-25**):

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1181 / 6333 | 1181 / 6330 | 1181 / 6330 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1181 / 6429 | 1181 / 6426 | 1181 / 6426 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1181 / 6979 | 1181 / 6976 | 1181 / 6976 |

Each combination ran **262 unit, 470 functional, 350 integration/API,
35 Chromium system and 64 documentation tests**: **10,629 tests /
59,205 assertions**, zero failures or errors. Cells record tests /
assertions. The 12 expected skips are the two migration unit tests for 3.1.2
and 3.1.3 on MariaDB/MySQL. MySQL retains `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES`; MariaDB uses strict mode without
`ONLY_FULL_GROUP_BY`.

Coverage includes API v4 normalization, malformed names/regions/types/countries,
HTTP/network/JSON errors, previews without writes, repeated and atomic imports,
signed/expired previews, invalid selections, access control and the browser form.
The malformed-name regression fails against the original API v3 implementation.
Initial 6.1/7 unit runs exposed core fixtures loaded by a boot test; disabling
its unused fixtures fixes the isolation, and the final matrix passes.

All holiday calls in the suites are stubbed. Separate read-only live API v4
checks on 2026-10-24 returned 204 countries and normalized France (11 holidays), Germany
(19, including 10 regional entries) and the USA (13, including 3 regional
entries) for 2026. API v4 supplies holiday names in English.

No new migration, production deployment or representative performance benchmark.
Historical results below remain validations of their respective versions.

## Version 3.2.0 projects with SLA in project lists

After integrating main's cache corrections on **2026-10-24**, all nine
combinations reran **250 unit, 461 functional and 4 project-list documentation
tests**: **6,435 tests / 25,350 assertions**, zero failures or errors and
12 expected migration skips. The full five-suite matrix below predates that
integration; API, general system and the other documentation tests were not
repeated afterwards.

Validated on **2026-10-24** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1149 / 6072 | 1149 / 6069 | 1149 / 6069 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1149 / 6152 | 1149 / 6149 | 1149 / 6149 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1149 / 6685 | 1149 / 6682 | 1149 / 6682 |

Each combination ran **241 unit, 461 functional, 350 integration/API,
33 Chromium system and 64 documentation tests**, with zero failures or
errors: **10,341 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.
MariaDB uses `STRICT_TRANS_TABLES` without `ONLY_FULL_GROUP_BY`; enabling
that mode fails existing calculation and grouped-query tests.

Regression coverage checks, for each profile, the SLA column, the filter
values and results, the board icon and administration access in the project
lists: administrator, View and Manage SLA, View SLA only, Manage SLA only, no
SLA permission, non-member, anonymous, mixed project permissions, and SLA
module disabled. Unit tests cover distinct SLAs sorted by name in the column,
filters with and without SLA, unassigned SLAs in filter values, preloading
and the board CSS class. Query regressions check a fixed number of SLA queries
for one or five projects in both displays, and no assignment or module lookups for
users without SLA access. Both performance regressions failed on the original
3.2.0 code before the fixes. The documentation test checks each profile in
Chromium and generates the screenshots of [Projects with SLA](PROJECT_LISTS.md).

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.1.5 custom field cache invalidation

Merge validation on **2026-10-24**, after incorporating the 3.1.4 cache
optimizations and clarifying the custom field regression tests: **237 unit
tests / 1,925 assertions**, zero failures, errors or skips, on Redmine 6.1.4
with PostgreSQL in a dedicated local container and database. This run did
not repeat the other suites or the full database matrix below.

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1106 / 5874 | 1106 / 5871 | 1106 / 5871 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1106 / 5954 | 1106 / 5951 | 1106 / 5951 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1106 / 6483 | 1106 / 6480 | 1106 / 6480 |

Each combination ran **228 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures or
errors: **9,954 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. On Redmine 5.1.13 with PostgreSQL, the unit suite
was rerun alone after a first run started without its generated fixtures in
the parallel test environment; the rerun passed. MySQL retained
`ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the
Rails session.

Regression coverage adds 10 custom field invalidation tests to the 27 of
3.1.4: field update and deletion, enumeration creation, update, move to
another field and deletion with or without reassignment invalidate only the
levels using that field. Unrelated fields, validation failures and rolled
back changes keep the caches.

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.1.4 competing level cache invalidation

Validated again on **2026-10-24** in dedicated local test containers and
separate databases:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1104 / 5896 | 1104 / 5893 | 1104 / 5893 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1104 / 5976 | 1104 / 5973 | 1104 / 5973 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1104 / 6507 | 1104 / 6504 | 1104 / 6504 |

Each combination ran **226 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures or
errors: **9,936 tests and 55,119 assertions** across the matrix. Cells record
tests / assertions. After the final bulk-cleanup simplification, the full unit
and controller suites were rerun on all nine combinations; the table uses
those final reruns.

The two migration unit tests skipped by design on MariaDB and MySQL are those
of 3.1.2 and 3.1.3 (12 skips across the matrix). MySQL retained
`ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails
session. MariaDB used `STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION`, separately
from strict MySQL. Test databases were migrated explicitly and SQL functions
were preserved; generated plugin fixtures and seed 0 were used.

Regression coverage includes 35 invalidation tests: affected and unaffected
cache/spent rows, creation, reassignment, direct and nested destruction,
metadata edits, invalid saves, rollback and aborted parent/child destruction.
A changed competing schedule selects the other level on the next SQL read.
Metadata edits issue no invalidation queries. Parent destruction resolves
its dependencies and deletes caches once, while dependent schedules/links
are removed in bulk. Query-count assertions run on every combination; see
[SLA cache invalidation](CACHE_INVALIDATION.md) for the before/after workloads.

This release introduces no migration relative to 3.1.3. These results cover
the exact versions above. SQL query counts were measured on regression
fixtures; no production deployment or production latency benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.1.3 reopened issue spent time

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1077 / 5576 | 1077 / 5573 | 1077 / 5573 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1077 / 5656 | 1077 / 5653 | 1077 / 5653 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1077 / 6185 | 1077 / 6182 | 1077 / 6182 |

Each combination ran **199 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures or
errors: **9,693 tests** across the matrix. Cells record tests / assertions.
On MariaDB and MySQL, two unit tests are skipped by design: they apply a
migration inside the test transaction, which `CREATE FUNCTION` and
`CREATE VIEW` would commit implicitly on those databases. The checks below
cover both paths. MySQL retained `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES`
and `STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes two generated reopened issues: one still open,
which keeps its first closing date and counts the statuses after reopening,
and one closed again, which counts up to its last closing. The explanation
matches the computed spent time, and reopening a closed issue resumes it.
API cache and spent-time expectations follow the new fixtures.

For every combination, outside test transactions and on the generated
fixtures, migration `202111112021024` was rolled back and reapplied: only the
spent cache of the reopened issue was purged, and its recalculated spent time
counted the time since reopening.

These results cover the exact versions above. No production deployment or
representative performance benchmark was performed. Historical results below
remain separate validations of their respective versions.

## Version 3.1.2 unused SQL function removal

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1071 / 5536 | 1071 / 5536 | 1071 / 5536 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1071 / 5616 | 1071 / 5616 | 1071 / 5616 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1071 / 6143 | 1071 / 6143 | 1071 / 6143 |

Each combination ran **193 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures or
errors: **9,639 tests** across the matrix. Cells record tests / assertions.
On MariaDB and MySQL, one unit test is skipped by design: it recreates the
dropped functions inside the test transaction, which `CREATE FUNCTION` would
commit implicitly on those databases. The check below covers that path.
MySQL retained `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and
`STRICT_ALL_TABLES` in the Rails session.

Regression coverage checks that the unused functions are absent after a fresh
installation while `sla_get_level` and `sla_get_spent` remain, and that the
"Explain" view works with the Ruby explanation service on every database.

For every combination, outside test transactions, the functions of an older
installation were recreated (`sla_get_level_overlap`, plus `sla_explain_level`
and `sla_explain_spent` on PostgreSQL). Migration `202111112021023` was rolled
back and reapplied: they were dropped, and the calculation functions kept.

These results cover the exact versions above. No production deployment or
representative performance benchmark was performed. Historical results below
remain separate validations of their respective versions.

## Version 3.1.1 SLA module gating and update_sla scope

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1069 / 5530 | 1069 / 5533 | 1069 / 5533 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1069 / 5610 | 1069 / 5613 | 1069 / 5613 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1069 / 6137 | 1069 / 6140 | 1069 / 6140 |

Each combination passed **191 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures, errors
or skips: **9,621 tests** across the matrix. Cells record tests / assertions.
MySQL retained `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and
`STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes SLA calculation on projects whose SLA module is
disabled, then re-enabled: no level is computed, a stale cache is ignored and
purged, and the project-tracker configuration is kept. Disabling another
module keeps the cache. The explanation lists no SLA level and the "Explain"
action is forbidden to administrators and managers on such projects.
`update_sla` is covered for each `scope` (`inprogress`, `miss`, `all`) and
`projects` option, rejects unknown values and keeps the cache of a project
that is not active.

For every combination, migration `202111112021021` was rolled back and
reapplied, then the SLA module and `update_sla` tests passed again.

These results cover the exact versions above. No production deployment or
representative performance benchmark was performed. Historical results below
remain separate validations of their respective versions.

## Version 3.1.0 descriptions and list corrections

Validated on **2026-10-11** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1051 / 5438 | 1051 / 5441 | 1051 / 5441 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1051 / 5518 | 1051 / 5521 | 1051 / 5521 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1051 / 6045 | 1051 / 6048 | 1051 / 6048 |

Each combination passed **175 unit, 433 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures, errors
or skips: **9,459 tests** across the matrix. Cells record tests / assertions.
MySQL retained `ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and
`STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes optional descriptions, HTML and JSON API creation,
updates and clearing, JSON/XML reads, anonymous access, administrator writes,
project visibility and cross-project access rejection. Textile and CommonMark
rendering, escaped tooltips, per-view formatting reuse, issue and time-entry
columns (including entries without an issue), and all eleven plugin block-column
lists are covered. Calendar and level description-only saves preserve calculation
caches; calculation changes and nested schedule updates still invalidate them.
Chromium checks exercise the wiki toolbar, saving and clearing descriptions, and
list block rows. Documentation forms and their screenshots were refreshed.

For every combination, migration `202111112021022` was applied, rolled back and
reapplied against existing records. Checks verified nullable text columns and
preservation of the other record attributes. Rollback deletes description data.

These results cover the exact versions above. No production deployment or
representative performance benchmark was performed. Historical results below
remain separate validations of their respective versions.

## Version 3.0.6 technical corrections

Validated on **2026-10-10** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 989 / 4856 | 989 / 4859 | 989 / 4859 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 989 / 4936 | 989 / 4939 | 989 / 4939 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 989 / 5428 | 989 / 5431 | 989 / 5431 |

Each combination passed **158 unit, 430 functional, 310 integration/API,
31 system and 60 documentation tests**, with zero failures, errors or skips.
Cells record tests / assertions. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes SLA memoization after issue save and reload,
native issue/time-entry filter exclusions and missing values, project-scoped
filter visibility, archived projects, sorting, grouped counts and hour totals.
Time entries without an issue are covered in queries and display getters.
Chromium checks verify the displayed SLA group labels and counts in both
native lists. The existing functional and API permission suites also passed.

These results cover the exact versions above. Validation preceded publication; no production deployment or
representative performance benchmark was performed.
The released 3.0.5 results below remain a separate historical validation.

## Redmine compatibility matrix

Validated on 2026-09-27 for **3.0.5** (including the
project-tracker permission fix and compatibility fixes); these results do
not describe the unmodified v3.0.4 tag.

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 971 / 4658 | 971 / 4661 | 971 / 4661 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 971 / 4738 | 971 / 4741 | 971 / 4741 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 971 / 5230 | 971 / 5233 | 971 / 5233 |

Each combination runs all five suites: **142 unit, 430 functional, 310
integration/API (including routing), 29 system and 60 documentation tests**.
The table records tests / assertions; assertion counts vary with Redmine
and its database adapter. All combinations finished with zero failures,
errors and skips. MySQL runs with `ONLY_FULL_GROUP_BY` and strict SQL modes.

The test environments use separate containers and databases, with no
preproduction instance or production deployment. Redmine 6.1.4 and 7.0.1
use the official Docker images plus test dependencies. Redmine 5.1.13 uses
the [official release archive](https://www.redmine.org/releases/) on the
Ruby environment of the 5.1 Docker image; its SHA-256 was checked against
the published checksum. These are exact tested combinations, not a claim
that every Ruby or database version above the minimum has been tested.

Migrate both Redmine and the plugin, then generate fixtures before running
the suites. The isolated matrix runner loads each suite directly with Ruby
against that migrated test database, disables automatic test schema reload
in the test environment, and clears SLA caches between suites. This keeps
the SQL functions and views created by migrations intact. The standard
Rake workflow below should keep `schema_format = :sql` for the same reason.
Generated fixtures, logs and documentation screenshots stay in the test
containers or local temporary storage; they are not release artifacts.

Add this line in file "config/application.rb" : `config.active_record.schema_format = :sql`
Use a dedicated database configured under `test:` in `config/database.yml` for
all operations: `export RAILS_ENV=test`. The commands below recreate test data;
keep this database separate from development and production.
And yet: `bundle exec rake db:environment:set RAILS_ENV=test`

## Create Database
Drop database, create database for core and all plugins : `bundle exec rake db:drop db:create db:migrate redmine:plugins:migrate RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

## Build Fixtures
First you can build fixtures with this command : `bundle exec rake redmine:plugins:redmine_sla:build_fixture RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

## Run tests

### Units
Now, you can run the units tests: `bundle exec rake redmine:plugins:test:units NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** Unit tests are such as controller actions or SLA calculations.

The unit suite also runs the real `sla_get_level` (forced recalculation and
cached lookup) and `sla_get_spent` functions against every SLA issue/type in
the test fixtures. It prints an informational line for each path with the
database name, call count and `min`/`median`/`p95`/`max`/`avg` duration in
milliseconds. Timings deliberately have no pass or fail threshold because they
depend on the database host and CI load; correctness assertions remain
mandatory.

### Functionals
But also functionals tests: `bundle exec rake redmine:plugins:test:functionals NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** Functional tests are particularly like access rights.

### Integration / API

``` bash
bundle exec rake redmine:plugins:test:integration NAME=redmine_sla RAILS_ENV=test
```

### System
But also functionals tests: `bundle exec rake redmine:plugins:test:system NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** System tests use a headless browser.

> **_TIP:_** Recommended use Chromium ( and chromium-driver ) with these options  `**GOOGLE_CHROME_OPTS_ARGS = ["headless","disable-gpu","no-sandbox","disable-dev-shm-usage"]**` ( in `test/application_system_test_case.rb` file for example ).

### Documentation
And also documentation tests, which regenerate the screenshots used in `doc/EXAMPLE-*.md`: `bundle exec rake redmine:plugins:test:documentation NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** Restrict to a single example with `SUITE=example-05` (see `doc/TASKS.md`). Screenshots are written to `tmp/redmine_sla/screenshots/`.

### All
And why not all the tests: `bundle exec rake redmine:plugins:test NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" --trace`

## Explore tests
To explore the generated SLA examples in the interface, use a separate Redmine
instance connected to the dedicated test database. See [USECASE](USECASE.md)
for the scenarios.

> **_NOTE:_** It's possible to reload default data after tests success : `bundle exec rake db:drop db:create db:migrate redmine:plugins:migrate redmine:load_default_data`

### Scope regression coverage

`sla_cache_invalidation_test.rb` also covers custom field and enumeration
changes, deletion with reassignment, unrelated fields, validation failures,
and transaction rollback. The model callbacks delete caches only for SLA
levels using the affected field; spent caches follow the foreign key cascade.
Calculations are rebuilt on demand, within the existing SLA cache lifecycle.

`test/unit/sla_explicit_query_scopes_test.rb` checks association sorting,
grouped counts and row preservation. `sla_cache_scope_operations_test.rb`
checks project/issue visibility, project purges including historical orphans,
and targeted cache deletion. Run these alongside the functional and API
suites on PostgreSQL, MariaDB and strict MySQL, with `ONLY_FULL_GROUP_BY`
enabled on MySQL. MariaDB results do not substitute for MySQL results.

When running suites separately, reset the dedicated test database or its
cache rows and spent-cache sequence between runs. Some existing API and
functional fixtures expect fixed cache IDs. Retain SQL schema dumps so Rails
schema preparation preserves the plugin's functions and views.

### Users
Six users have been created by the fixtures:

| Login       | Admin | Role       | Projects                        |
|-------------|:-----:|------------|---------------------------------|
| `admin`     |   x   |            | all                             |
| `manager`   |       | Manager    | all                             |
| `developer` |       | Resolver   | the two TMA projects            |
| `sysadmin`  |       | Resolver   | two infrastructure projects     |
| `reporter`  |       | Reporter   | the four SLA test projects      |
| `other`     |       |            | none                            |

The password for each user is their login.

### Roles
Here are the SLA permissions of the fixture roles
(see [Roles and permissions](SETTINGS.md#roles-and-permissions)):

| Role       | `view_sla` | `manage_sla` | Description                                   |
|------------|:----------:|:------------:|-----------------------------------------------|
| Manager    |     x      |      x       | Views and manages SLAs in projects            |
| Resolver   |     x      |              | Reads SLA information in projects              |
| Reporter   |            |              | Accesses projects without seeing SLAs         |

Administrators (`admin`) manage the global SLA configuration regardless of roles.
