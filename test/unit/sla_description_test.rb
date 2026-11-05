# frozen_string_literal: true
# File: redmine_sla/test/unit/sla_description_test.rb
# SPDX-License-Identifier: GPL-2.0-or-later

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

require File.expand_path('../../application_sla_units_test_case', __FILE__)

# Optional description of the named SLA objects and the tooltip built from it.
class SlaDescriptionTest < ApplicationSlaUnitsTestCase

  # Minimal view context exposing the rendering helper.
  class TooltipView
    include ERB::Util
    include RedmineSla::Helpers::SlaRenderingHelper
  end

  DESCRIBED_CLASSES = [Sla, SlaType, SlaCalendar, SlaLevel].freeze

  def setup
    @view = TooltipView.new
  end

  # --- Model ---

  test "description is an optional safe attribute of the named SLA objects" do
    DESCRIBED_CLASSES.each do |klass|
      assert_includes klass.column_names, 'description', klass.name
      assert_includes klass.new.safe_attribute_names(User.find_by(login: 'admin')), 'description', klass.name
    end
  end

  test "description is saved and stays optional" do
    sla_type = SlaType.new(name: "DESCRIPTION_TEST", position: 99)
    assert sla_type.save, sla_type.errors.full_messages.join(', ')

    sla_type.update!(description: "Time until the first answer.")
    assert_equal "Time until the first answer.", sla_type.reload.description
  end

  # --- Tooltip ---

  test "tooltip falls back when there is no description" do
    sla_type = SlaType.new(name: "X")
    assert_nil @view.sla_description_tooltip(sla_type)
    assert_equal "Show", @view.sla_description_tooltip(sla_type, "Show")

    sla_type.description = "  \n "
    assert_equal "Show", @view.sla_description_tooltip(sla_type, "Show")
    assert_nil @view.sla_description_tooltip(nil)
  end

  test "tooltip strips CommonMark markup" do
    with_settings :text_formatting => 'common_mark' do
      sla = Sla.new(description: "**Bug** requests\n\n* first & second")
      assert_equal "Bug requests first & second", @view.sla_description_tooltip(sla)
    end
  end

  test "tooltip strips Textile markup" do
    with_settings :text_formatting => 'textile' do
      sla = Sla.new(description: "*Bug* requests\n\n* first & second")
      assert_equal "Bug requests first & second", @view.sla_description_tooltip(sla)
    end
  end

  test "tooltip is truncated" do
    sla = Sla.new(description: "word " * 100)
    tooltip = @view.sla_description_tooltip(sla)
    assert_equal RedmineSla::Helpers::SlaRenderingHelper::SLA_DESCRIPTION_TOOLTIP_LENGTH, tooltip.length
    assert tooltip.end_with?("...")
  end

  test "name with tooltip only wraps described objects" do
    assert_equal "GTR", @view.sla_name_with_tooltip(SlaType.new(name: "GTR"))

    html = @view.sla_name_with_tooltip(SlaType.new(name: "GTI", description: "Answer & well"))
    assert_equal '<span title="Answer &amp; well">GTI</span>', html
  end

  test "identical descriptions share formatting across records in one view" do
    with_settings :text_formatting => 'common_mark' do
      Redmine::WikiFormatting.expects(:to_html).with('common_mark', '**Shared**').once.returns('<p>Shared</p>')
      assert_equal 'Shared', @view.sla_description_tooltip(Sla.new(description: '**Shared**'))
      assert_equal 'Shared', @view.sla_description_tooltip(SlaLevel.new(description: '**Shared**'))
    end
  end

  test "tooltip cache follows changed text and formatting" do
    sla = Sla.new(description: '*First*')
    with_settings :text_formatting => 'textile' do
      assert_equal 'First', @view.sla_description_tooltip(sla)
      sla.description.replace('*Second*')
      assert_equal 'Second', @view.sla_description_tooltip(sla)
    end
    with_settings :text_formatting => 'common_mark' do
      Redmine::WikiFormatting.expects(:to_html).with('common_mark', '*Second*').once.returns('<p>Second</p>')
      assert_equal 'Second', @view.sla_description_tooltip(sla)
    end
  end

  test "cached empty formatted descriptions preserve each caller fallback" do
    sla = Sla.new(description: '![image](https://example.org/image.png)')
    with_settings :text_formatting => 'common_mark' do
      assert_nil @view.sla_description_tooltip(sla)
      assert_equal 'Show', @view.sla_description_tooltip(sla, 'Show')
      assert_equal 'Edit', @view.sla_description_tooltip(sla, 'Edit')
    end
  end

  test "tooltip formatting cache is limited to each view context" do
    with_settings :text_formatting => 'common_mark' do
      Redmine::WikiFormatting.expects(:to_html).with('common_mark', '**Shared**').twice.returns('<p>Shared</p>')
      sla = Sla.new(description: '**Shared**')
      assert_equal 'Shared', @view.sla_description_tooltip(sla)
      assert_equal 'Shared', TooltipView.new.sla_description_tooltip(sla)
    end
  end

  test "tooltip and name escape HTML attribute delimiters" do
    sla = Sla.new(name: '<script>alert(1)</script>', description: '&quot; onmouseover=&quot;alert(1)')
    fragment = Nokogiri::HTML.fragment(@view.sla_name_with_tooltip(sla))
    assert_empty fragment.css('script, [onmouseover]')
    assert_equal sla.name, fragment.at_css('span').text
    assert_includes fragment.at_css('span')['title'], 'onmouseover='
  end

  [SlaCalendar, SlaLevel].each do |model_class|
    test "#{model_class.name} description changes preserve calculation caches" do
      record = model_class.find(1)
      cache_ids = SlaCache.unscoped.order(:id).pluck(:id)
      spent_ids = SlaCacheSpent.unscoped.order(:id).pluck(:id)
      assert_not_empty cache_ids
      assert_not_empty spent_ids
      record.update!(description: 'Presentation only')
      assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
      assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
      record.update!(description: '')
      assert_equal cache_ids, SlaCache.unscoped.order(:id).pluck(:id)
      assert_equal spent_ids, SlaCacheSpent.unscoped.order(:id).pluck(:id)
    end

    test "#{model_class.name} name and description changes #{model_class == SlaCalendar ? 'preserve' : 'invalidate'} caches" do
      record = model_class.find(1)
      affected_level_ids = model_class == SlaLevel ? [record.id] : SlaLevel.where(sla_calendar_id: record.id).pluck(:id)
      affected_caches = SlaCache.unscoped.where(sla_level_id: affected_level_ids)
      assert_not_empty affected_caches
      record.update!(name: "#{record.name} renamed", description: 'Changed together')
      if model_class == SlaCalendar
        assert_not_empty affected_caches.reload
      else
        assert_empty affected_caches.reload
      end
    end
  end

  test "calendar description with nested schedule changes still invalidates caches" do
    calendar = SlaCalendar.find(1)
    schedule = calendar.sla_schedules.first
    affected_level_ids = SlaLevel.where(sla_calendar_id: calendar.id).pluck(:id)
    affected_caches = SlaCache.unscoped.where(sla_level_id: affected_level_ids)
    assert_not_empty affected_caches
    calendar.update!(description: 'Changed with schedule',
      sla_schedules_attributes: [{id: schedule.id, match: schedule.match ? '0' : '1'}])
    assert_empty affected_caches.reload
  end

end
