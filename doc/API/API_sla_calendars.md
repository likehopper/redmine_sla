## SLA Calendars

### Description field

Since version **3.1.0**, `description` is an optional string accepting the
configured Redmine wiki syntax. List and detail responses return the source
text, or `null` for existing records without a description. Creation and update
requests accept it; send an empty string to clear it. HTML detail pages render
the wiki formatting. Name tooltips in the supported lists and issue SLA block
use plain text truncated to 250 characters; macros are not evaluated there.

Calendar reads follow the existing SLA visibility rules. Creation, update
and deletion require an administrator. Enable Redmine's REST API and send
`X-Redmine-API-Key` with an authorized user's key.

### Listing and showing calendars

- `GET /sla/calendars.[format]`
- `GET /sla/calendars/[id].[format]`
- `GET /projects/[project_id]/sla/calendars.[format]`
- `GET /projects/[project_id]/sla/calendars/[id].[format]`

Both JSON and XML are supported. Lists are paginated and can be filtered by
`name`. Project routes expose only calendars used by that project.

Example JSON detail response:

```json
{
  "sla_calendar": {
    "id": 1,
    "name": "Business hours",
    "description": "**Office hours**, Monday to Friday."
  }
}
```

### Creating a calendar

`POST /sla/calendars.[format]`

```json
{
  "sla_calendar": {
    "name": "Business hours",
    "description": "**Office hours**, Monday to Friday."
  }
}
```

The existing nested `sla_schedules_attributes` parameter can also specify
working periods. The description does not change schedule calculations.

### Updating a calendar

`PUT /sla/calendars/[id].[format]` or `PATCH /sla/calendars/[id].[format]`

To clear the description:

```json
{
  "sla_calendar": {
    "description": ""
  }
}
```

### Deleting a calendar

`DELETE /sla/calendars/[id].[format]`

Existing association and validation rules still apply.
