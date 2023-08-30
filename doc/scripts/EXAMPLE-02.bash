#!/bin/bash
#
# 
# URL ENCODE
#
urlencode() {
    local l=${#1}
    for (( i = 0 ; i < l ; i++ )); do
        local c=${1:i:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            ' ') printf + ;;
            *) printf '%%%.2X' "'$c"
        esac
    done
}
#
#
# check installation of requirements
#
REQUIREMENTS=( "curl" "jq" )
for REQUIREMENT in ${REQUIREMENTS[*]}; do
	if ! which $REQUIREMENT >/dev/null; then
		echo "Error: $REQUIREMENT is not installed." >&2
		exit 1
	fi
	echo "Ok: $REQUIREMENT is installed."
done
#
#
# Check arguments usage
#
if [ ! $# -eq 2 ]; then
    echo "Error: Usage:"
    echo -e "\t$0 [ URL OF REDMINE ] [ API KEY ]\n"
    exit 1
fi
echo "Ok: two arguments are present."
#
#
# Check tracker access
#
TRACKER=$1
if ! curl -sI $TRACKER >/dev/null; then
	echo "Error: Failed to connect to $TRACKER" >&2
	exit 1
fi
echo "Ok: connection to $TRACKER is possible."
#
#
# Check API KEY size
#
APIKEY=$2
if [ ! ${#APIKEY} -eq 40 ]; then 
	echo "Error: The API KEY size is incorrect."
	exit 1
fi
echo "Ok: the API KEY size (${#APIKEY}) is correct."
#
#
# SLA
#
NAME="SLA Bug Tracker"
DATA="{ \"sla\": { \"name\": \"$NAME\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json"`
ID=`echo $EXEC|jq -r ".sla|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "Name has already been taken" ]; then
                SEARCH=$(urlencode "name=$NAME")
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/slas.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".slas[0]|.id"`
                echo "Ok: sla exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
SLA_ID=$ID
#
#
# SLA TYPE 1 = GTI
#
NAME="Response time"
DATA="{ \"sla_type\": { \"name\": \"$NAME\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`
ID=`echo $EXEC|jq -r ".sla_type|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_type add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "Name has already been taken" ]; then
                SEARCH="name=$(urlencode "$NAME")"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_types[0]|.id"`
                echo "Ok: sla_type exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
SLA_TYPE1_ID=$ID
#
#
# SLA TYPE 2 = GTR
#
NAME="Resolution deadline"
DATA="{ \"sla_type\": { \"name\": \"$NAME\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json"`
ID=`echo $EXEC|jq -r ".sla_type|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_type add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "Name has already been taken" ]; then
                SEARCH="name=$(urlencode "$NAME")"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/types.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_types[0]|.id"`
                echo "Ok: sla_type exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
SLA_TYPE2_ID=$ID
#
#
# SLA STATUS 1 : SLA TYPE 1 (GTI)
#
STATUS_ID="1" # New
DATA="{ \"sla_status\": { \"sla_type_id\": \"$SLA_TYPE1_ID\", \"status_id\": \"$STATUS_ID\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`
ID=`echo $EXEC|jq -r ".sla_status|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_status add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "SLA Type has already been taken" ]; then
                SEARCH="sla_type_id=$SLA_TYPE1_ID&status_id=$STATUS_ID"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_statuses[0]|.id"`
                echo "Ok: sla_status exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
#
#
# SLA STATUS 2 : SLA TYPE 2 (GTR)
#
STATUS_ID="1" # New
DATA="{ \"sla_status\": { \"sla_type_id\": \"$SLA_TYPE2_ID\", \"status_id\": \"$STATUS_ID\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`
ID=`echo $EXEC|jq -r ".sla_status|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_status add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "SLA Type has already been taken" ]; then
                SEARCH="sla_type_id=$SLA_TYPE2_ID&status_id=$STATUS_ID"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_statuses[0]|.id"`
                echo "Ok: sla_status exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
STATUS_ID="2" # In Progress
DATA="{ \"sla_status\": { \"sla_type_id\": \"$SLA_TYPE2_ID\", \"status_id\": \"$STATUS_ID\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json"`
ID=`echo $EXEC|jq -r ".sla_status|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_status add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "SLA Type has already been taken" ]; then
                SEARCH="sla_type_id=$SLA_TYPE2_ID&status_id=$STATUS_ID"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/statuses.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_statuses[0]|.id"`
                echo "Ok: sla_status exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
#
#
# SLA HOLIDAY
#
NAME="New Year's Day"
DATE="2024-01-01"
DATA="{ \"sla_holiday\": { \"name\": \"$NAME\", \"date\": \"$DATE\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json"`
ID=`echo $EXEC|jq -r ".sla_holiday|.id"`
if [ $((ID+0)) -gt 0 ]; then
	echo "Ok: sla_holiday add n°$ID"
else
	ERROR=`echo $EXEC|jq -r ".errors[0]"`
	if [ "$ERROR" == "Date has already been taken" ]; then
    SEARCH="date=$DATE"
		EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/holidays.json?$SEARCH"`
		ID=`echo $EXEC|jq -r ".sla_holidays[0]|.id"`
		echo "Ok: sla_holiday exists n°$ID"
	else 
		echo "Error: $ERROR"
		exit 1
	fi
fi
SLA_HOLIDAY_ID=$ID
#
#
# SLA CALENDAR
#
NAME="Calendar Bug Tracker"
DATA="{ \"sla_calendar\": { \"name\": \"$NAME\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendars.json"`
ID=`echo $EXEC|jq -r ".sla_calendar|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_calendar add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "Name has already been taken" ]; then
                SEARCH="name=$(urlencode "$NAME")"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendars.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_calendars[0]|.id"`
                echo "Ok: sla_calendar exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
SLA_CALENDAR_ID=$ID
#
#
# SLA SCHEDULE
#
SCHEDULES=(
  '"dow": "1", "start_time": "09:30", "end_time": "12h29" , "match": "true"'
  '"dow": "1", "start_time": "14:00", "end_time": "18h00" , "match": "true"'
  '"dow": "2", "start_time": "09:30", "end_time": "12h29" , "match": "true"'
  '"dow": "2", "start_time": "14:00", "end_time": "18h00" , "match": "true"'
  '"dow": "3", "start_time": "09:30", "end_time": "12h29" , "match": "true"'
  '"dow": "3", "start_time": "14:00", "end_time": "18h00" , "match": "true"'
  '"dow": "4", "start_time": "09:30", "end_time": "12h29" , "match": "true"'
  '"dow": "4", "start_time": "14:00", "end_time": "18h00" , "match": "true"'
  '"dow": "5", "start_time": "09:30", "end_time": "12h29" , "match": "true"'
  '"dow": "5", "start_time": "14:00", "end_time": "18h00" , "match": "true"'
)
for i in $(echo ${!SCHEDULES[@]}); do
  SCHEDULE=${SCHEDULES[$i]}
  DATA="{ \"sla_schedule\": { \"sla_calendar_id\": \"$SLA_CALENDAR_ID\", $SCHEDULE } }"
  EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json"`
  ID=`echo $EXEC|jq -r ".sla_schedule|.id"`
  if [ $((ID+0)) -gt 0 ]; then
          echo "Ok: sla_schedule add n°$ID"
  else
          ERROR=`echo $EXEC|jq -r ".errors[0]"`
          if [ "$ERROR" == "SLA Calendar This slot alredy exists" ]; then
                  DOW=`echo $DATA|jq -r ".sla_schedule|.dow"`
                  START_TIME=`echo $DATA|jq -r ".sla_schedule|.start_time"`
                  SEARCH="sla_calendar_id=$SLA_CALENDAR_ID&dow=$DOW"
                  EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/schedules.json?$SEARCH"`
                  # TODO : plugin must retrun TIME ( NOT TIMESTAMP )
                  START_TIME="2000-01-01T${START_TIME}:00Z"
                  ID=`echo $EXEC|jq -r ".sla_schedules[]|select(.start_time==\"$START_TIME\")|.id"`
                  echo "Ok: sla_schedule exists n°$ID"
          else
                  echo "Error: $ERROR"
                  exit 1
          fi
  fi
done
#
#
# SLA CALENDAR HOLIDAY
#
DATA="{ \"sla_calendar_holiday\": { \"sla_calendar_id\": \"$SLA_CALENDAR_ID\", \"sla_holiday_id\": \"$SLA_HOLIDAY_ID\", \"match\": \"false\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json"`
ID=`echo $EXEC|jq -r ".sla_calendar_holiday|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_calendar_holiday add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "SLA Calendar This holiday is already present in this SLA Calendar's Holidays" ]; then
                SEARCH="sla_calendar_holiday_id=$SLA_CALENDAR_ID&sla_holiday_id=$SLA_HOLIDAY_ID"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/calendar_holidays.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_calendar_holidays[0]|.id"`
                echo "Ok: sla_calendar_holiday_id exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
#
#
# SLA LEVEL
#
NAME="Level Bug Tracker"
DATA="{ \"sla_level\": { \"name\": \"$NAME\", \"sla_id\": \"$SLA_ID\", \"sla_calendar_id\": \"$SLA_CALENDAR_ID\" } }"
EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json"`
ID=`echo $EXEC|jq -r ".sla_level|.id"`
if [ $((ID+0)) -gt 0 ]; then
        echo "Ok: sla_level add n°$ID"
else
        ERROR=`echo $EXEC|jq -r ".errors[0]"`
        if [ "$ERROR" == "Name has already been taken" ]; then
                SEARCH="sla_id=$SLA_ID&sla_calendar_id=$SLA_CALENDAR_ID"
                EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/levels.json?$SEARCH"`
                ID=`echo $EXEC|jq -r ".sla_levels[0]|.id"`
                echo "Ok: sla_level exists n°$ID"
        else
                echo "Error: $ERROR"
                exit 1
        fi
fi
SLA_LEVEL_ID=$ID
#
#
# SLA LEVEL TERMS
#
LEVEL_TERMS=(
  '"priority_id": "1", "term": "1440"'
  '"priority_id": "2", "term": "480"'
  '"priority_id": "3", "term": "240"'
)
for i in $(echo ${!LEVEL_TERMS[@]}); do
  LEVEL_TERM=${LEVEL_TERMS[$i]}
  DATA="{ \"sla_level_term\": { \"sla_level_id\": \"$SLA_LEVEL_ID\", \"sla_type_id\": \"$SLA_TYPE1_ID\", $LEVEL_TERM } }"
  EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`
  ID=`echo $EXEC|jq -r ".sla_level_term|.id"`
  if [ $((ID+0)) -gt 0 ]; then
          echo "Ok: sla_level_term add n°$ID"
  else
          ERROR=`echo $EXEC|jq -r ".errors[0]"`
          if [ "$ERROR" == "SLA Level This term alredy exists" ]; then
                  PRIORITY_ID=`echo $DATA|jq -r ".sla_level_term|.priority_id"`
                  SEARCH="sla_level_id=$SLA_LEVEL_ID&sla_type_id=$SLA_TYPE1_ID&priority_id=$PRIORITY_ID"
                  EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json?$SEARCH"`
                  ID=`echo $EXEC|jq -r ".sla_level_terms[0]|.id"`
                  echo "Ok: sla_level_term exists n°$ID"
          else
                  echo "Error: $ERROR"
                  exit 1
          fi
  fi
done
LEVEL_TERMS=(
  '"priority_id": "1", "term": "4320"'
  '"priority_id": "2", "term": "1920"'
  '"priority_id": "3", "term": "1200"'
)
for i in $(echo ${!LEVEL_TERMS[@]}); do
  LEVEL_TERM=${LEVEL_TERMS[$i]}
  DATA="{ \"sla_level_term\": { \"sla_level_id\": \"$SLA_LEVEL_ID\", \"sla_type_id\": \"$SLA_TYPE2_ID\", $LEVEL_TERM } }"
  EXEC=`curl -s -H "Content-Type: application/json" -X POST --data "$DATA" -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json"`
  ID=`echo $EXEC|jq -r ".sla_level_term|.id"`
  if [ $((ID+0)) -gt 0 ]; then
          echo "Ok: sla_level_term add n°$ID"
  else
          ERROR=`echo $EXEC|jq -r ".errors[0]"`
          if [ "$ERROR" == "SLA Level This term alredy exists" ]; then
                  PRIORITY_ID=`echo $DATA|jq -r ".sla_level_term|.priority_id"`
                  SEARCH="sla_level_id=$SLA_LEVEL_ID&sla_type_id=$SLA_TYPE2_ID&priority_id=$PRIORITY_ID"
                  EXEC=`curl -s -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: $APIKEY" "$TRACKER/sla/level_terms.json?$SEARCH"`
                  ID=`echo $EXEC|jq -r ".sla_level_terms[0]|.id"`
                  echo "Ok: sla_level_term exists n°$ID"
          else
                  echo "Error: $ERROR"
                  exit 1
          fi
  fi
done