## Slas

### Listing Slas

`GET /sla/slas.[format]`

Returns a paginated list of Slas. By default, it returns all Slas.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`

