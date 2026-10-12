## Sla Levels

### Listing Sla Levels

`GET /sla/levels.[format]`

Returns a paginated list of Sla Levels. By default, it returns all Sla Levels.

<u>Optional filters:</u>
- name
- sla_id
- sla_calendar_id

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`



### Showing a Sla Level

`GET /sla/levels/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels/17.json"`


### Creating a Sla Level

Since version **3.1.0**, `description` is an optional string accepting the
configured Redmine wiki syntax. List and detail responses return the source
text, or `null` for existing records without a description. Creation and update
requests accept it; send an empty string to clear it. HTML detail pages render
the wiki formatting. Name tooltips in the supported lists and issue SLA block
use plain text truncated to 250 characters; macros are not evaluated there.

`POST /sla/levels.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_level": {
    "name": "Level Bug Tracker",
    "description": "Terms applied to bugs on the business-hours calendar.",
    "sla_id": 1,
    "sla_calendar_id": 1
  }
}
EOF
)"
```

### Updating a Sla Level

`PUT /sla/levels/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_level": {
    "name": "Level Bug Tracker",
    "sla_id": 1,
    "sla_calendar_id": 1
  }
}
EOF
)"
```


### Deleting a Sla Level

`DELETE /sla/levels/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels/17.json"`
