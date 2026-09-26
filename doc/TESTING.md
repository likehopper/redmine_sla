# Testing
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
