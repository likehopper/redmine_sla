# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require 'minitest/autorun'
require 'logger'
require 'uri'
require 'action_view'
require 'nokogiri'
require_relative '../../lib/redmine_sla/helpers/sla_icons_helper'
require_relative '../../lib/redmine_sla/patches/column_headers_patch'
require_relative '../../lib/redmine_sla/patches/admin_menu_icons_patch'
require_relative '../../lib/redmine_sla/patches/project_icons_patch'

class SlaIconsHelperTest < Minitest::Test
  def view(set)
    ActionView::Base.empty.tap do |helper|
      helper.extend RedmineSla::Helpers::SlaIconsHelper
      helper.instance_variable_set(:@sla_icon_set, RedmineSla::IconSet.fetch(set))
      helper.config = helper.config.inheritable_copy
      helper.config.relative_url_root = '/redmine'
      def helper.l(_key)
        'Icons created by'
      end
    end
  end

  def fragment(html)
    Nokogiri::HTML.fragment(html)
  end

  def test_png_heading_uses_24px_variant_and_dimensions
    html = fragment(view('flaticon').sla_icon('sla_level', context: :heading, plugin: 'redmine_sla'))
    image = html.at_css('img')
    assert_match(/sla_level_24\.png/, image['src'])
    assert_equal '24', image['width']
    assert_equal '24', image['height']
    assert_equal '', image['alt']
  end

  def test_tabler_works_without_native_sprite_helper
    helper = view('tabler')
    refute helper.respond_to?(:sprite_icon)
    html = fragment(helper.sla_icon('sla_level', plugin: 'redmine_sla', context: :heading))
    assert_equal '24', html.at_css('svg')['width']
    assert_equal 'currentColor', html.at_css('svg')['stroke']
    assert_equal '/redmine/plugin_assets/redmine_sla/images/icon_sets/tabler/icons.svg#icon--heart-handshake', html.at_css('use')['href']
  end

  def test_core_icons_have_a_redmine_5_fallback_for_both_sets
    %w[flaticon tabler].each do |set|
      html = fragment(view(set).sla_icon('edit', 'Edit', icon_only: true))
      assert_equal '/redmine/plugin_assets/redmine_sla/images/icon_sets/tabler/core-icons.svg#icon--edit', html.at_css('use')['href']
      assert_equal 'Edit', html.at_css('.sla-icon-label-hidden').text
    end
  end

  def test_core_icons_delegate_to_native_helper_when_available
    helper = view('tabler')
    def helper.sprite_icon(name, label, **options)
      [name, label, options]
    end
    assert_equal ['edit', 'Edit', {icon_only: true, size: 16}], helper.sla_icon('edit', 'Edit', icon_only: true)
    assert_includes helper.sla_icon('sla', plugin: 'redmine_sla'), 'icons.svg#icon--clock-record'
  end

  def test_label_is_escaped_and_hidden_without_losing_accessible_text
    html = fragment(view('tabler').sla_icon('sla', '<script>text</script>', plugin: 'redmine_sla', icon_only: true))
    assert_nil html.at_css('script')
    assert_equal '<script>text</script>', html.at_css('.sla-icon-label-hidden').text
  end

  def test_credit_contains_logo_and_both_links_only_when_enabled
    html = fragment(view('flaticon').sla_icon_credit)
    assert html.at_css('.redmine_sla_footer img')
    assert_equal ['https://www.flaticon.com/', 'https://www.flaticon.com/fr/auteurs/magnific', 'https://www.flaticon.com/'], html.css('a').map { |a| a['href'] }
    assert_includes html.text, 'Icons created by'
    assert_nil view('tabler').sla_icon_credit
  end

  def header_view(set)
    view(set).tap do |helper|
      def helper.column_header(_query, column, _options = {})
        content_tag(:th, link_to(column.caption, '/issues?sort=priority', title: column.caption), class: column.name)
      end
      helper.singleton_class.prepend RedmineSla::Patches::ColumnHeadersPatch
    end
  end

  def test_headers_distinguish_level_and_respect_for_both_sets_without_changing_captions
    column = Struct.new(:name, :caption)
    %w[flaticon tabler].each do |set|
      helper = header_view(set)
      level = column.new(:get_sla_level, 'SLA level')
      respect = column.new(:get_sla_respect_1, 'SLA respect Response')
      level_html = fragment(helper.column_header(nil, level))
      respect_html = fragment(helper.column_header(nil, respect))
      if set == 'flaticon'
        assert_match(/sla_level_16.png/, level_html.at_css('img')['src'])
        assert_match(/sla_status_16.png/, respect_html.at_css('img')['src'])
      else
        assert_match(/#icon--heart-handshake/, level_html.at_css('use')['href'])
        assert_match(/#icon--clipboard-check/, respect_html.at_css('use')['href'])
      end
      assert_equal '/issues?sort=priority', level_html.at_css('a')['href']
      assert_equal 'SLA level', level_html.at_css('a')['title']
      assert_equal 'SLA level', level.caption
      assert_equal 'SLA respect Response', respect.caption
    end
  end

  def test_unrelated_headers_are_unchanged
    helper = header_view('tabler')
    column = Struct.new(:name, :caption).new(:subject, 'Subject')
    html = fragment(helper.column_header(nil, column))
    assert_nil html.at_css('svg,img')
    assert_equal 'Subject', html.text
  end


  def decorated_view
    view('flaticon').tap do |helper|
      helper.instance_variable_set(:@sla_icon_set, RedmineSla::IconSet.new('atelier', {
        'name' => 'Atelier', 'format' => 'files', 'icons' => {'sla' => {16 => 'custom.png'}}, 'credit' => {'display' => false}
      }))
      def helper.render_single_menu_node(_item, caption, _url, _selected)
        _item.url[:controller] = '/slas' if _item.url[:controller] == 'slas'
        link_to(caption, '/sla/slas', class: 'icon redmine-sla')
      end
      def helper.link_to_project(_project, _options = {}, html_options = nil)
        link_to('Example', '/projects/example', html_options)
      end
      helper.singleton_class.prepend RedmineSla::Patches::AdminMenuIconsPatch
      helper.singleton_class.prepend RedmineSla::Patches::ProjectIconsPatch
    end
  end

  def test_administration_marker_uses_an_arbitrary_sets_sla_role
    helper = decorated_view
    item = Struct.new(:name, :url).new(:redmine_sla, {controller: 'slas'})
    html = fragment(helper.render_single_menu_node(item, 'SLA settings', item.url, false))
    assert_match(%r{icon_sets/atelier/custom.png}, html.at_css('img')['src'])
    assert_equal '/sla/slas', html.at_css('a')['href']
    assert_equal 'SLA settings', html.text.strip
  end

  def test_project_marker_uses_the_same_role_without_changing_the_link
    html = fragment(decorated_view.link_to_project(nil, {}, class: 'project has-sla'))
    assert_match(%r{icon_sets/atelier/custom.png}, html.at_css('.sla-project-marker img')['src'])
    assert_equal '/projects/example', html.at_css('a')['href']
    assert_equal 'Example', html.text
  end

  def test_unrelated_menu_and_project_links_are_not_decorated
    helper = decorated_view
    item = Struct.new(:name, :url).new(:redmine_sla, {controller: 'sla_caches'})
    assert_nil fragment(helper.render_single_menu_node(item, 'SLA', item.url, false)).at_css('img,svg')
    assert_nil fragment(helper.link_to_project(nil, {}, class: 'project')).at_css('.sla-project-marker')
  end


  def test_modern_redmine_resolves_plugin_sprites_through_the_asset_catalogue
    helper = view('tabler')
    def helper.sprite_icon(*)
      raise 'Plugin sprites keep the common renderer'
    end
    def helper.image_path(source, **)
      @requested_asset = source
      '/redmine/assets/plugin-sprite-digest.svg'
    end
    html = fragment(helper.sla_icon('sla', plugin: 'redmine_sla'))
    assert_equal 'plugin_assets/redmine_sla/icon_sets/tabler/icons.svg', helper.instance_variable_get(:@requested_asset)
    assert_equal '/redmine/assets/plugin-sprite-digest.svg#icon--clock-record', html.at_css('use')['href']
  end


  def test_time_term_remaining_and_respect_have_distinct_header_icons
    column = Struct.new(:name, :caption)
    %w[flaticon tabler].each do |set|
      helper = header_view(set)
      sources = %w[spent term remain respect].map do |kind|
        item = column.new("get_sla_#{kind}_1".to_sym, "#{kind} Response")
        html = fragment(helper.column_header(nil, item))
        assert_equal "#{kind} Response", html.text.strip
        assert_equal "#{kind} Response", item.caption
        icon = html.at_css('img,use')
        refute_nil icon
        icon['src'] || icon['href']
      end
      assert_equal 4, sources.uniq.length
    end
  end

end
