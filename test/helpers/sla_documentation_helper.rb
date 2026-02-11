# frozen_string_literal: true

# File: redmine_sla/test/helpers/sla_documentation_helper.rb
# Redmine SLA - Redmine's Plugin 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module SlaDocumentationHelperTest

  # Normalize YAML payload:
  # - unwrap single root key (e.g. { "slas" => [...] } -> [...])
  # - keep multi-root hashes as-is
  def normalize_doc_yaml(raw)
    return nil if raw.nil?

    return raw unless raw.is_a?(Hash)

    return raw.values.first if raw.size == 1

    raw
  end


  # Strict accessor (optional but recommended)
  def doc_fixture(name)
    name = name.to_s
    fixtures = @fixtures || load_doc_fixtures

    return fixtures[name] if fixtures.key?(name)

    raise KeyError, "Fixture '#{name}' not found. Available: #{fixtures.keys.sort.join(', ')}"
  end  

  def take_doc_screenshot(
    name,
    viewport: { width: 800, height: 600, scale: 1 },
    resize_to: "640x",
    quality: 80,
    full_page: true
  )
    suite = ENV['SUITE'] || 'default'
    path  = Rails.root.join('tmp', 'redmine_sla', 'screenshots', suite, name)
    FileUtils.mkdir_p(File.dirname(path))

    driver = page.driver.browser

    # 1) Force viewport
    driver.execute_cdp(
      'Emulation.setDeviceMetricsOverride',
      **{
        width: viewport[:width],
        height: viewport[:height],
        deviceScaleFactor: viewport[:scale],
        mobile: false
      }
    )

    # 2) Capture
    result = driver.execute_cdp(
      'Page.captureScreenshot',
      **{
        fromSurface: true,
        captureBeyondViewport: full_page
      }
    )

    File.binwrite(path, Base64.decode64(result['data']))

    # 3) Resize + compress
    image = MiniMagick::Image.open(path.to_s)
    image.resize resize_to if resize_to
    image.quality quality.to_s
    image.write(path.to_s)

    puts "[Doc Screenshot] #{path}"

  ensure
    driver.execute_cdp('Emulation.clearDeviceMetricsOverride') rescue nil
  end

  def create_issues_with_history!(defn)
    project_identifier = defn.fetch('project')
    tracker_name       = defn.fetch('tracker')
    subject            = defn.fetch('subject')
    priority_name      = defn['priority']
    author_name        = defn['author']
    start_date         = defn['start_date']
    due_date           = defn['due_date']
    history            = Array(defn['history'])

    raise ArgumentError, 'history is required' if history.empty?

    project = Project.find_by!(identifier: project_identifier)
    tracker = Tracker.find_by!(name: tracker_name)

    author =
      if author_name
        find_user_by_display_name!(author_name)
      else
        User.current
      end

    priority =
      if priority_name
        IssuePriority.find_by!(name: priority_name)
      else
        IssuePriority.default
      end

    first_step = history.first
    initial_status = IssueStatus.find_by!(name: first_step.fetch('status'))
    created_at = first_step.fetch('at')

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

    # Force the issue timestamps deterministically (no time travel needed)
    Issue.where(id: issue.id).update_all(created_on: created_at, updated_on: created_at, lock_version: 0)
    issue.reload

    current_status_id = issue.status_id
    lock_version      = issue.lock_version.to_i

    # Replay status transitions by creating journals + details manually
    history.drop(1).each do |step|
      status_name = step.fetch('status')
      at          = step.fetch('at')
      notes       = step['notes'].to_s

      new_status = IssueStatus.find_by!(name: status_name)

      # Create journal entry at the desired time
      journal = Journal.create!(
        journalized: issue,
        user: author,
        notes: notes,
        created_on: at
      )

      # Add a status change detail so UI shows the transition
      JournalDetail.create!(
        journal: journal,
        property: 'attr',
        prop_key: 'status_id',
        old_value: current_status_id.to_s,
        value: new_status.id.to_s
      )

      # Update issue without optimistic locking issues
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

end