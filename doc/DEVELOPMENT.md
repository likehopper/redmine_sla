# Query scopes and Ruby integrations

Since 3.0.4, the remaining SLA models no longer add joins through
`default_scope`. Queries should request the associations they use explicitly.
This keeps list joins out of validation, associations and cache cleanup.

| Model | `with_references` joins |
| --- | --- |
| `SlaLevel` | SLA, calendar and an optional custom field (left join) |
| `SlaLevelTerm` | Level and type |
| `SlaProjectTracker` | SLA, tracker and project |
| `SlaCache` | Level, project and issue |
| `SlaCacheSpent` | Project, issue, type, cache and its level |

The plugin's Query classes apply these scopes for sorting, filtering and
grouping. Direct controller lookups also use them before checking access.
For example, a custom cache listing can combine visibility and reference
joins:

``` ruby
SlaCache.visible(user).with_references.order('sla_levels.name')
```

`with_references` only supplies joins; it does not authorize access. Cache
visibility scopes join projects and issues to apply the existing permission
conditions. Project-tracker visibility joins projects for `manage_sla`.
Continue using the plugin's permission checks for reads and mutations.

For a query that only needs one association, request it directly:

``` ruby
SlaCacheSpent.joins(:issue).where(issues: {tracker_id: tracker_id})
```

Internal cache cleanup intentionally works on base-table rows. Applying list
joins to a purge could hide historical orphan rows from deletion. Prefer the
existing project-scoped purge methods after the caller has checked mutation
permissions; foreign-key cascades remove dependent spent rows when a cache
is deleted.

The plugin version is declared once in `lib/redmine_sla/version.rb` and used
by `init.rb`. Keep the matching release entry in `CHANGELOG.md` and the
README current when preparing a release. The version unit tests check the
Redmine registration and changelog against that constant.

See [Testing](TESTING.md) for the database-backed regression suites.
