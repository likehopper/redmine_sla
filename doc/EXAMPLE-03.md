# Example n°3 : Complex service levels in working (HO) and non-working hours (HNO)


For a managed services provider, open Monday to Friday from 8:00 a.m. to 9:00 p.m., we want to monitor commitments on response (GTI) and resolution times (GTR).

**TMA in working hours**
| Dow       | Start time  |	End time  |
|-----------|-------------|-----------|
| Monday    |    08:00    |   18:00   |
| Tuesday   |    08:00    |   18:00   |
| Wednesday |    08:00    |   18:00   |
| Thursday  |    08:00    |   18:00   |
| Friday    |    08:00    |   18:00   |

However, when an issue occurs during working hours, the delays continue during non-working hours.
And, when an anomaly occurs during non-working hours, other deadlines apply. However, when an issue occurs during non-working hours, the delays continue during working hours.

Response time will be calculated as long as the issue is in a "new" state during the above business hours. Indeed, the Response time is stop when the issue is in others statuses (either "In progress", "Resolved", "Comments", "Closed" and "Rejected" state).
Resolution time will be calculated as long as the issue is in a "new" and "In progress" state during the above business hours. Indeed, the resolution time is suspended when the issue is in a "Resolved", "Comments", "Closed" and "Rejected" state.

In the projects, we will apply this SLA to the tracker « tracker_production_incident » :

**LEVEL for Managed Services on working hours **
| Issue priorities / SLA Levels | Response time | Resolution deadline |
|-------------------------------|---------------|---------------------|
| Minor                         |      15mn     |          4h         |
| Major                         |      15mn     |          4h         |
| blocker                       |      15mn     |          4h         |

**LEVEL for Managed Services on non-working hours **
| Issue priorities / SLA Levels | Response time | Resolution deadline |
|-------------------------------|---------------|---------------------|
| Minor                         |      30mn     |          4h         |
| Major                         |      30mn     |          4h         |
| blocker                       |      30mn     |          4h         |

Here, whatever the issue's level, the deadlines are the same.


## Create SLA

The SLA configuration bring together the entire definition of the SLA

To begin, go to `Administration » SLA Global settings` (https://[redmine-host]/sla/slas). Add "SLA Managed Services Standard tracker_production_incident" as new "Service Level Agreements".
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 01](images/example_03/redmine_sla_doc_example_03_01.png)
</div>

So, this will bring together the entire definition of the SLA that we described in the introduction.


## Create SLA Types

The SLA Types' configuration define the various commitments possibles.

Go to `Administration » SLA Global settings » SLA Types` (https://[redmine-host]/sla/types). Add "GTI" as new "SLA Type".
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 02](images/example_03/redmine_sla_doc_example_03_02.png)
</div>

Add "GTR" as new "SLA Type".
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 03](images/example_03/redmine_sla_doc_example_03_03.png)
</div>

Restart Redmine for applys patches with all sla types:
- Issue : for display columns of the respect of each sla type in issues report
- IssueQuery : for filter issues on the respect of each sla type in issues report
- TimeEntry : for display columns of the respect of each sla type in time entries report
- TimeEntryQuery : for filter issues on the respect of each sla type in time entries report


## Create SLA Statuses

The SLA Statuses' configuration allows to define for which statuses the time elapses.

Go to `Administration » SLA Global settings » SLA Statuses` (https://[redmine-host]/sla/statuses). Add "SLA Statuses" for "GTI" with this statuses :
- New
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 04](images/example_03/redmine_sla_doc_example_03_04.png)
</div>

Add "SLA Statuses" for "GTR" with this statuses :
- New
- In progress
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 05](images/example_03/redmine_sla_doc_example_03_05.png)
</div>

The addition of this tuple indicates that the ticket creation delay should be calculated only when then issue was is in this status (i.e. while the ticket is in this status).


## Create SLA Holidays

This module is used to list all the holidays (non-working days or even exceptional closing days) that will be needed in the SLA duration count.

Go to `Administration » SLA Global settings » SLA Holidays` ( https://[redmine-host]/sla/holidays). Add new "SLA Holidays" like in the fixtures, we have all the French public holidays of the year 2021 for example :
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 06](images/example_03/redmine_sla_doc_example_03_06.png)
</div>


## Create SLA Calendar (& SLA Calendar' Schedule)

The SLA calendar is important, it allows to define the working hours and non-working hours of the week.

If the "match" field is checked, then the issue can be opened in this time slot (opening hours). If the time is declared with the "match" field unchecked, then the issue cannot be opened in this slot, however the time calculation can continue on this slot (non-working hours).

Typically, for support activities, deadlines are suspended outside business hours. If an issue is opened during non-working hours, then the calculation starts at the next working hour. Conversely, in the case of web hosting, an issue can be opened at any time and continues regardless of the time. If an exit is opened during working hours then it continues during non-working hours and vice versa.

Go to Administration » SLA Global settings » SLA Calendar ( https://[redmine-host]/sla/calendars ). Add "Managed services std - HO - Incident" as new "SLA Calendar"
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 07 - 01](images/example_03/redmine_sla_doc_example_03_07-01.png)
</div>

Edit this SLA Calendar and add schedules :
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 08 - 01](images/example_03/redmine_sla_doc_example_03_08-01.png)
</div>

Go to Administration » SLA Global settings » SLA Calendar ( https://[redmine-host]/sla/calendars ). Add "Managed Services std - HNO - Incident" as new "SLA Calendar"
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 07 - 02](images/example_03/redmine_sla_doc_example_03_07-02.png)
</div>

Edit this SLA Calendar and add schedules :
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 08 - 02](images/example_03/redmine_sla_doc_example_03_08-02.png)
</div>

> **_NOTE:_** These are the intervals from a start time to an end time, so the time is usually stopped by subtracting one minute from the end time. Indeed, taking a schedule of 8am to 9am, so to get well 60 minutes, it's therefore necessary to declare from 8am to 8:59am.


## Create SLA Calendars' Holidays

So, we can create several SLA Calendars with SLA Schedules. For each SLA Calendar, you can also assign SLA Holidays.

For SLA Calendars' Holidays, the "match" field has the opposite meaning to SLA Calendar' Schedules. Indeed, for SLA Calendar' Schedules, the hours worked were declared. For SLA Calendars' Holidays, the hours not worked are declared. 
By default, we add a public holiday to remove it from the calculations. However, if the "match" field is checked, then the time will be counted. However, if a ticket is open on this slot, then it cannot start until the next working hour.

Go to `Administration » SLA Global settings » SLA Calendars' Holidays` (https://[redmine-host]/sla/calendar_holidays). Add "TMA in working hours" as new "SLA Calendars' Holidays"
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 09](images/example_03/redmine_sla_doc_example_03_09.png)
</div>

For our example, which is a support service, public holidays are equivalent to times that shouldn't be counted.


## Create SLA Levels

After declaring SLAs and SLA Schedules, they can be linked to define service levels. In other words, the SLA Levels make it possible to know the moment "when" commitments will apply.

Go to `Administration » SLA Global settings » SLA Levels` (https://[redmine-host]/sla/levels). Add "Managed Services STD - Incident HO" and "Managed Services STD - Incident HNO" as new "SLA Levels"
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 10](images/example_03/redmine_sla_doc_example_03_10.png)
</div>


## Create SLA Terms

Finally, we can define the SLA Terms. For an SLA Level, an SLA Type and a priority, you can define a time commitment (in minutes).

Go to `Administration » SLA Global settings » SLA Terms` (https://[redmine-host]/sla/level_terms). Add each term for "Managed Services STD - Incident HO" :
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 11](images/example_03/redmine_sla_doc_example_03_11.png)
</div>

Add each term for "Managed Services STD - Incident HO" :
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 12](images/example_03/redmine_sla_doc_example_03_12.png)
</div>


## Apply SLA to a Project

Go to your project' settings ( https://[redmine-host]/projects/[project-identifier]/settings ). Active SLA module for your project.
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 13](images/example_03/redmine_sla_doc_example_03_13.png)
</div>

The tab should appear `SLA Project settings`, go to this tab (http://[redmine-host]/projects/[project-identifier]/settings/slas). With "New SLA project's tracker" définie à SLA for a tracker.
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 14](images/example_03/redmine_sla_doc_example_03_14.png)
</div>


## View SLA into an issue

When you go to a project's issue, you should see the SLA appear if it matches with the status and priority.
<div style=" width:50%; height:50%; " >

![Redmine SLA - Example 03 - 15](images/example_03/redmine_sla_doc_example_03_15.png)
</div>


## Roles

Until then, you were an administrator. However, in order for the members of your project to be able to see the SLAs, or even manage their activation within the project, you must grant them this right.

Got to `Administration » Roles and permissions` (http://[redmine-host]/roles). Edit a role (http://[redmine-host]/roles/[role-id]/edit) to check "View SLA" (ex: for manager and developer) and/or "Manage SLA" (ex: for manager).

