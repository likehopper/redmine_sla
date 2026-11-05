# Tasks

## build_fixture_sla.rake
Build fixture base on CSV file
Usage: `rake redmine:plugins:redmine_sla:build_fixture RAILS_ENV=development --trace`

## documentation_tests.rake
Generate screenshots for the different examples
Usage: `rake redmine:plugins:test:documentation NAME=redmine_sla RAILS_ENV=test TESTOPTS="-v -w -b" SUITE=example-05`
Also runs `test/documentation/sla_project_lists_doc_test.rb`, which writes the [project lists](PROJECT_LISTS.md) screenshots to `tmp/redmine_sla/screenshots/project-lists/`.

## update_sla.rake
Update SLA manualy or by crontab
Usage: `rake redmine:plugins:redmine_sla:update_sla RAILS_ENV=development --trace`

Projects to process: `projects=all` (default), `projects=with_sla` or
`projects=without_sla`. Projects with the SLA module enabled get their SLA
cache updated; on the others, the SLA cache left behind is purged while their
SLA configuration is kept. Use `projects=without_sla` to only clean up the
cache, for example after disabling the SLA module on several projects.

Issues to process: `scope=inprogress` (default) updates open issues, and
closed issues whose SLA spent time was not updated since their closing, so
their final value is settled once. `scope=miss` only calculates issues without
SLA cache; `scope=all` updates every issue.

Projects not active (closed, archived) are passed: their SLA cache is kept as
it was, nothing is updated or purged.
