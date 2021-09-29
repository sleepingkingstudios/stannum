# frozen_string_literal: true

require 'yaml'

require 'sleeping_king_studios/tools/toolbelt'

require 'stannum/messages'

module Stannum::Messages
  # Strategy to generate error messages from gem configuration.
  class DefaultStrategy
    # @param configuration [Hash{Symbol, Object}] The configured messages.
    # @param load_path [Array<String>] The filenames for the configuration
    #   file(s).
    def initialize(configuration: nil, load_path: nil)
      @load_path     = load_path.nil? ? [default_filename] : Array(load_path)
      @configuration = configuration
    end

    # @return [Array<String>] the filenames for the configuration file(s).
    attr_reader :load_path

    # @param error_type [String] The qualified path to the configured error
    #   message.
    # @param options [Hash] Additional properties to interpolate or to pass to
    #   the message proc.
    def call(error_type, **options)
      unless error_type.is_a?(String) || error_type.is_a?(Symbol)
        raise ArgumentError, 'error type must be a String or Symbol'
      end

      message = generate_message(error_type, options)

      interpolate_message(message, options)
    end

    # Reloads the configuration from the configured load_path.
    #
    # This can be useful when the load_path is updated after creating the
    # strategy, such as in an initializer for another gem.
    #
    # @return [DefaultStrategy] the strategy.
    def reload_configuration!
      @configuration = load_configuration

      self
    end

    private

    def configuration
      @configuration ||= load_configuration
    end

    def deep_merge(source, target)
      hsh = tools.hash_tools.deep_dup(source)

      target.each do |key, value|
        hsh[key] = value.is_a?(Hash) ? deep_merge(hsh[key] || {}, value) : value
      end

      hsh
    end

    def default_filename
      File.join(Stannum::Messages.locales_path, 'en.rb')
    end

    def generate_message(error_type, options)
      path = error_type.to_s.split('.').map(&:intern)
      path.unshift(:en)

      message = configuration.dig(*path)

      return message if message.is_a?(String)

      return message.call(error_type, options) if message.is_a?(Proc)

      return "no message defined for #{error_type.inspect}" if message.nil?

      "configuration is a namespace at #{error_type}"
    end

    def interpolate_message(message, options)
      message.gsub(/%{\w+}/) do |match|
        key = match[2..-2].intern

        options.fetch(key, match)
      end
    end

    def load_configuration
      load_path.reduce({}) do |config, filename|
        deep_merge(config, read_configuration(filename))
      end
    end

    def read_configuration(filename)
      case File.extname(filename)
      when '.rb'
        read_ruby_file(filename)
      when '.yml'
        read_yaml_file(filename)
      else
        raise "unable to load configuration file #{filename} with extension" \
              " #{File.extname(filename)}"
      end
    end

    def read_ruby_file(filename)
      eval(File.read(filename), binding, filename) # rubocop:disable Security/Eval
    end

    def read_yaml_file(filename)
      tools.hash_tools.convert_keys_to_symbols(
        YAML.safe_load(File.read(filename))
      )
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
