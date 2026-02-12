# EXAMPLE-03 — Service levels with both *Bug* and *Request* in the same project

This third example introduces a new and important capability of the Redmine SLA plugin:
**using multiple SLAs within the same project**, depending on the **tracker**.

Up to now:
- EXAMPLE-01 showed a single SLA with one commitment (GTI)
- EXAMPLE-02 extended this SLA with a second commitment (GTR)

Here, we keep the same technical foundations, but we **duplicate the SLA logic** to support
different types of work (for example *Bugs* vs *Requests*) inside a single project.

---

## What this example adds compared to EXAMPLE-02

**One new facet only**:

- Multiple SLAs can coexist **in the same project**
- Each SLA is selected **by the issue tracker**

Everything else remains unchanged:
- working hours only (HO)
- priorities based on native Redmine priorities
- no custom field
- no HO/HNO advanced behavior

---

## What we want to achieve

We manage a single support project, but with **two different types of issues**:

1. **Bugs**
   - stricter response and resolution times
2. **Requests**
   - more flexible response and resolution times

Both issue types:
- live in the **same project**
- share the same working calendar
- have **different SLAs**

The SLA applied to an issue is determined **only by its tracker**.

---

## Target SLA design

### SLA 1 — Bug SLA

Applies to tracker: **Bug**

- Response time (GTI)
- Resolution deadline (GTR)
- Aggressive targets

### SLA 2 — Request SLA

Applies to tracker: **Request**

- Response time (GTI)
- Resolution deadline (GTR)
- More relaxed targets

---

## Key idea: SLA selection is tracker-based

In a project, the plugin evaluates SLAs in this order:

```
Issue
 └─ Tracker
     └─ SLA mapping (project level)
         └─ SLA definition
             ├─ SLA Types
             ├─ SLA Levels
             └─ SLA Terms
```

➡️ The **tracker** is the decision key.

---

## 1) Create the SLAs

Go to:

`Administration → SLA Global settings → Service Level Agreements`

Create **two SLAs**:

- `SLA Bug`
- `SLA Request`

![Create SLA](screenshots/example-03/01-01-01-01-sla-new.png)

Verify both appear in the list:

![SLA list](screenshots/example-03/01-01-01-02-sla-created.png)

---

## 2) Create the SLA Types (same as EXAMPLE-02)

We reuse the same SLA Types for both SLAs:

- Response time
- Resolution deadline

Go to:

`Administration → SLA Global settings → SLA Types`

Create the types if they do not already exist:

![Create SLA Types](screenshots/example-03/02-01-01-01-sla_type-new.png)

Verify the list:

![SLA Types list](screenshots/example-03/02-01-01-02-sla_type-created.png)

---

## 3) Define SLA Statuses (shared by both SLAs)

Go to:

`Administration → SLA Global settings → SLA Statuses`

Define when each SLA Type elapses:

- **Response time** → New
- **Resolution deadline** → In Progress (and related statuses)

![Create SLA Status](screenshots/example-03/03-01-01-01-01-sla_status-new.png)

Verify the list:

![SLA Status list](screenshots/example-03/03-01-01-01-02-sla_status-created.png)

> SLA Statuses are **global**: they apply to all SLAs using the same SLA Type.

---

## 4) Create the SLA Calendar (shared)

Go to:

`Administration → SLA Global settings → SLA Calendars`

Create one calendar (same working hours as previous examples):

![Create SLA Calendar](screenshots/example-03/04-01-01-01-sla_calendar-new.png)

Verify the list:

![Calendar list](screenshots/example-03/04-01-01-02-sla_calendar-created.png)

---

## 5) Create Holidays and assign them to the calendar

Create holidays (same logic as previous examples):

![Create SLA Holiday](screenshots/example-03/05-01-01-01-sla_holiday-new.png)

Verify the holiday list:

![Holiday list](screenshots/example-03/05-02-sla_holiday-list.png)

Assign holidays to the calendar:

![Calendar holiday mapping](screenshots/example-03/06-01-01-01-sla_calendar_holiday-new.png)

---

## 6) Create the project

Create a project that will host **both trackers**:

![Create project](screenshots/example-03/07-01-01-project-new.png)

Verify the project:

![Project overview](screenshots/example-03/07-02-01-project-show.png)

Enable the SLA module in project settings (same as previous examples).

---

## 7) Create SLA Levels (one per SLA)

Go to:

`Administration → SLA Global settings → SLA Levels`

Create two levels:

- `Level Bug` → linked to `SLA Bug`
- `Level Request` → linked to `SLA Request`

Both levels can use the **same calendar**.

![Create SLA Levels](screenshots/example-03/09-01-01-01-sla_level-new.png)

Verify the list:

![SLA Levels list](screenshots/example-03/09-01-01-02-sla_leel-created.png)

---

## 8) Define SLA Terms per SLA

Go to:

`Administration → SLA Global settings → SLA Terms`

### 8.1 Bug SLA Terms

Define stricter targets for **Bug**:

![Bug SLA Terms](screenshots/example-03/10-01-01-01-sla_level_term-new.png)

### 8.2 Request SLA Terms

Define more relaxed targets for **Request**:

![Request SLA Terms](screenshots/example-03/10-01-02-01-sla_level_term-new.png)

Verify the list:

![SLA Terms list](screenshots/example-03/10-01-01-02-sla_level_term-created.png)

---

## 9) Map trackers to SLAs at project level

Go to:

`Project → Settings → SLA`

Create mappings:

- Tracker **Bug** → `SLA Bug`
- Tracker **Request** → `SLA Request`

![Create tracker/SLA mapping](screenshots/example-03/11-04-01-01-project-settings-sla-new.png)

Verify mappings:

![Project SLA list](screenshots/example-03/11-05-01-project-settings-sla-list.png)

---

## 10) View SLAs on issues

Create two issues in the same project:
- one **Bug**
- one **Request**

Each issue will automatically use the SLA mapped to its tracker.

Example issue view:

![Issue with SLA](screenshots/example-03/12-01-01-issue_1-issue-show.png)

---

## What you learned in this example

With EXAMPLE-03, you learned that:

- multiple SLAs can coexist in a single project
- SLA selection is based on the **tracker**
- SLAs can share calendars and SLA Types
- SLA logic remains isolated per SLA definition

The next example (EXAMPLE-04) will introduce **custom fields for SLA priority**, allowing even more flexibility.