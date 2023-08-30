## Slas

### Listing Slas

`GET /sla/slas.[format]`

Returns a paginated list of Slas. By default, it returns all Slas.

<u>Optional filters:</u>
- name

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`


### Showing a Sla

`GET /sla/slas/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas/17.json"`


### Creating a Sla

`POST /sla/slas.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla": {
    "name": "Sla Support Tracker"
  }
}
EOF
)"
```

### Updating a Sla

`PUT /sla/slas/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla": {
    "name": "Sla Support Tracker"
  }
}
EOF
)"
```


### Deleting a Sla

`DELETE /sla/slas/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas/17.json"`
