# Testing

## Version 3.3.2 fixtures for a project without SLA

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1166 / 6107 | 1166 / 6104 | 1166 / 6104 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1166 / 6195 | 1166 / 6192 | 1166 / 6192 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1166 / 6733 | 1166 / 6730 | 1166 / 6730 |

Each combination ran **247 unit, 465 functional, 350 integration/API,
35 Chromium system and 69 documentation tests**, with zero failures or
errors: **10,494 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. On Redmine 6.1.4 with MySQL, the unit suite was
rerun alone after a first run started without its generated fixtures in the
parallel test environment; the rerun passed. MySQL retained
`ONLY_FULL_GROUP_BY`, `STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the
Rails session.

The generated project without SLA and with an issue is listed with the
projects without SLA by the project list tests, for administrators and
managers; the project list screenshots were regenerated accordingly. The
generated `time_entries.yml` is not loaded by the test suites.

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.3.1 roles and permissions documentation

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1166 / 6105 | 1166 / 6102 | 1166 / 6102 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1166 / 6193 | 1166 / 6190 | 1166 / 6190 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1166 / 6731 | 1166 / 6728 | 1166 / 6728 |

Each combination ran **247 unit, 465 functional, 350 integration/API,
35 Chromium system and 69 documentation tests**, with zero failures or
errors: **10,494 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.

The new roles documentation test runs with each documentation suite and
takes the permissions report and role form screenshots once, with
`example-01`. This release changes documentation and tests only.

These results cover the exact versions above. No production deployment or
representative performance benchmark was performed. Historical results below
remain separate validations of their respective versions.

## Version 3.3.0 public holiday import

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1161 / 6101 | 1161 / 6098 | 1161 / 6098 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1161 / 6189 | 1161 / 6186 | 1161 / 6186 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1161 / 6727 | 1161 / 6724 | 1161 / 6724 |

Each combination ran **247 unit, 465 functional, 350 integration/API,
35 Chromium system and 64 documentation tests**, with zero failures or
errors: **10,449 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes the Nager.Date adapter (country options, local
names and regional holidays, dates outside the requested year, invalid input
before any request, timeouts, DNS failures, HTTP errors and malformed JSON),
the importer (preview of existing dates without writes, repeated imports,
same-day names combined, rollback of a failed import), the controller (access
check, unavailable service, signed preview and import, invalid and expired
previews, non-administrators refused) and the browser form in Chromium. The
holiday service is stubbed: no test calls the network.

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.2.0 projects with SLA in project lists

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1145 / 6025 | 1145 / 6022 | 1145 / 6022 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1145 / 6105 | 1145 / 6102 | 1145 / 6102 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1145 / 6636 | 1145 / 6633 | 1145 / 6633 |

Each combination ran **238 unit, 460 functional, 350 integration/API,
33 Chromium system and 64 documentation tests**, with zero failures or
errors: **10,305 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.

Regression coverage checks, for each profile, the SLA column, the filter
values and results, the board icon and administration access in the project
lists: administrator, View and Manage SLA, View SLA only, Manage SLA only, no
SLA permission, non-member, anonymous, and SLA module disabled. Unit tests
cover the distinct SLAs sorted by name in the column, filters with and
without SLA, filter values, SLA preloading and the board CSS class. The
documentation test checks the rendering per profile in Chromium and
generates the screenshots of [Projects with SLA](PROJECT_LISTS.md).

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
performed. Historical results below remain separate validations of their
respective versions.

## Version 3.1.5 custom field cache invalidation

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

Validated on **2026-10-16** in isolated local test containers:

| Redmine | Ruby | Rails | PostgreSQL 17.7 | MariaDB 10.11.19 | MySQL 8.0.46 strict |
| --- | --- | --- | --- | --- | --- |
| 5.1.13 | 3.2.11 | 6.1.7.10 | 1096 / 5797 | 1096 / 5794 | 1096 / 5794 |
| 6.1.4 | 3.4.11 | 7.2.3.2 | 1096 / 5877 | 1096 / 5874 | 1096 / 5874 |
| 7.0.1 | 4.0.7 | 8.1.3.1 | 1096 / 6406 | 1096 / 6403 | 1096 / 6403 |

Each combination ran **218 unit, 435 functional, 350 integration/API,
33 Chromium system and 60 documentation tests**, with zero failures or
errors: **9,864 tests** across the matrix. Cells record tests / assertions.
The two migration unit tests skipped by design on MariaDB and MySQL are
those of 3.1.2 and 3.1.3. MySQL retained `ONLY_FULL_GROUP_BY`,
`STRICT_TRANS_TABLES` and `STRICT_ALL_TABLES` in the Rails session.

Regression coverage includes 27 invalidation tests: creating, updating,
moving and destroying calendars, schedules, calendar-holiday links, holidays,
levels and terms, with affected and unaffected cache and spent-time rows.
Competing levels of the same SLA are invalidated, invalid saves keep the
caches, a rollback restores them, and a changed competing schedule selects
the other level on the next read. See [SLA cache invalidation](CACHE_INVALIDATION.md).

This release introduces no migration. These results cover the exact versions
above. No production deployment or representative performance benchmark was
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
suites on PostgreSQL, MariaDB and strict MySQL, including
`ONLY_FULL_GROUP_BY`; MariaDB results do not substitute for MySQL results.

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
| Resolver   |     x      |              | Only sees SLAs in project issues              |
| Reporter   |            |              | Accesses projects without seeing SLAs         |

Administrators (`admin`) manage the global SLA configuration regardless of roles.
