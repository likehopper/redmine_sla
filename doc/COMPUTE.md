# Compute

The foundation for calculating SLAs is based on the use of PostgreSQL's generate_series function.


## Concepts

As part of Service Level Agreements (SLA), we usually calculate intervention and times commitments.

Let's start from Redmine's default statuses, namely: New, Assigned, Resolved, Feedback, Closed, Rejected.

The intervention commitment lasts as long as the ticket is new, ie as long as the ticket is in the “New” status.

The duration of the resolution commitment goes from the creation of the issue and its closure, from which we subtract the times of "inactivity", ie as long as the ticket is in the “New” or "Assigned" statuses :
- Resolved: a solution is proposed (pending validation)
- Feedback: a request for additional information is in progress (pending after reporter)
- Closed, Rejected: issue is closed, no more actions are expected.


## Summary

With the generate_series function, we generate a list for each minute of the creation of the issue at the closing (or at the current timestamp, if the issue isn't closed). A reopened issue is not closed: Redmine keeps its last closing date (`closed_on`), which is ignored until the issue is closed again.

For example, an issue was created on 06/01/2023 at 10:00 a.m. and it was closed on 06/01/2023 at 10:10 a.m., so we will have a series of 10 lines :
- 2023-06-01 10:01
- 2023-06-01 10:02
- 2023-06-01 10:03
- 2023-06-01 10:04
- 2023-06-01 10:05
- 2023-06-01 10:06
- 2023-06-01 10:07
- 2023-06-01 10:08
- 2023-06-01 10:09
- 2023-06-01 10:10


## Issues statuses

To find the delay in minutes between opening and closing the titcket : just count the rows.

It's not interesting if nothing happens! But, let's imagine changes in the status of the issue :
- 2023-06-01 10:01 - New
- 2023-06-01 10:02 - New
- 2023-06-01 10:03 - Assigned
- 2023-06-01 10:04 - Feedback
- 2023-06-01 10:05 - Feedback
- 2023-06-01 10:06 - Assigned
- 2023-06-01 10:07 - Assigned
- 2023-06-01 10:08 - Resolved
- 2023-06-01 10:09 - Resolved
- 2023-06-01 10:10 - Closed

To calculate the intervention commitment, all you have to do is filter the lines whose status is "New". We will get 2 lines and therefore the delay is 2 minutes!

And for the resolution engagement, we filter with the status "New" or "Awarded". We get 5 lines, so the resolution time is 5 minutes!

Easy and efficient!


## SLA Calendars

### Selecting the SLA level

For each issue, only levels belonging to its project/tracker SLA mapping and
having at least one term for its current priority are candidates. A level's
priority source is determined independently: the native issue priority when
`custom_field_id` is blank, or that level's custom-field enumeration otherwise.
Among eligible levels, the existing rule applies: the earliest matching
calendar start wins, then the lowest level id breaks a tie. If no eligible
level has a matching calendar start, no SLA level or cache is returned.

Changing an issue's priority recalculates its level from the issue's creation
time with the new priority's calendar. Time is not split across the old and new
priority periods.

The SLA Calendars will finally make it possible to complete the times of activity or non-activity.


### SLA Holidays

SLA Holidays are completely non-working days: the lines corresponding to these days will be deleted.

The notion carried by the “match” boolean:
- if it is false, then the days will be deleted, ie time is suspended.
- if it is true, then an SLA cannot start on the holiday but, if it started earlier then it will continue.


### Schedules

With the SLA Schedules, it is possible to determine the ranges of working hours.

We find the same concept with "match" booleann, this allows you to define the non-working hours during which you must continue to solve the ticket.


## Implementation Note (Optimization)

The principle above still holds, but the actual stored procedures no longer generate one row per minute.

Instead, `generate_series` produces one row per **calendar day** between the issue's creation and its closing (or the current timestamp). For each day, the working-hours window (schedule), the status interval (roll status) and the calculation window are intersected using a closed-form `GREATEST` / `LEAST` computation on timestamps, and the resulting overlap is summed directly in seconds/minutes -- instead of counting one row per elapsed minute.

This produces the exact same total as the minute-by-minute principle described above, but scales to issues open for months or years without generating millions of rows.
