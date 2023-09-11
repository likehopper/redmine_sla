## Sla Types

###  Listing Sla Types

`GET /sla/types.[format]`

Returns a paginated list of Sla Types. By default, it returns all Sla Types.

<u>Optional filters:</u>
- name

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`



### Showing a Sla Type

`GET /sla/types/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types/17.json"`


### Creating a Sla Type

`POST /sla/types.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_type": {
    "name": "Response time"
  }
}
EOF
)"
```

### Updating a Sla Type

`PUT /sla/types/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_type": {
    "name": "Response time"
  }
}
EOF
)"
```


### Deleting a Sla Type

`DELETE /sla/types/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types/17.json"`
