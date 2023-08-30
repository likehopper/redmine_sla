## Sla Calendar Holidays

### Listing Sla Calendar Holidays

`GET /sla/calendar_holidays.[format]`

Returns a paginated list of Sla Levels. By default, it returns all Sla Levels.

<u>Optional filters:</u>
- sla_calendar_id
- sla_holiday
- match

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json"`


### Showing a Sla Calendar Holiday

`GET /sla/calendar_holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays/17.json"`


### Creating a Sla Calendar Holiday

`POST /sla/calendar_holidays.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "calendar_holiday": {
    "sla_calendar_id": 1,
    "sla_holiday_id": 1,
    "match": "true"
  }
}
EOF
)"
```

### Updating a Sla Calendar Holiday

`PUT /sla/calendar_holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "calendar_holiday": {
    "sla_calendar_id": 1,
    "sla_holiday_id": 1,
    "match": "true"
  }
}
EOF
)"
```


### Deleting a Sla Calendar Holiday

`DELETE /sla/calendar_holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays/17.json"`
