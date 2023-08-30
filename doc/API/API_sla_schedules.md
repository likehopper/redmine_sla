## Sla Schedules

### Listing Sla Schedules

`GET /sla/schedules.[format]`

Returns a paginated list of Sla Statuses. By default, it returns all Sla Statuses.

<u>Optional filters:</u>
- sla_calendar_id
- dow
- match

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json"`


### Showing a Sla Schedule

`GET /sla/schedules/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules/17.json"`


### Creating a Sla Schedule

`POST /sla/schedules.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_schedule": {
    "sla_calendar_id": "1",
    "dow": "1",
    "start_time": "09:30",
    "end_time": "12h29",
    "match": "true"
  }
}
EOF
)"
```

### Updating a Sla Schedule

`PUT /sla/schedules/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_schedule": {
    "sla_calendar_id": "1",
    "dow": "1",
    "start_time": "09:30",
    "end_time": "12h29",
    "match": "true"
  }
}
EOF
)"
```


### Deleting a Sla Schedule

`DELETE /sla/schedules/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules/17.json"`
