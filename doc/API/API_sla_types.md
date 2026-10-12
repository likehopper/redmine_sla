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

Since version **3.1.0**, `description` is an optional string accepting the
configured Redmine wiki syntax. List and detail responses return the source
text, or `null` for existing records without a description. Creation and update
requests accept it; send an empty string to clear it. HTML detail pages render
the wiki formatting. Name tooltips in the supported lists and issue SLA block
use plain text truncated to 250 characters; macros are not evaluated there.

`POST /sla/types.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla_type": {
    "name": "Response time",
    "description": "Time until the first answer to the customer."
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
