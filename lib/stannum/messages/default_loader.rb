# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'yaml'

require 'stannum/messages'

module Stannum::Messages
  # @todo
  class DefaultLoader
    # @todo
    def initialize(file_paths:, locale: 'en')
      @file_paths = file_paths
      @locale     = locale
    end

    # @todo
    attr_reader :file_paths

    # @todo
    attr_reader :locale

    # @todo
    def call
      file_paths.reduce({}) do |config, file_path|
        loaded = load_configuration_file(file_path)

        deep_update(config, loaded)
      end
    end
    alias load call

    private

    def deep_update(original, target)
      target.each do |key, value|
        if original[key].is_a?(Hash) && value.is_a?(Hash)
          deep_update(original[key], value)
        else
          original[key] = value
        end
      end

      original
    end

    def load_configuration_file(file_path)
      ruby_file = File.join(file_path, "#{locale}.rb")

      return read_ruby_file(ruby_file) if File.exist?(ruby_file)

      yaml_file = File.join(file_path, "#{locale}.yml")

      return read_yaml_file(yaml_file) if File.exist?(yaml_file)

      {}
    end

    def read_ruby_file(filename)
      ruby = File.read(filename)

      eval(ruby, binding, filename) # rubocop:disable Security/Eval
    end

    def read_yaml_file(filename)
      raw  = File.read(filename)
      yaml = YAML.safe_load(raw)

      tools.hsh.convert_keys_to_symbols(yaml)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
