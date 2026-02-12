# EXAMPLE-05 — Complex service levels in working (HO) and non-working hours (HNO)

This final example demonstrates the **most advanced time-calculation behavior** of the Redmine SLA plugin:
**combining working hours (HO) and non-working hours (HNO)** within the same service model.

Up to now (EXAMPLE-01 → EXAMPLE-04), all SLAs followed a simple rule:

> SLA time elapses **only during working hours**.

In real-life operations, this assumption is often insufficient.  
This example explains **why**, **how**, and **with which configuration primitives** you can go further.

---

## What problem this example addresses

Some support organizations operate with **partial coverage**:

- a standard support team during business hours (HO)
- limited or different commitments outside business hours (HNO)
- incidents may:
  - be created at any time
  - start during HO and continue during HNO
  - be paused during HNO and resume at the next HO

The challenge is therefore **not only defining hours**, but defining:

- when an issue **can start**
- when SLA time **runs**
- when SLA time **pauses**
- whether time can **continue across HO/HNO boundaries**

---

## Target working schedule

### Working hours (HO)

| Day | Start | End |
|----|-------|-----|
| Monday | 09:00 | 18:00 |
| Tuesday | 09:00 | 18:00 |
| Wednesday | 09:00 | 18:00 |
| Thursday | 09:00 | 18:00 |
| Friday | 09:00 | 18:00 |

These periods represent **normal business activity**:
- issues can be created
- work can start
- SLA time runs

---

### Non-working hours (HNO)

| Period | Description |
|-------|-------------|
| Nights | Outside 09:00–18:00 |
| Weekends | Saturday & Sunday |
| Holidays | Defined SLA holidays |

During HNO:
- issues may or may not be created (depending on configuration)
- work may or may not continue
- SLA time may or may not run

➡️ These rules are **explicitly modeled**, not implicit.

---

## Key concept: HO and HNO are not opposites

In the plugin, HO and HNO are **not hard-coded concepts**.  
They are the result of **calendar schedules + the `match` flag**.

This allows you to model **three distinct behaviors**:

| Scenario | Can issue start? | Does time run? |
|--------|-----------------|----------------|
| HO only | Yes | Yes |
| HNO pause | No | No |
| HNO continuation | No | Yes |

This distinction is what makes complex SLA behavior possible.

---

## Reminder: the meaning of `match` on schedules

Each calendar schedule defines a time window and a **match** flag.

- **match = true**
  - issues are allowed to start in this window
  - typically represents HO

- **match = false**
  - issues cannot start in this window
  - SLA time may still continue
  - typically represents HNO continuation

> This single flag is the foundation of all HO/HNO modeling.

---

## What this example adds compared to EXAMPLE-02

**One new facet only**:

- SLA calculation across **HO and HNO**, using the calendar `match` behavior

Everything else remains unchanged:
- multiple SLA Types (Response time + Resolution deadline)
- native Redmine priorities
- a single project
- no custom field
- no multi-SLA per tracker

---

## 1) Create the SLA and SLA Types (same foundations as EXAMPLE-02)

### 1.1 Create the SLA

Go to:

`Administration → SLA Global settings → Service Level Agreements`

Create an SLA (example: **SLA HO/HNO**):

![Create SLA](screenshots/example-05/01-01-01-01-sla-new.png)

Verify the list:

![SLA list](screenshots/example-05/01-01-01-02-sla-created.png)

### 1.2 Create SLA Types

Go to:

`Administration → SLA Global settings → SLA Types`

Create:
- Response time
- Resolution deadline

![Create SLA Type — Response time](screenshots/example-05/02-01-01-01-sla_type-new.png)
![Create SLA Type — Resolution deadline](screenshots/example-05/02-01-02-01-sla_type-new.png)

Verify the list:

![SLA Types list](screenshots/example-05/02-01-02-02-sla_type-created.png)

---

## 2) Define SLA Statuses (same foundations as EXAMPLE-02)

Go to:

`Administration → SLA Global settings → SLA Statuses`

Define when each SLA Type elapses:
- Response time → New
- Resolution deadline → In Progress

![SLA Status — Response time](screenshots/example-05/03-01-01-01-01-sla_status-new.png)
![SLA Status — Resolution deadline](screenshots/example-05/03-01-02-01-01-sla_status-new.png)

Verify the list:

![SLA Status list](screenshots/example-05/03-01-02-02-02-sla_status-created.png)

---

## 3) Create calendars modeling HO and HNO behavior

Go to:

`Administration → SLA Global settings → SLA Calendars`

Create a calendar defining:
- HO schedules with **match = true**
- HNO schedules with **match = false**

![Create SLA Calendar](screenshots/example-05/04-01-01-01-sla_calendar-new.png)

Verify the list:

![Calendar list](screenshots/example-05/04-01-01-02-sla_calendar-created.png)

---

## 4) Holidays (non-working days)

Create holidays:

![Create one SLA Holiday](screenshots/example-05/05-01-01-01-sla_holiday-new.png)

Verify the list:

![SLA Holidays list](screenshots/example-05/05-02-sla_holiday-list.png)

Assign holidays to the calendar:

![Calendar holiday mapping](screenshots/example-05/06-01-01-01-sla_calendar_holiday-new.png)

Verify mappings:

![Calendar holiday list](screenshots/example-05/06-02-sla_calendar_holiday-list.png)

---

## 5) Create the project and enable SLA

Create a test project:

![Create project](screenshots/example-05/07-01-01-project-new.png)

Verify it:

![Project overview](screenshots/example-05/07-02-01-project-show.png)

Enable the SLA module:

![Enable SLA module](screenshots/example-05/11-01-01-project-settings-issues.png)

---

## 6) Create SLA Levels representing HO/HNO regimes

Go to:

`Administration → SLA Global settings → SLA Levels`

Create multiple SLA Levels if needed:
- one representing HO behavior
- one representing HNO behavior or continuation rules

![Create SLA Level (1)](screenshots/example-05/09-01-01-01-sla_level-new.png)
![Create SLA Level (2)](screenshots/example-05/09-01-02-01-sla_level-new.png)

Verify the list:

![SLA Levels list](screenshots/example-05/09-01-01-02-sla_leel-created.png)

---

## 7) Define SLA Terms for HO and HNO

Go to:

`Administration → SLA Global settings → SLA Terms`

Create terms reflecting:
- stricter HO targets
- different or extended HNO targets

![SLA Terms creation (1)](screenshots/example-05/10-01-01-01-sla_level_term-new.png)
![SLA Terms creation (2)](screenshots/example-05/10-01-02-01-sla_level_term-new.png)
![SLA Terms creation (3)](screenshots/example-05/10-01-03-01-sla_level_term-new.png)

Verify the list:

![SLA Terms list](screenshots/example-05/10-01-01-02-sla_level_term-created.png)

---

## 8) Map the SLA to the project tracker

Go to:

`Project → Settings → SLA`

Create the tracker → SLA mapping:

![Tracker/SLA mapping](screenshots/example-05/11-04-01-01-project-settings-sla-new.png)

Verify the list:

![Project SLA list](screenshots/example-05/11-05-01-project-settings-sla-list.png)

---

## 9) Observe HO/HNO behavior on issues

The screenshots below illustrate different timelines:
- issue created in HO
- issue created in HNO
- work starting in HO and continuing in HNO
- work resuming at next HO

![Issue scenario 1](screenshots/example-05/12-01-01-issue_past_1-issue-show.png)
![Issue scenario 2](screenshots/example-05/12-01-02-issue_past_2-issue-show.png)
![Issue scenario 3](screenshots/example-05/12-01-03-issue_past_3-issue-show.png)
![Issue scenario 4](screenshots/example-05/12-01-04-issue_past_4-issue-show.png)

---

## What you learned in this example

With EXAMPLE-05, you learned how to:

- explicitly model working and non-working hours
- control when issues can start and when time runs
- use the `match` flag to represent HO/HNO behavior
- build advanced SLA models without custom code

This concludes the progressive SLA documentation examples.