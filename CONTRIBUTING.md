# Contributing to Redmine SLA

Thank you for helping improve the plugin. Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before opening an issue

Search existing issues and the [documentation](README.md). For a bug, include the Redmine, Ruby, Rails, plugin, and database versions; steps to reproduce; expected and actual behavior; and a sanitized error or log excerpt. Do not post credentials, customer data, or other secrets. Report suspected vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Proposing a change

Open an issue first for substantial behavior or database changes so the approach can be discussed. Keep pull requests focused and describe the user impact. Add or update tests when behavior changes, especially for project permissions, cross-project access, and PostgreSQL/MySQL/MariaDB SQL. Update documentation when the user-facing behavior changes.

Run the relevant suites in a Redmine test installation using [the testing guide](doc/TESTING.md). State which database and suites you ran, and note any checks you could not run. Do not include generated screenshots, local audit reports, secrets, or unrelated changes in a pull request.

The plugin is distributed under [GPL-2.0-or-later](LICENSE). By contributing, you agree that your contribution is distributed under the same license.
