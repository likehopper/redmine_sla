# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require 'net/http'
require_relative '../application_sla_system_test_case'
require_relative '../helpers/sla_documentation_helper'

class SlaIconSetsSystemTest < ApplicationSlaSystemTestCase
  include SlaDocumentationHelperTest

  def teardown
    User.current = nil
    super
  end

  %w[flaticon tabler].each do |set_id|
    test "#{set_id} renders its assets in native views and keeps selectors separate" do
      User.current = User.find(1)
      project = Project.find(1)
      log_user('admin', 'admin')

      visit '/settings/plugin/redmine_sla'
      find('#tab-sla_display').click
      select RedmineSla::IconSet.fetch(set_id).name, from: 'settings_sla_icon_set'
      find('input[type=submit]').click
      assert_selector "#settings_sla_icon_set option[selected][value='#{set_id}']", visible: :all
      Setting.clear_cache
      assert_equal set_id, Setting.plugin_redmine_sla['sla_icon_set']
      assert_no_selector '.redmine_sla_footer'
      find('#tab-sla_zone').click
      capture_icon_doc(set_id, 'locale')
      find('#tab-sla_display').click
      capture_icon_doc(set_id, 'display')

      visit '/admin'
      assert_set_asset('#admin-menu a.redmine-sla', set_id)
      assert_inline_menu_icon_alignment('#admin-menu a.redmine-sla')
      capture_icon_doc(set_id, 'administration')

      visit '/projects?set_filter=1&display_type=board'
      assert_set_asset("a.project[href='/projects/#{project.identifier}'] .sla-project-marker", set_id)
      capture_icon_doc(set_id, 'projects')

      visit '/sla/slas'
      assert_set_asset('.title-sla-settings', set_id)
      if set_id == 'flaticon'
        assert_selector '#sidebar #sla-icon-credit'
        assert_selector '#sla-icon-credit a[href="https://www.flaticon.com/"]'
      else
        assert_no_selector '#sla-icon-credit'
      end
      capture_icon_doc(set_id, 'list')

      names = %w[issue start_date updated_on sla_level get_sla_term_1 get_sla_spent_1 get_sla_remain_1 get_sla_respect_1]
      params = URI.encode_www_form([['set_filter', '1'], *names.map { |name| ['c[]', name] }])
      path = "/projects/#{project.identifier}/sla/caches"
      visit "#{path}?#{params}"
      %w[sla_level get_sla_term_1 get_sla_spent_1 get_sla_remain_1 get_sla_respect_1].each do |name|
        assert_set_asset("th.#{name}", set_id)
        assert_no_text_in_header(name, /[◇◎◷⌛☷]/)
      end
      sources = %w[term spent remain respect].map { |kind| icon_source(find("th.get_sla_#{kind}_1")) }
      assert_equal 4, sources.uniq.length
      find('#options legend').click
      markers = RedmineSla::IconSet.fetch(set_id).markers
      assert_selector '#selected_c option[value="sla_level"]', text: markers.fetch('sla_level')
      assert_selector '#selected_c option[value="get_sla_term_1"]', text: markers.fetch('sla_term')
      assert_selector '#selected_c option[value="get_sla_spent_1"]', text: markers.fetch('sla_spent')
      assert_selector '#selected_c option[value="get_sla_remain_1"]', text: markers.fetch('sla_remain')
      assert_selector '#selected_c option[value="get_sla_respect_1"]', text: markers.fetch('sla_respect')
      capture_icon_doc(set_id, 'columns')

      visit "/issues/#{project.issues.find(7).id}"
      assert_selector '.sla_display'
      capture_icon_doc(set_id, 'issue')
    end
  end

  private

  def icon_source(container)
    image = container.first('img', minimum: 0)
    image ? image[:src] : container.find('svg use', visible: :all)[:href]
  end

  def assert_set_asset(selector, set_id)
    source = icon_source(find(selector))
    assert_includes source, "/icon_sets/#{set_id}/"
    asset_url, fragment = source.split('#', 2)
    response = Net::HTTP.get_response(URI.join(page.current_url, asset_url))
    assert_equal '200', response.code, source
    assert_includes response.body, "id=\"#{fragment}\"" if fragment
  end

  def assert_no_text_in_header(name, pattern)
    refute_match pattern, find("th.#{name}").text
  end

  def assert_inline_menu_icon_alignment(selector)
    geometry = page.evaluate_script(<<~JS)
      (() => {
        const link = document.querySelector(#{selector.to_json});
        const icon = link.querySelector('.sla-icon-image, .sla-icon-svg');
        return {
          padding: parseFloat(getComputedStyle(link).paddingLeft),
          offset: icon.getBoundingClientRect().left - link.getBoundingClientRect().left
        };
      })()
    JS
    assert_in_delta 0, geometry.fetch('padding'), 0.5
    assert_in_delta 0, geometry.fetch('offset'), 0.5
  end

  def capture_icon_doc(set_id, name)
    return unless ENV['SLA_ICON_SCREENSHOTS'] == '1'

    @current_suite = 'icon-sets'
    take_doc_screenshot("#{set_id}-#{name}.png", viewport: {width: 1280, height: 800, scale: 1}, resize_to: '960x')
  end
end
