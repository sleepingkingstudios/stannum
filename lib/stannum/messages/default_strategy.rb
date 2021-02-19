# frozen_string_literal: true

require 'stannum/messages'

module Stannum::Messages
  # Strategy to generate error messages from gem configuration.
  class DefaultStrategy
    # @param configuration [Hash{Symbol, Object}] the configured messages.
    # @param filename [String] the filename for the configuration file.
    def initialize(configuration: nil, filename: nil)
      @filename      = filename || default_filename
      @configuration = configuration || load_configuration
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

    private

    attr_reader :configuration

    attr_reader :filename

    def default_filename
      File.join(Stannum::Messages.locales_path, 'en.rb')
    end

    def generate_message(error_type, options)
      path = error_type.to_s.split('.').map(&:intern)
      path.unshift(:en)

      message = configuration.dig(*path)

      return message if message.is_a?(String)

      return message.call(error_type, options) if message.is_a?(Proc)

      return "no message defined for #{error_type}" if message.nil?

      "configuration is a namespace at #{error_type}"
    end

    def interpolate_message(message, options)
      message.gsub(/%{\w+}/) do |match|
        key = match[2..-2].intern

        options.fetch(key, match)
      end
    end

    def load_configuration
      eval(IO.read(filename), binding, filename) # rubocop:disable Security/Eval
    end
  end
end
