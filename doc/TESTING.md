# Testing

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
Five users have been created by the fixtures, the logins of which are:
- admin
- manager
- developer ( only access to one project of TMA )
- sysadmin ( only access to two projects of infrastructure )
- reporter
- other
  
The password for each user is their login/name.

### Roles
Here are the roles of the available users:

| Name        | is_admin  | sla_manage  | sla_view  | Description |
|-------------|-----------|-------------|-----------|-------------|
| `admin`     |     x     |             |           | all this includes the SLA admin interface access |
| `manager`   |           |      x      |     x     | View and manage SALs in projects                 |
| `resolver`  |           |             |     x     | Only sees SLAs in project tickets                |
| `reporter`  |           |             |           | Access projects without seeing SLAs in tickets   |
| `other`     |           |             |           | Don't access any projects             |
