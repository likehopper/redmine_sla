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

With the generate_series function, we generate a list for each minute of the creation of the issue at the closing (or at the current timestamp, if the issue isn't closed).

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

The SLA Calendars will finally make it possible to complete the times of activity or non-activity.

### SLA Holidays

SLA Holidays are completely non-working days: the lines corresponding to these days will be deleted.

The notion carried by the “match” boolean:
- if it is false, then the days will be deleted, ie time is suspended.
- if it is true, then an SLA cannot start on the holiday but, if it started earlier then it will continue.

### Schedules

With the SLA Schedules, it is possible to determine the ranges of working hours.

We find the same concept with "match" booleann, this allows you to define the non-working hours during which you must continue to solve the ticket.
