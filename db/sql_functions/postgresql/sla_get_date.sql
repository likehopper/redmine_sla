-- SPDX-License-Identifier: GPL-2.0-or-later
--
-- Redmine SLA - service level agreement plugin
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.
-- File: redmine_sla/db/sql_functions/postgresql/sla_get_date.sql
-- Remove the existing function to ensure a clean redeployment
DROP FUNCTION IF EXISTS sla_get_date CASCADE ;

-- Normalize a timestamp to the SLA timezone and truncate to the minute.
-- This function is used everywhere a consistent datetime reference is required.
CREATE FUNCTION sla_get_date(p_date TIMESTAMP WITHOUT TIME ZONE)
  RETURNS TIMESTAMP WITHOUT TIME ZONE
  LANGUAGE sql
AS $BODY$

-- Convert the input timestamp into the SLA-specific configured timezone.
-- Steps:
-- 1. Retrieve the configured SLA timezone from plugin settings.
--    The setting is stored as a serialized hash inside Redmine's settings table.
--    We extract it by regex from the "plugin_redmine_sla" setting.
-- 2. Fallback to 'Etc/UTC' if no timezone is configured.
-- 3. Apply the timezone conversion.
-- 4. Truncate the result to the minute (SLA granularity).
--
-- Note:
--   p_date is always interpreted as UTC first ("AT TIME ZONE 'Etc/UTC'")
--   then converted to the configured timezone via TIMEZONE().
SELECT DATE_TRUNC(
  'MINUTE',
  TIMEZONE(
    (
      SELECT COALESCE(
        (
          -- Extract SLA timezone from Redmine plugin settings (YAML-like blob)
          SELECT SUBSTRING(value FROM 'sla_time_zone: ([a-z,A-Z,/]*)')
          FROM settings
          WHERE name LIKE 'plugin_redmine_sla'
        ),
        -- Default timezone if none is configured
        'Etc/UTC'
      )
    ),
    -- Normalize input timestamp as UTC before conversion
    p_date AT TIME ZONE 'Etc/UTC'
  )
)

$BODY$ ;