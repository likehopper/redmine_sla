# Step-by-step use case

These examples are present in the web interface after the launch of the functional tests :
-	TMA Support : Support request on hours worked (HO) with GTI only
- TMA Bug : tracker bug on hours worked (HO) with GTI/GTR
-	"Managed Services Standard" and "Managed Services Spécific" : for change request on hours worked (HO) and for production incident also on non-working hours (HNO).


## Connctions

Differents users are configured :
- user `admin` with pass `admin`
- user `manager` with pass `manager`
- user `developer` with pass `developer`
- user `reporter` with pass `reporter`


## Redmine base

For each user an eponymous role has been defined
- role `admin` : he can define the SLAs in the global configuration.
- role `manager` : he sees the SLAs and manages them in the projects.
- role `developer` : it only sees SLAs in issues.
- role `reporter` : he doesn't see the SLAs nowhere.

A few issue priorities are defined in enumerations : low, normal and high. Currently, only "normal" priority is used in tests.


## Simple case with only HO

Typically, in TMA, commitments are in working hours. Outside of these hours, weekends and public holidays, past times are suspended.


## Complexe whith NHO

In outsourcing, commitments for change requests are defined as in TMA.
Commitments for incidents are not the same whether they occur during business hours or not. But, whatever the hour at which an incident occurs, the past times do not stop.

