# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'
require 'yaml'

require 'stannum/messages'

module Stannum::Messages
  # Loads and parses messages configuration files and merges configuration data.
  class DefaultLoader
    # @param file_paths [Array<String>] The directories from which to load the
    #   configuration files.
    # @param locale [String] The name of the locale for which to load
    #   configuration.
    def initialize(file_paths:, locale: 'en')
      @file_paths = file_paths
      @locale     = locale
    end

    # @return [Array<String>] the directories from which to load the
    #   configuration files.
    attr_reader :file_paths

    # @return [String] the name of the locale for which to load configuration.
    attr_reader :locale

    # Loads and parses each file, then deep merges the data from each file.
    #
    # The configuration file should be either a Ruby file or a YAML file, with
    # the filename of the format locale.extname, e.g. en.rb or en-gb.yml, and
    # located in one of the directories defined in #file_paths.
    #
    # The contents of each file should be either a Ruby Hash or a YAML document
    # containing an associative array, with a single key equal to the locale.
    # The value of the key must be a Hash or associative array, which contains
    # the scoped messages to load.
    #
    # Each file is read in order and parsed into a Hash. Each hash is then deep
    # merged in sequence, with nested hashes merged together instead of
    # overwritten.
    #
    # @return [Hash<Symbol, Object>] the merged configuration data.
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
