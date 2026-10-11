# Tasks

## build_fixture_sla.rake
Build fixture base on CSV file
Usage: `rake redmine:plugins:redmine_sla:build_fixture RAILS_ENV=development --trace`

## documentation_tests.rake
Generate screenshots for the different examples
Usage: `rake redmine:plugins:test:documentation NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" SUITE=example-05`

## update_sla.rake
Update SLA manualy or by crontab
Usage: `rake redmine:plugins:redmine_sla:update_sla RAILS_ENV=development --trace`

Projects to process: `projects=all` (default), `projects=with_sla` or
`projects=without_sla`. Projects with the SLA module enabled get their SLA
cache updated; on the others, the SLA cache left behind is purged while their
SLA configuration is kept. Use `projects=without_sla` to only clean up the
cache, for example after disabling the SLA module on several projects.
