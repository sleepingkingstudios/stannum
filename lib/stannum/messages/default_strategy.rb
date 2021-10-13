# frozen_string_literal: true

require 'yaml'

require 'sleeping_king_studios/tools/toolbelt'

require 'stannum/messages'

module Stannum::Messages
  # Strategy to generate error messages from gem configuration.
  class DefaultStrategy
    # The default directories from which to load configured error messages.
    DEFAULT_LOAD_PATHS = [Stannum::Messages.locales_path].freeze

    # @return [Array<String>] The directories from which to load configured
    #   error messages.
    def self.load_paths
      @load_paths ||= DEFAULT_LOAD_PATHS.dup
    end

    # @param configuration [Hash{Symbol, Object}] The configured messages.
    # @param load_paths [Array<String>] The directories from which to load
    #   configured error messages.
    def initialize(configuration: nil, load_paths: nil)
      @load_paths    = Array(load_paths) unless load_paths.nil?
      @configuration = configuration
    end

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

    # @return [Array<String>] The directories from which to load configured
    #   error messages.
    def load_paths
      @load_paths || self.class.load_paths
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
      Stannum::Messages::DefaultLoader
        .new(
          file_paths: load_paths,
          locale:     'en'
        )
        .call
    end
  end
end
