# SLA Project Trackers

These assignments associate a project and tracker with an SLA. Both JSON and
XML are supported.

## Permissions

Access requires `manage_sla` on the assignment's project. Global lists include
only assignments from authorized projects. Creation requires permission on
the destination project; moving an existing assignment through the global
route requires permission on both its current and destination projects.

For project routes, the project comes from the URL. An existing assignment
must belong to that project, including for bulk operations. A denied
project or destination returns `403`; looking up an assignment outside the
user's permitted projects returns `404`. A rejected bulk request deletes
none of its assignments.

## Routes

| Operation | Global route | Project route |
| --- | --- | --- |
| List | `GET /sla/project_trackers.[format]` | `GET /projects/:project_id/sla/trackers.[format]` |
| Create | `POST /sla/project_trackers.[format]` | `POST /projects/:project_id/sla/trackers.[format]` |
| Update | `PATCH /sla/project_trackers/:id.[format]` | `PATCH /projects/:project_id/sla/trackers/:id.[format]` |
| Delete | `DELETE /sla/project_trackers/:id.[format]` | `DELETE /projects/:project_id/sla/trackers/:id.[format]` |

`PUT` is also accepted for updates. Listing supports `sla_id` and `tracker_id`
filters. The global list also supports a `project_id` filter.

``` bash
curl -s -H "X-Redmine-API-Key: $APIKEY" \
  "$TRACKER/projects/project-identifier/sla/trackers.json"
```

Creation and updates accept attributes under `sla_project_tracker`:

``` json
{
  "sla_project_tracker": {
    "project_id": 1,
    "tracker_id": 2,
    "sla_id": 1
  }
}
```

Omit `project_id` when using the project route. Use the global update route
to move an assignment to another authorized project.
