# frozen_string_literal: true

module RedmineSla
  # Adapter-neutral, read-only explanation of SLA level and spent-time
  # decisions. Production cache calculations remain in optimized SQL.
  class SlaExplanation
    SEARCH_WINDOW = 7.days

    def initialize(issue, connection: ActiveRecord::Base.connection)
      @issue = issue
      @connection = connection
    end

    def issue_created_on
      @issue_created_on ||= @connection.select_value(
        ActiveRecord::Base.sanitize_sql(["SELECT sla_get_date(?)", @issue.created_on])
      ).to_time
    end

    def levels
      rows = candidate_levels.map do |level|
        start_date = first_matching_minute(level.sla_calendar_id)
        {
          'sla_level_id' => level.id,
          'sla_level_name' => level.name,
          'sla_calendar_id' => level.sla_calendar_id,
          'sla_calendar_name' => level.sla_calendar.name,
          'matched' => !start_date.nil?,
          'start_date' => start_date,
          'selected' => false
        }
      end

      selected = rows.filter_map { |row| row['start_date'] }.min
      rows.each { |row| row['selected'] = row['start_date'] == selected if selected }
      rows.sort_by { |row| [row['start_date'].nil? ? 1 : 0, row['start_date'] || Time.at(0)] }
    end

    def spent(sla_type_id)
      cache = SlaCache.find_by(issue_id: @issue.id)
      return [] unless cache

      tracked_ids = SlaStatus.where(sla_type_id: sla_type_id).pluck(:status_id).map(&:to_i)
      calendar_id = cache.sla_level.sla_calendar_id
      statuses = IssueStatus.where(id: roll_status_ids).index_by(&:id)

      roll_statuses.flat_map do |interval|
        from_date = interval['from_status_date'].to_time
        to_date = interval['to_status_date'].to_time
        next [] unless to_date > from_date

        from_id = interval['from_status_id'].to_i
        to_id = interval['to_status_id'].to_i
        tracked = tracked_ids.include?(from_id)
        days = tracked ? (from_date.to_date..(to_date - 1.minute).to_date).to_a : [from_date.to_date]

        days.map do |day|
          holiday = excluded_holidays(calendar_id)[day]
          schedules = schedules_for_day(calendar_id, day)
          {
            'from_status_id' => from_id,
            'from_status_name' => statuses[from_id]&.name,
            'to_status_id' => to_id,
            'to_status_name' => statuses[to_id]&.name,
            'from_status_date' => from_date,
            'to_status_date' => to_date,
            'tracked' => tracked,
            'day' => day,
            'is_holiday' => !holiday.nil?,
            'holiday_name' => holiday&.name,
            'has_schedule' => schedules.any?(&:match?),
            'minutes_counted' => tracked && !holiday ? counted_minutes(day, from_date, to_date, schedules) : 0
          }
        end
      end
    end

    private

    def candidate_levels
      sla_ids = SlaProjectTracker.where(project_id: @issue.project_id, tracker_id: @issue.tracker_id).pluck(:sla_id)
      SlaLevel.where(sla_id: sla_ids).includes(:sla_calendar).distinct.to_a
    end

    def first_matching_minute(calendar_id)
      created = issue_created_on
      last = created + SEARCH_WINDOW

      (created.to_date..last.to_date).filter_map do |day|
        next if excluded_holidays(calendar_id).key?(day)

        matching_schedules(calendar_id, day).filter_map do |schedule|
          starts_at = [created, at_time(day, schedule.start_time)].max
          ends_at = at_time(day, schedule.end_time)
          starts_at if starts_at <= ends_at && starts_at <= last
        end.min
      end.min
    end

    def matching_schedules(calendar_id, day)
      schedules = schedules_for_day(calendar_id, day)
      return schedules if matched_holidays(calendar_id).key?(day)

      schedules.select(&:match?)
    end

    def schedules_for_day(calendar_id, day)
      schedules_by_calendar[calendar_id].select { |schedule| schedule.dow == day.wday }
    end

    def counted_minutes(day, from_date, to_date, schedules)
      schedules.sum do |schedule|
        starts_at = [from_date, at_time(day, schedule.start_time)].max
        ends_at = [to_date - 1.minute, at_time(day, schedule.end_time)].min
        starts_at <= ends_at ? (((ends_at - starts_at) / 60).floor + 1) : 0
      end
    end

    def at_time(day, time)
      Time.zone.local(day.year, day.month, day.day, time.hour, time.min, time.sec)
    end

    def schedules_by_calendar
      @schedules_by_calendar ||= SlaSchedule.unscoped.order(:dow, :start_time).to_a.group_by(&:sla_calendar_id).tap do |hash|
        hash.default = []
      end
    end

    def excluded_holidays(calendar_id)
      calendar_holidays(false, calendar_id)
    end

    def matched_holidays(calendar_id)
      calendar_holidays(true, calendar_id)
    end

    def calendar_holidays(match, calendar_id)
      calendar_holidays_by_match.fetch(match).fetch(calendar_id, {})
    end

    def calendar_holidays_by_match
      @calendar_holidays_by_match ||= begin
        result = { true => {}, false => {} }
        SlaCalendarHoliday.unscoped.includes(:sla_holiday).find_each do |link|
          result[link.match][link.sla_calendar_id] ||= {}
          result[link.match][link.sla_calendar_id][link.sla_holiday.date] = link.sla_holiday
        end
        result
      end
    end

    def roll_statuses
      @roll_statuses ||= @connection.select_all(
        ActiveRecord::Base.sanitize_sql([<<~SQL.squish, @issue.id])
          SELECT from_status_id, from_status_date, to_status_id, to_status_date
          FROM sla_view_roll_statuses
          WHERE issue_id = ?
          ORDER BY from_status_date
        SQL
      ).to_a
    end

    def roll_status_ids
      roll_statuses.flat_map { |row| [row['from_status_id'], row['to_status_id']] }.compact.map(&:to_i).uniq
    end
  end
end
