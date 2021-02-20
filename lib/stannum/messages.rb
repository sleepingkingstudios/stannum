# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for generating messages for Stannum::Errors.
  module Messages
    autoload :DefaultStrategy, 'stannum/messages/default_strategy'

    # @return [String] the absolute path to the configured locales.
    def self.locales_path
      File.join(Stannum.gem_path, 'config', 'locales')
    end

    # @return [#call] the configured strategy for generating messages.
    def self.strategy
      @strategy ||= DefaultStrategy.new
    end

    # @param strategy [#call] The strategy to use to generate error messages.
    def self.strategy=(strategy)
      @strategy = strategy
    end
  end
end
