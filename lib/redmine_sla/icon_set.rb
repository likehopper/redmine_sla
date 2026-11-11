# frozen_string_literal: true
# SPDX-License-Identifier: GPL-2.0-or-later

require 'yaml'

module RedmineSla
  # Resolves trusted local manifests into assets, independently of HTML rendering.
  class IconSet
    ROOT = File.expand_path('../../assets/images/icon_sets', __dir__)
    DEFAULT = 'flaticon'
    FALLBACK = 'tabler'
    CONTEXT_SIZES = { menu: 16, list: 16, form: 20, column: 16, heading: 24 }.freeze

    Asset = Struct.new(:path, :symbol, keyword_init: true) do
      def initialize(path:, symbol: nil)
        super(path: path.dup.freeze, symbol: symbol&.dup&.freeze)
        freeze
      end

      def image?
        symbol.nil?
      end
    end

    def self.all
      @all ||= Dir[File.join(ROOT, '*', 'manifest.yml')].sort.each_with_object({}) do |path, sets|
        id = File.basename(File.dirname(path))
        begin
          set = new(id, YAML.safe_load(File.read(path)))
          sets[id] = set
        rescue Psych::Exception, ArgumentError, SystemCallError => error
          message = "Redmine SLA: ignoring icon manifest #{path}: #{error.message}"
          defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger ? Rails.logger.warn(message) : warn(message)
        end
      end.freeze
    end

    def self.fetch(id)
      all.fetch(id.to_s) do
        all[DEFAULT] || all[FALLBACK] || all.values.first || raise(KeyError, 'No valid SLA icon sets available')
      end
    end

    def self.core_icon(name)
      Asset.new(path: all.fetch(FALLBACK).asset_path('core-icons.svg'), symbol: name.to_s)
    end

    attr_reader :id

    def initialize(id, manifest)
      @id = id
      @manifest = manifest
      validate_manifest!
    end

    def name
      @manifest.fetch('name')
    end

    def roles
      @manifest.fetch('icons').keys
    end

    def markers
      fallback = self.class.all[FALLBACK]
      return @markers unless fallback && fallback != self

      fallback.markers.merge(@markers).freeze
    end

    def credit
      @manifest.fetch('credit', {})
    end

    def asset_path(file)
      "icon_sets/#{id}/#{file}"
    end

    def resolve(role, size:)
      entry = @manifest.fetch('icons')[role.to_s]
      case @manifest.fetch('format')
      when 'files'
        file = image_variant(entry, size)
        return Asset.new(path: asset_path(file)) if file
      when 'svg_sprite'
        if entry.is_a?(String)
          return Asset.new(path: asset_path(@manifest.fetch('file')), symbol: entry)
        end
      end

      # A missing fallback set must not resolve to the default set, which would recurse.
      fallback = self.class.all[FALLBACK]
      fallback.resolve(role, size: size) if fallback && fallback != self
    end

    private

    def validate_manifest!
      raise ArgumentError, 'expected a manifest mapping' unless @manifest.is_a?(Hash)
      raise ArgumentError, 'name must be a nonempty string' unless valid_string?(@manifest['name'])
      format = @manifest['format']
      raise ArgumentError, 'format must be files or svg_sprite' unless %w[files svg_sprite].include?(format)
      raise ArgumentError, 'icons must be a mapping' unless @manifest['icons'].is_a?(Hash)
      if format == 'svg_sprite'
        raise ArgumentError, 'file must be a nonempty string' unless valid_string?(@manifest['file'])
        raise ArgumentError, 'symbols must be nonempty strings' unless @manifest['icons'].values.all? { |value| valid_string?(value) }
      else
        @manifest['icons'] = @manifest['icons'].transform_values { |variants| normalize_variants(variants) }
      end
      credit = @manifest.fetch('credit', {})
      raise ArgumentError, 'credit must be a mapping' unless credit.is_a?(Hash)
      if credit.key?('display') && ![true, false].include?(credit['display'])
        raise ArgumentError, 'credit.display must be a boolean'
      end
      %w[text text_key logo].each do |key|
        raise ArgumentError, "credit.#{key} must be a nonempty string" if credit.key?(key) && !valid_string?(credit[key])
      end
      %w[author source].each do |key|
        next unless credit.key?(key)
        entry = credit[key]
        unless entry.is_a?(Hash) && %w[name url].all? { |field| valid_string?(entry[field]) }
          raise ArgumentError, "credit.#{key} must contain name and url"
        end
      end
      markers = @manifest.fetch('markers', {})
      unless markers.is_a?(Hash) && markers.all? { |role, marker| valid_string?(role) && valid_string?(marker) }
        raise ArgumentError, 'markers must map role names to nonempty strings'
      end
      @markers = markers.to_h { |role, marker| [role.dup.freeze, marker.dup.freeze] }.freeze
    end

    def valid_string?(value)
      value.is_a?(String) && !value.strip.empty?
    end

    def normalize_variants(variants)
      raise ArgumentError, 'image variants must be a nonempty mapping' unless variants.is_a?(Hash) && !variants.empty?

      variants.each_with_object({}) do |(size, file), result|
        unless (size.is_a?(Integer) || size.is_a?(String)) && size.to_s.match?(/\A[1-9]\d*\z/) && valid_string?(file)
          raise ArgumentError, 'image sizes must be positive integers and filenames nonempty strings'
        end
        size = size.to_i
        raise ArgumentError, "duplicate image size #{size}" if result.key?(size)
        result[size] = file
      end
    end

    # Prefer the smallest image that will not be enlarged.
    def image_variant(variants, size)
      return unless variants.is_a?(Hash) && !variants.empty?

      sizes = variants.keys.sort
      variants.fetch(sizes.find { |candidate| candidate >= size } || sizes.last)
    end
  end
end
