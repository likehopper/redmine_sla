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

`POST /sla/levels.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`

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
