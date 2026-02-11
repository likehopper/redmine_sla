# frozen_string_literal: true

# File: plugins/redmine_sla/test/documentation/modules/12_issues_module.rb
# Redmine SLA - Redmine's Plugin
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

module IssuesDocumentationTest
  # Create demo issues with past start/due dates and journal history (status transitions),
  # then visit each issue page to take documentation screenshots.
  #
  # Expected structure (in your master test initialize):
  # @issues = {
  #   'issue_key_1' => {
  #     'project'    => 'project-sla-tests-tma',
  #     'tracker'    => 'tracker_bug',
  #     'subject'    => 'SLA demo - past lifecycle (Bug)',
  #     'priority'   => 'Normal',
  #     'author'     => 'Redmine Reporter',
  #     'start_date' => Date.today - 10,
  #     'due_date'   => Date.today - 2,
  #     'history' => [
  #       { 'status' => 'New',         'at' => 10.days.ago, 'notes' => 'Ticket created' },
  #       { 'status' => 'Assigned',    'at' =>  9.days.ago, 'notes' => 'Assigned to resolver' },
  #       { 'status' => 'In Progress', 'at' =>  8.days.ago, 'notes' => 'Work started' },
  #       { 'status' => 'Resolved',    'at' =>  4.days.ago, 'notes' => 'Fix delivered' },
  #       { 'status' => 'Closed',      'at' =>  2.days.ago, 'notes' => 'Validated by requester' }
  #     ]
  #   }
  # }
  def test_12_issues
    id = 12

    log_user('admin', 'admin')

    return if @fixtures['issues'].nil? || @fixtures['issues'].empty?

    created_issues = []

    @fixtures['issues'].each.with_index(1) do |(issue_key, defn), idx|
      issue = create_issues_with_history!(defn)
      created_issues << [issue_key, issue, idx]
    end

    # Ensure SLA cache is updated after all issues/journals are created.
    # invoke_update_sla_task!

    # Visit each issue and take screenshots (issue page + SLA tab).
    created_issues.each do |issue_key, issue, idx|
      visit "/issues/#{issue.id}"
      take_doc_screenshot(format('%02d-01-%02d-%s-issue-show.png', id, idx, issue_key))
    end
  end

  private

  # Create an issue and replay its status transitions as journals in the past.
  def create_issues_with_history!(defn)
    project_identifier  = defn.fetch('project')
    tracker_name        = defn.fetch('tracker')
    subject             = defn.fetch('subject')
    issue_priority_name = defn['issue_priority_name']
    author_name         = defn['author']
    start_date          = defn['start_date']
    due_date            = defn['due_date']
    history             = Array(defn['history'])

    project = Project.find_by!(identifier: project_identifier)
    tracker = Tracker.find_by!(name: tracker_name)

    author = author_name ? find_user_by_display_name!(author_name) : User.current

    # Trouver l'ID de priorité à partir du nom
    priority_name = defn['issue_priority_name'] || 'Normal'
    priority = IssuePriority.find_by(name: priority_name) || IssuePriority.default
    # priority = priority_name ? IssuePriority.find_by!(name: priority_name) : IssuePriority.default

    # Determine initial status and creation time (best effort).
    first_step = history.first
    initial_status_name = first_step ? first_step['status'] : 'New'
    initial_status = IssueStatus.find_by!(name: initial_status_name)

    created_at =
      if first_step && first_step['at']
        first_step['at']
      elsif start_date.respond_to?(:to_time)
        start_date.to_time
      else
        Time.now
      end

    issue = nil

    travel_to(created_at) do
      issue = Issue.create!(
        project: project,
        tracker: tracker,
        subject: subject,
        author: author,
        priority: priority,
        start_date: start_date,
        due_date: due_date,
        status: initial_status
      )

      # 2. Assignation du Custom Field
      if defn['SlaPriorityScf'].present?
        cf_priority = IssueCustomField.find_by(name: 'SlaPriorityScf')
        if cf_priority
          # On assigne la valeur (le texte 'Minor', 'Major', etc.)
          issue.custom_field_values = { cf_priority.id.to_s => defn['SlaPriorityScf'] }
        end
      end      

    end

    current_status_id = issue.status_id
    lock_version = Issue.where(id: issue.id).pick(:lock_version).to_i

    # Apply remaining history steps (skip the first one if it matches initial status).
    history.each_with_index do |step, i|
      next if i == 0 # already set at creation time

      status_name = step.fetch('status')
      at          = step.fetch('at')
      notes       = step['notes']

      new_status = IssueStatus.find_by!(name: status_name)

      journal = Journal.create!(
        journalized: issue,
        user: author,
        notes: notes.to_s,
        created_on: at
      )

      JournalDetail.create!(
        journal: journal,
        property: 'attr',
        prop_key: 'status_id',
        old_value: current_status_id.to_s,
        value: new_status.id.to_s
      )

      lock_version += 1
      Issue.where(id: issue.id).update_all(
        status_id: new_status.id,
        updated_on: at,
        lock_version: lock_version
      )

      issue.reload
      current_status_id = new_status.id
    end

    issue
  end

  # Find user by a "Firstname Lastname" display name.
  def find_user_by_display_name!(display_name)
    parts = display_name.to_s.strip.split(' ', 2)
    firstname = parts[0]
    lastname  = parts[1] || ''

    user = User.find_by(firstname: firstname, lastname: lastname)
    return user if user

    # Fallback: try login or mail if the display name wasn't Firstname Lastname.
    user = User.find_by(login: display_name) || User.find_by(mail: display_name)
    return user if user

    raise ActiveRecord::RecordNotFound, "Unable to find user for display_name='#{display_name}'"
  end

  def invoke_update_sla_task!
    task_name = 'redmine:plugins:redmine_sla:update_sla'
    return unless defined?(Rake::Task)

    task = Rake::Task[task_name]
    task.reenable
    task.invoke
  rescue StandardError => e
    # Keep tests readable if task is unavailable in this context.
    warn "[redmine_sla] Unable to invoke #{task_name}: #{e.class}: #{e.message}"
  end
end