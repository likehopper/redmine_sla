## Sla Project Trackers

### Listing Sla Project Trackers

`GET /projects/[project-identifier]/slas.[format]`

Returns a paginated list of Sla Project Trackers. By default, it returns all Sla Project Trackers.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>
`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/projects/[project-identifier]/slas.json"`
