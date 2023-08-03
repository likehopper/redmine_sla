# API

Some of the SLA data is exposed through Redmine's REST API for the resources described below. The API supports both XML and JSON formats.

> **_NOTE:_** for each example, we use the command `curl`. The `TRACKER` variable contains the Redmine URL and the `APIKEY` variable the API key available from each user's account (if the REST API is enabled in the configuration).


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


## Sla Types

###  Listing Sla Types

`GET /sla/types.[format]`

Returns a paginated list of Sla Types. By default, it returns all Sla Types.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`


## Sla Statuses

### Listing Sla Statuses

`GET /sla/statuses.[format]`

Returns a paginated list of Sla Statuses. By default, it returns all Sla Statuses.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`


## Sla Schedules

### Listing Sla Statuses

`GET /sla/schedules.[format]`

Returns a paginated list of Sla Statuses. By default, it returns all Sla Statuses.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json"`


## Sla Holidays

### Listing Sla Holidays

`GET /sla/holidays.[format]`

Returns a paginated list of Sla Holidays. By default, it returns all Sla Holidays.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json"`


## Sla Calendar Holildays

### Listing Sla Calendar Holildays

`GET /sla/calendar_holidays.[format]`

Returns a paginated list of Sla Calendar Holildays. By default, it returns all Sla Calendar Holildays.

<u>Parameters:</u>
- offset: skip this number of items in response (optional)
- limit: number of itmes per page (optional)
- sort: column to sort with. Append :desc to invert the order.

<u>Examples:</u>

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json"`


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
