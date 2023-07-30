# API

Some of the SLA data is exposed through Redmine's REST API for the resources described below. The API supports both XML and JSON formats.

> **_NOTE:_** for each example, we use the command `curl`. The `TRACKER` variable contains the Redmine URL and the `APIKEY` variable the API key available from each user's account (if the REST API is enabled in the configuration).


## Slas

To retrieve the list of Slas :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`


## Sla Types

To retrieve the list of Sla Types :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`


## SLA Statuses

To retrieve the list of Sla Statuses :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`


## SLA Schedules

To retrieve the list of Sla Schedules :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json"`


## Sla Holidays

To retrieve the list of Sla Holidays :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json"`


## Sla Calendar Holildays

To retrieve the list of Sla Calendar Holidays :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json"`


## Sla Levels

To retrieve the list of Sla Levels :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`


## Sla Level Terms
 
To retrieve the list of Sla Level Terms :

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`


## Sla Project Trackers

To retrieve the list of Sla Project Trackers:

`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/projects/[project-identifier]/slas.json"`
