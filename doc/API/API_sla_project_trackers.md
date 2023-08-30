## Sla Project Trackers

### Listing Sla Project Trackers

`GET /projects/[project-identifier]/slas.[format]`

Returns a paginated list of Sla Project Trackers. By default, it returns all Sla Project Trackers.

<u>Optional filters:</u>
- sla_id
- tracker_id

<u>Examples:</u>
`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/projects/[project-identifier]/slas.json"`
