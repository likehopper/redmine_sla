## Slas

### Listing Slas

`GET /sla/slas.[format]`

Returns a paginated list of Slas. By default, it returns all Slas.

<u>Optional filters:</u>
- name

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`

To improve the presentation, you can use this command:
`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json" | python3 -m json.tool`



### Showing a Sla

`GET /sla/slas/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas/17.json"`


### Creating a Sla

Since version **3.1.0**, `description` is an optional string accepting the
configured Redmine wiki syntax. List and detail responses return the source
text, or `null` for existing records without a description. Creation and update
requests accept it; send an empty string to clear it. HTML detail pages render
the wiki formatting. Name tooltips in the supported lists and issue SLA block
use plain text truncated to 250 characters; macros are not evaluated there.

`POST /sla/slas.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`

Use with :
```
DATA="$(cat <<-EOF
{
  "sla": {
    "name": "Sla Support Tracker",
    "description": "Support requests: answer within business hours."
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
