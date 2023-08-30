## Sla Statuses

### Listing Sla Statuses

`GET /sla/statuses.[format]`

Returns a paginated list of Sla Statuses. By default, it returns all Sla Statuses.

<u>Optional filters:</u>
- sla_type_id
- status_id

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`


### Showing a Sla Status

`GET /sla/statuses/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses/17.json"`


### Creating a Sla Status

`POST /sla/statuses.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_status": {
    "sla_type_id": "1",
    "status_id": "1"
  }
}
EOF
)"
```

### Updating a Sla Status

`PUT /sla/statuses/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_status": {
    "sla_type_id": "1",
    "status_id": "1"
  }
}
EOF
)"
```


### Deleting a Sla Status

`DELETE /sla/statuses/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses/17.json"`
