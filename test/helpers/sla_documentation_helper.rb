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
    suite = @current_suite || ENV['SUITE'] || 'default'
    path  = Rails.root.join('tmp', 'redmine_sla', 'screenshots', suite, name)
    FileUtils.mkdir_p(File.dirname(path))

    driver = page.driver.browser

    # 0) Hide Redmine's top "#header" bar (logo, quick-search, "Jump to a
    # project..." combobox, mobile flyout toggle) and the "#footer" bar
    # (Powered by Redmine...) -- documentation screenshots are meant to focus
    # on the plugin's own screens, not Redmine's chrome. Done before measuring
    # scrollHeight below so the page's real (shorter) height is used, instead
    # of leaving a blank gap where they used to be.
    page.execute_script(<<~JS)
      ['header', 'footer'].forEach(function(id) {
        var el = document.getElementById(id);
        if (el) el.style.display = 'none';
      });
    JS

    # 1) Force viewport
    #
    # For full-page captures, resize the emulated viewport to the page's
    # actual content height instead of relying on captureBeyondViewport.
    # Chrome's "capture beyond viewport" mode renders position: sticky/fixed
    # elements (e.g. Redmine's "Jump to a project..." top bar) at whatever
    # position they'd occupy in a virtual scroll -- which strands them
    # mid-page instead of pinned at the top. Sizing the viewport to fit the
    # whole page up front means nothing needs to scroll during capture, so
    # the sticky header renders correctly.
    height =
      if full_page
        # Measuring scrollHeight must happen at the SAME width that will be
        # used for capture -- content can wrap/reflow differently at a
        # different width, under- or over-estimating the real height. So
        # pin the width (an arbitrary height is fine here, it gets replaced
        # below) before measuring, then reset scroll to the top before the
        # real resize -- the browser keeps whatever scrollTop the page had
        # at the smaller viewport (e.g. after filling in a field further
        # down a long form), which would otherwise crop the top once the
        # viewport is enlarged to fit everything.
        driver.execute_cdp(
          'Emulation.setDeviceMetricsOverride',
          **{ width: viewport[:width], height: viewport[:height], deviceScaleFactor: viewport[:scale], mobile: false }
        )
        page.execute_script('window.scrollTo(0, 0)')
        content_height = page.evaluate_script('document.documentElement.scrollHeight').to_i
        [content_height, viewport[:height]].max
      else
        viewport[:height]
      end

    driver.execute_cdp(
      'Emulation.setDeviceMetricsOverride',
      **{
        width: viewport[:width],
        height: height,
        deviceScaleFactor: viewport[:scale],
        mobile: false
      }
    )
    page.execute_script('window.scrollTo(0, 0)') if full_page

    # 2) Capture (no need for captureBeyondViewport now that the emulated
    # viewport already matches the full page height)
    result = driver.execute_cdp(
      'Page.captureScreenshot',
      **{
        fromSurface: true,
        captureBeyondViewport: false
      }
    )

    File.binwrite(path, Base64.decode64(result['data']))

    # 3) Crop the surrounding whitespace down to the actual content (Redmine's
    # #content area reserves a fixed min-height to keep the footer pinned to
    # the bottom of the viewport, which otherwise leaves a large blank strip
    # below short forms), then resize + compress. A small fuzz tolerates the
    # anti-aliased pixels at the edge of the content box instead of leaving a
    # sliver of them behind; a fixed white border is added back afterwards so
    # the trimmed content isn't flush against the image edge.
    image = MiniMagick::Image.open(path.to_s)
    image.combine_options do |c|
      c.fuzz "3%"
      c.trim
    end
    image.combine_options do |c|
      c.bordercolor "white"
      c.border "12"
    end
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