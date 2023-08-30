## Sla Level Terms

### Listing Sla Level Terms

`GET /sla/level_terms.[format]`
 
Returns a paginated list of Sla Level Terms. By default, it returns all Sla Level Terms.

<u>Optional filters:</u>
- sla_level_id
- sla_type_id
- priority_id
- term

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`


### Showing a Sla Level Term

`GET /sla/level_terms/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms/17.json"`


### Creating a Sla Level Term

`POST /sla/level_terms.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_level_term": {
    "sla_level_id": 1,
    "sla_type_id": 1,
    "priority_id": 1,
    "term": "240"
  }
}
EOF
)"
```

### Updating a Sla Level Term

`PUT /sla/level_terms/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X PUT --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms/1.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_level_term": {
    "sla_level_id": 1,
    "sla_type_id": 1,
    "priority_id": 1,
    "term": "240"
  }
}
EOF
)"
```


### Deleting a Sla Level Term

`DELETE /sla/level_terms/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms/17.json"`
