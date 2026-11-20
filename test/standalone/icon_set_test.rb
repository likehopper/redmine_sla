# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../lib/redmine_sla/icon_set'

class IconSetTest < Minitest::Test
  ASSETS = File.expand_path('../../assets/images', __dir__)

  def test_unknown_or_missing_setting_falls_back_without_resolving_a_path
    [nil, '', '../../etc/passwd', 'missing'].each do |id|
      assert_same RedmineSla::IconSet.fetch('flaticon'), RedmineSla::IconSet.fetch(id)
    end
  end

  def test_missing_fallback_set_neither_recurses_nor_borrows_core_icons
    sets = RedmineSla::IconSet.all
    RedmineSla::IconSet.instance_variable_set(:@all, sets.slice('flaticon').freeze)
    assert_nil RedmineSla::IconSet.fetch('flaticon').resolve('unknown', size: 16)
    assert_raises(KeyError) { RedmineSla::IconSet.core_icon('edit') }
  ensure
    RedmineSla::IconSet.instance_variable_set(:@all, sets)
  end

  def test_credit_is_selected_with_the_set
    assert_equal true, RedmineSla::IconSet.fetch('flaticon').credit['display']
    assert_equal false, RedmineSla::IconSet.fetch('tabler').credit['display']
  end

  def test_markers_are_selected_with_the_set
    assert_equal({'sla_level' => '◇', 'sla_spent' => '🚀', 'sla_term' => '🏁',
                  'sla_remain' => '🏃', 'sla_respect' => '⏰'},
                 RedmineSla::IconSet.fetch('flaticon').markers)
    assert_equal({'sla_level' => '◇', 'sla_spent' => '◎', 'sla_term' => '◷',
                  'sla_remain' => "\u231B\uFE0E", 'sla_respect' => '☷'},
                 RedmineSla::IconSet.fetch('tabler').markers)
  end

  def test_admin_menu_alignment_does_not_depend_on_has_selector_support
    css = File.read(File.expand_path('../../assets/stylesheets/redmine_sla.css', __dir__)).gsub(%r{/\*.*?\*/}m, '')
    rule = css.scan(/([^{}]+)\{([^{}]*)\}/).find { |selectors, _| selectors.strip == '#admin-menu a.redmine-sla' }

    refute_nil rule
    assert_match(/padding-left:\s*0/, rule.last)
  end

  def test_custom_sets_inherit_missing_markers_from_the_fallback
    set = RedmineSla::IconSet.new('custom', {
      'name' => 'Custom', 'format' => 'files', 'icons' => {}, 'markers' => {'sla_spent' => '$'}
    })
    assert_equal '$', set.markers['sla_spent']
    assert_equal '◷', set.markers['sla_term']
  end

  def test_missing_default_set_keeps_valid_sets_available_for_selection_and_fallback
    sets = RedmineSla::IconSet.all
    tabler = sets.fetch('tabler')
    RedmineSla::IconSet.instance_variable_set(:@all, {'tabler' => tabler}.freeze)

    assert_same tabler, RedmineSla::IconSet.fetch('tabler')
    [nil, '', 'flaticon', 'missing'].each do |id|
      assert_same tabler, RedmineSla::IconSet.fetch(id)
    end
  ensure
    RedmineSla::IconSet.instance_variable_set(:@all, sets)
  end

  def test_missing_bundled_sets_falls_back_to_a_valid_custom_set
    sets = RedmineSla::IconSet.all
    custom = RedmineSla::IconSet.new('custom', {'name' => 'Custom', 'format' => 'files', 'icons' => {}})
    RedmineSla::IconSet.instance_variable_set(:@all, {'custom' => custom}.freeze)

    assert_same custom, RedmineSla::IconSet.fetch('custom')
    assert_same custom, RedmineSla::IconSet.fetch(nil)
  ensure
    RedmineSla::IconSet.instance_variable_set(:@all, sets)
  end

  def test_empty_catalogue_reports_that_no_valid_sets_are_available
    sets = RedmineSla::IconSet.all
    RedmineSla::IconSet.instance_variable_set(:@all, {}.freeze)

    error = assert_raises(KeyError) { RedmineSla::IconSet.fetch(nil) }
    assert_equal 'No valid SLA icon sets available', error.message
  ensure
    RedmineSla::IconSet.instance_variable_set(:@all, sets)
  end

  def test_image_selection_avoids_upscaling_when_possible
    set = RedmineSla::IconSet.fetch('flaticon')
    assert_equal 'icon_sets/flaticon/sla_16.png', set.resolve('sla', size: 16).path
    assert_equal 'icon_sets/flaticon/sla_24.png', set.resolve('sla', size: 20).path
    assert_equal 'icon_sets/flaticon/sla_32.png', set.resolve('sla', size: 32).path
    assert_equal 'icon_sets/flaticon/sla_64.png', set.resolve('sla', size: 100).path
    assert_nil set.resolve('unknown', size: 16)
    refute RedmineSla::IconSet.fetch('tabler').resolve('sla', size: 16).image?
  end

  def test_both_sets_cover_the_same_roles
    assert_equal RedmineSla::IconSet.fetch('flaticon').roles.sort,
                 RedmineSla::IconSet.fetch('tabler').roles.sort
  end

  def test_all_raster_variants_and_credit_logo_exist
    set = RedmineSla::IconSet.fetch('flaticon')
    YAML.safe_load(File.read(File.join(RedmineSla::IconSet::ROOT, set.id, 'manifest.yml'))).fetch('icons').each_value do |variants|
      refute_empty variants
      variants.each_value { |file| assert File.file?(File.join(ASSETS, set.asset_path(file))), file }
    end
    assert File.file?(File.join(ASSETS, set.asset_path(set.credit.fetch('logo'))))
  end

  def test_all_tabler_symbols_exist_in_the_sprite
    set = RedmineSla::IconSet.fetch('tabler')
    set.roles.each do |role|
      asset = set.resolve(role, size: 16)
      svg = File.read(File.join(ASSETS, asset.path))
      assert_includes svg, "id=\"icon--#{asset.symbol}\""
    end
  end

  def test_redmine_5_fallback_contains_all_core_icons_used_by_templates
    names = Dir[File.expand_path('../../app/views/**/*.erb', __dir__)].flat_map do |path|
      File.read(path).scan(/sla_icon\(['"]([^'"]+)/).flatten
    end
    names += %w[checked close]
    plugin_names = RedmineSla::IconSet.fetch('tabler').roles
    svg = File.read(File.join(ASSETS, 'icon_sets/tabler/core-icons.svg'))
    (names.uniq - plugin_names).each { |name| assert_includes svg, "id=\"icon--#{name}\"" }
  end

  def test_resolution_returns_an_immutable_asset_without_rendering_html
    asset = RedmineSla::IconSet.fetch('tabler').resolve('sla_level', size: 24)
    assert_equal 'icon_sets/tabler/icons.svg', asset.path
    assert_equal 'heart-handshake', asset.symbol
    assert asset.frozen?
    assert asset.path.frozen?
    assert asset.symbol.frozen?
    refute asset.image?
    refute RedmineSla::IconSet.fetch('tabler').respond_to?(:manifest)
  end

  def test_missing_roles_in_custom_file_and_sprite_sets_use_the_bundled_fallback
    ['files', 'svg_sprite'].each do |format|
      set = RedmineSla::IconSet.new('custom', {'name' => 'Custom', 'format' => format, 'file' => 'custom.svg', 'icons' => {}})
      asset = set.resolve('sla_level', size: 16)
      assert_equal 'icon_sets/tabler/icons.svg', asset.path
      assert_equal 'heart-handshake', asset.symbol
      assert_nil set.resolve('unknown', size: 16)
    end
  end

  def test_custom_sprite_resolution_preserves_its_own_file_and_symbol
    set = RedmineSla::IconSet.new('custom', {'name' => 'Custom', 'format' => 'svg_sprite', 'file' => 'custom.svg', 'icons' => {'sla' => 'custom-clock'}})
    asset = set.resolve('sla', size: 16)
    assert_equal 'icon_sets/custom/custom.svg', asset.path
    assert_equal 'custom-clock', asset.symbol
  end

  def test_core_icons_resolve_independently_of_the_selected_set
    asset = RedmineSla::IconSet.core_icon('edit')
    assert_equal 'icon_sets/tabler/core-icons.svg', asset.path
    assert_equal 'edit', asset.symbol
  end

  def test_catalogue_ignores_invalid_manifests_and_normalizes_quoted_sizes
    Dir.mktmpdir('sla-manifests') do |directory|
      manifests = {
        'valid' => {'name' => 'Custom', 'format' => 'files', 'icons' => {'sla' => {'16' => 'small.png', 32 => 'large.png'}}},
        'bad-size' => {'name' => 'Bad', 'format' => 'files', 'icons' => {'sla' => {'large' => 'bad.png'}}},
        'zero-size' => {'name' => 'Bad', 'format' => 'files', 'icons' => {'sla' => {0 => 'bad.png'}}},
        'negative-size' => {'name' => 'Bad', 'format' => 'files', 'icons' => {'sla' => {-16 => 'bad.png'}}},
        'float-size' => {'name' => 'Bad', 'format' => 'files', 'icons' => {'sla' => {16.5 => 'bad.png'}}},
        'duplicate-size' => {'name' => 'Bad', 'format' => 'files', 'icons' => {'sla' => {16 => 'a.png', '16' => 'b.png'}}},
        'bad-credit' => {'name' => 'Bad', 'format' => 'files', 'icons' => {}, 'credit' => {'author' => {}}},
        'bad-markers' => {'name' => 'Bad', 'format' => 'files', 'icons' => {}, 'markers' => {'sla' => ''}},
        'empty' => nil,
        'bad-format' => {'name' => 'Bad', 'format' => 'unknown', 'icons' => {}}
      }
      manifests.each do |id, manifest|
        folder = File.join(directory, id)
        Dir.mkdir(folder)
        File.join(folder, 'manifest.yml').tap { |path| File.write(path, YAML.dump(manifest)) }
      end
      Dir.mkdir(File.join(directory, 'broken'))
      broken = File.join(directory, 'broken', 'manifest.yml')
      File.write(broken, 'name: [')
      previous = RedmineSla::IconSet.instance_variable_get(:@all)
      RedmineSla::IconSet.remove_instance_variable(:@all) if previous
      original_root = RedmineSla::IconSet::ROOT
      RedmineSla::IconSet.send(:remove_const, :ROOT)
      RedmineSla::IconSet.const_set(:ROOT, directory)
      _stdout, stderr = capture_io do
        sets = RedmineSla::IconSet.all
        assert_equal ['valid'], sets.keys
        assert_equal 'icon_sets/valid/small.png', sets['valid'].resolve('sla', size: 16).path
        assert_equal 'icon_sets/valid/large.png', sets['valid'].resolve('sla', size: 20).path
      end
      assert_equal 10, stderr.scan('ignoring icon manifest').length
    ensure
      RedmineSla::IconSet.instance_variable_set(:@all, previous)
      if original_root
        RedmineSla::IconSet.send(:remove_const, :ROOT)
        RedmineSla::IconSet.const_set(:ROOT, original_root)
      end
    end
  end

end
