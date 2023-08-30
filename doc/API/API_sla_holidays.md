## Sla Holidays

### Listing Sla Holidays

`GET /sla/holidays.[format]`

Returns a paginated list of Sla Holidays. By default, it returns all Sla Holidays.

<u>Optional filters:</u>
- name
- date

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json"`


### Showing a Sla Holiday

`GET /sla/holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays/17.json"`


### Creating a Sla Holiday

`POST /sla/holidays.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_holiday": {
    "name": "New Year's Day",
    "date": "2024-01-01"
  }
}
EOF
)"
```


### Updating a Sla Holiday

`PUT /sla/holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_holiday": {
    "name": "New Year's Day",
    "date": "2024-01-01"
  }
}
EOF
)"
```


### Deleting a Sla Holiday

`DELETE /sla/holidays/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays/17.json"`
