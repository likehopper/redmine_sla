## Sla Caches

### Listing Sla Caches

`GET /sla/caches.[format]`

Returns a paginated list of Sla Caches. By default, it returns all Sla Caches for open's issues.


<u>Parameters:</u>
- offset: skip this number of issues in response (optional)
- limit: number of issues per page (optional)
- sort: column to sort with. Append :desc to invert the order.
    - project
    - issue
    - sla_level
    - start_date
    - created_on
    - updated_on
- include: fetch associated data (optional, use comma to fetch multiple associations). Possible values:
    - SlaCacheSpents

<u>Optional filters:</u>
- project_id
- issue_id
- issue.status_id
- issue.tracker_id
- sla_level_id
- start_date
- created_on
- updated_on

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches.json"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches.json?project_id=1"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches.json?issue_id=59"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches.json?sla_level_id=2"`

`curl -s -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches.json?issue.status_id=*&start_date=><2021-01-01|2021-12-01"  | python3 -m json.tool`


### Showing a Sla Caches

`GET /sla/holidays/[id].[format]`

<u>Optional includes:</u>
- sla_cache_spents

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches/60.json"`

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches/60.json?include=sla_cache_spents"`


### Refresh a Sla Caches

`POST /sla/caches/[id]/refresh.[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches/60.json"`


### Deleting a Sla Caches

`DELETE /sla/caches/[id].[format]`

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X DELETE -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/caches/60.json"`
