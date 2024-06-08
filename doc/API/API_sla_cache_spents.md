## Sla Cache Spents 

### Listing Cache Spents

`GET /sla/caches.[format]`

Returns a paginated list of Sla Cache Spents. By default, it returns all Sla Cache Spents for open's issues. You must add filter « issue.status_id=* » to view all.

<u>Parameters:</u>
- offset: skip this number of issues in response (optional)
- limit: number of issues per page (optional)
- sort: column to sort with. Append :desc to invert the order.
    - project
    - issue
    - sla_level
    - sla_type
    - spent
    - created_on
    - updated_on

<u>Optional filters:</u>
- project_id
- issue_id
- issue.status_id
- issue.tracker_id
- sla_level_id
- sla_type_id

<u>Examples:</u>

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?issue.status_id=*&order=issue_id"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?project_id=1"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?issue_id=59"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?sla_level_id=2"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?sla_type_id=1"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?issue.status_id=*&project_id=1&sort=spent" | python3 -m json.tool`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/cache_spents.json?issue.status_id=*&project_id=1&sort=issue:desc" | python3 -m json.tool`


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
