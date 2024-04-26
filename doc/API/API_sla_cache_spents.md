## Sla Cache Spents 

### Listing Cache Spents

`GET /sla/caches.[format]`

Returns a paginated list of Sla Cache Spents. By default, it returns all Sla Cache Spents.

<u>Optional filters:</u>
- project_id
- issue_id
- sla_level_id

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?project_id=1"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?issue_id=59"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?sla_level_id=2"`


### Showing a Sla Cache Spents

`GET /sla/holidays/[id].[format]`


<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents/120.json"`


### Refresh a Sla Cache Spents

`POST /sla/cache_spents/[id]/refresh.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents/120.json"`


### Deleting a Sla Cache Spents

`DELETE /sla/cache_spents/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents/120.json"`
