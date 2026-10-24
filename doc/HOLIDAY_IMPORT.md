# Public holiday import

Administrators can open **Import public holidays** from the SLA holiday list,
choose a year and country, preview the response, and import selected dates.
The plugin settings accept an optional ISO country code (for example `FR`)
as the default. Redmine's default language does not determine a country.

The form requests the country list from Nager.Date's community API v4.
The Redmine server needs outbound HTTPS access to `nagerholidays.com`.

Only holidays of type `Public` are offered. National holidays are selected by
default; regional holidays show their subdivision codes and require selection.
The community API v4 supplies holiday names in English. Existing dates retain
their names and calendar associations. Selected entries on the same date are combined into
one name because the model enforces a unique date. Importing does not attach new
holidays to calendars; use the existing calendar-holiday configuration for that.

The preview is signed, belongs to the current administrator, and expires after
15 minutes. Import uses the previewed data without fetching the API again.
The import runs in a database transaction, rechecks existing dates, and rolls
back all creations if validation or a concurrent uniqueness conflict fails.
HTTP connection/read timeouts are 5/10 seconds. Network errors, non-success HTTP
responses, invalid JSON and invalid holiday data produce a translated error and
no import. Refresh the form to retry an unavailable service.

## Design

`SlaHolidayImporter` handles preview and persistence using an injected adapter.
`SlaHolidayAdapters::NagerDate` handles HTTP and validates API v4 responses.
Adapters return country options as `[name, ISO code]` pairs and holidays with
string keys `date` (ISO date), `name`, `national` (boolean) and `regions`
(subdivision code array). No API key or configurable destination is required.
