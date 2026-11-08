# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require 'net/http'
require_relative '../application_sla_system_test_case'

class SlaIconUrlPrefixTest < ApplicationSlaSystemTestCase
  def setup
    super
    @original_app = Capybara.app
    @original_root = ActionController::Base.relative_url_root
    ActionController::Base.relative_url_root = '/redmine'
    clear_importmap_cache
    Capybara.app = Rack::URLMap.new('/redmine' => Rails.application)
  end

  def teardown
    super
  ensure
    Capybara.app = @original_app
    ActionController::Base.relative_url_root = @original_root
    clear_importmap_cache
    Setting.clear_cache
    User.current = nil
  end

  # Importmap caches resolved URLs across requests, including the mount prefix.
  # Its cache sweeper exists only when classes reload (development), so clear
  # the map directly: stale "/redmine" module URLs break JavaScript, such as
  # context menus, in the tests that run afterwards.
  def clear_importmap_cache
    return unless Rails.application.respond_to?(:importmap)

    Rails.application.importmap.send(:clear_cache)
  end

  test 'both sets and core action assets work under a real URL mount' do
    visit '/redmine/my/page'
    fill_in 'username', with: 'admin'
    fill_in 'password', with: 'admin'
    find('input[type=submit]').click
    assert_current_path '/redmine/my/page', ignore_query: true

    %w[flaticon tabler].each do |set_id|
      visit '/redmine/settings/plugin/redmine_sla'
      find('#tab-sla_display').click
      select RedmineSla::IconSet.fetch(set_id).name, from: 'settings_sla_icon_set'
      find('input[type=submit]').click
      assert_selector "#settings_sla_icon_set option[selected][value='#{set_id}']", visible: :all
      visit '/redmine/sla/slas'
      assert_selector '.title-sla-settings'
      assets = page.all('img.sla-icon-image, svg.sla-icon-svg use', visible: :all)
      assert_operator assets.length, :>, 3
      assets.each do |asset|
        source = asset.tag_name == 'img' ? asset[:src] : asset[:href]
        uri = URI.join(page.current_url, source)
        assert uri.path.start_with?('/redmine/'), source
        response = Net::HTTP.get_response(uri)
        assert_equal '200', response.code, source
        assert_includes response.body, "id=\"#{uri.fragment}\"" if uri.fragment
      end
      page.all('img.sla-icon-image').each do |image|
        assert image.evaluate_script('this.complete && this.naturalWidth > 0')
      end
    end
  end
end
