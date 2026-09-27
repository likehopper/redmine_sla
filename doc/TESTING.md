# Testing

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
