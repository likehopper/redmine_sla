## Sla Levels

### Listing Sla Levels

`GET /sla/levels.[format]`

Returns a paginated list of Sla Levels. By default, it returns all Sla Levels.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`

