# Testing
Add this line in file "config/application.rb" : `config.active_record.schema_format = :sql`
And, use development database for all opérations : `export RAILS_ENV=test`
And yet: `bundle exec rake db:environment:set RAILS_ENV=test`

## Create Database
Drop database, create database for core and all plugins : `bundle exec rake db:drop db:create db:migrate redmine:plugins:migrate TESTOPTS="-v -w -b" --trace`

## Build Fixtures
First you can build fixtures with this command : `bundle exec rake redmine:plugins:redmine_sla:build_fixture TESTOPTS="-v -w -b" --trace`

## Lauch tests

### Units
Now, you can run the units tests: `bundle exec rake redmine:plugins:test:units NAME=redmine_sla TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** Unit tests are such as controller actions or SLA calculations.

### Functionals
But also functionals tests: `bundle exec rake redmine:plugins:test:functionals NAME=redmine_sla TESTOPTS="-v -w -b" --trace`

> **_NOTE:_** Unit tests are particularly like access rights.

### All
And why not all the tests: `bundle exec rake redmine:plugins:test NAME=redmine_sla TESTOPTS="-v -w -b" --trace`

## Explore tests
We suggest that you go see in the interface how the SLA are built with the comments in the section USECASE.

> **_NOTE:_** It's possible to reload default data after tests success : `bundle exec rake db:drop db:create db:migrate redmine:plugins:migrate redmine:load_default_data`

### Users
Five users have been created by the fixtures, the logins of which are:
- admin
- manager
- developer
- reporter
- other
  
The password for each user is their login/name.

### Roles
Here are the roles of the available users:

| Name        | is_admin  | sla_manage  | sla_view  | Description |
|-------------|-----------|-------------|-----------|-------------|
| `admin`     |     x     |             |           | all this includes the SLA admin interface access |
| `manager`   |           |      x      |     x     | View and manage SALs in projects                 |
| `developer` |           |             |     x     | Only sees SLAs in project tickets                |
| `reporter`  |           |             |           | Access projects without seeing SLAs in tickets   |
| `other`     |           |             |           | Don't access any projects             |
