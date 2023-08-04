## Sla Level Terms

### Listing Sla Level Terms

`GET /sla/level_terms.[format]`
 
Returns a paginated list of Sla Level Terms. By default, it returns all Sla Level Terms.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`
