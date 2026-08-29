# frozen_string_literal: true

# File: redmine_sla/test/documentation/modules/10_sla_level_terms_module.rb
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

module SlaLevelTermsDocumentationTest

  def test_10_sla_level_term
    id = 10

    sla_level_terms = fixture!('sla_level_terms')

    log_user('admin', 'admin') if sla_level_terms.any?

    # Resolve names -> records
    sla_types_by_name = SlaType.all.index_by(&:name)

    sla_level_terms.each.with_index(1) do |(_key, sla_level_term), idx|

      # Resolve names -> records
      sla_level_name = sla_level_term.fetch('sla_level')
      sla_type_name  = sla_level_term.fetch('sla_type')
      sla_priorities = sla_level_term.fetch('sla_priority')

      # Resolve names -> records
      sla_level = SlaLevel.find_by!(name: sla_level_name)
      sla_type  = sla_types_by_name.fetch(sla_type_name)

      # Priority names must be resolved against the SLA level's OWN priority
      # source: native IssuePriority, or -- when the level has a custom_field_id
      # configured -- that custom field's own enumeration values. This is the
      # exact same abstraction the real "SLA Terms" form uses (SlaPriority.create,
      # see app/views/sla_levels/sla_terms.html.erb), so the ids submitted here
      # always land in the id-space SlaLevelTerm#before_save expects.
      #
      # Using IssuePriority unconditionally here was a real bug: when a level
      # uses a custom field, IssuePriority ids get silently reinterpreted as
      # custom_field_enumeration_id by the model callback. It only appeared to
      # work when both id sequences coincidentally aligned (e.g. a fresh DB
      # where the custom field happens to be the first enumeration-type field
      # created) -- in the general case it raises a foreign key violation.
      priorities_by_name = SlaPriority.create(sla_level.custom_field_id).all.index_by(&:name)

      # Open and fill out the form
      visit "/sla/levels/#{sla_level.id}/sla_terms"

      # A type added after this level already has at least one other term is
      # hidden by default (see sla_terms.html.erb) -- reveal it first, same
      # as a real admin completing a level would need to.
      show_hidden_types_link = l('sla_label.sla_level_term.show_hidden_types')
      click_link show_hidden_types_link if page.has_link?(show_hidden_types_link)

      sla_priorities.each do |priority_name, value|

        # Resolve names -> records
        priority = priorities_by_name.fetch(priority_name) {
          raise KeyError, "Priority/value '#{priority_name}' not found for SLA level " \
            "'#{sla_level_name}' (available: #{priorities_by_name.keys.sort.join(', ')})"
        }

        field_id = "sla_level_sla_level_terms_attributes_#{sla_type.id}_#{priority.id}_term"
        fill_in field_id, with: value
      end

      # Take the photo and submit the form
      take_doc_screenshot(format('%02d-01-%02d-01-sla_level_term-new.png', id, idx))
      click_button l('sla_label.sla_level_term.save')
      assert_current_path sla_levels_path

      # Validation and screenshot
      assert_text(l('sla_label.sla_level.notice_successful_update', id: "##{sla_level.id}"))
      take_doc_screenshot(format("%02d-01-%02d-02-sla_level_term-created.png", id, idx))

    end

    # take_doc_screenshot(format("%02d-02-sla_level_term-list.png", id)) if sla_level_terms.any?

  end
end