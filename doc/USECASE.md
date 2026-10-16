# Step-by-step use case

These examples are present in the web interface after the launch of the functional tests :
-	TMA Support : Support request on hours worked (HO) with GTI only
- TMA Bug : tracker bug on hours worked (HO) with GTI/GTR
-	"Managed Services Standard" and "Managed Services Spécific" : for change request on hours worked (HO) and for production incident also on non-working hours (HNO).


## Connections

Different users are configured, each with their login as password:
`admin`, `manager`, `developer`, `reporter`.


## Redmine base

- `admin` is a Redmine administrator: they define the SLAs in the global configuration.
- `manager` has the Manager role (`view_sla`, `manage_sla`): they see the SLAs and manage them in the projects.
- `developer` has the Resolver role (`view_sla`): they only see SLAs in issues.
- `reporter` has the Reporter role (no SLA permission): they don't see SLAs anywhere.

See [Roles and permissions](SETTINGS.md#roles-and-permissions) and [Testing](TESTING.md#roles).

A few issue priorities are defined in enumerations : low, normal and high. Currently, only "normal" priority is used in tests.


## Simple case with only HO

Typically, in TMA, commitments are in working hours. Outside of these hours, weekends and public holidays, past times are suspended.


## Complexe whith NHO

In outsourcing, commitments for change requests are defined as in TMA.
Commitments for incidents are not the same whether they occur during business hours or not. But, whatever the hour at which an incident occurs, the past times do not stop.

