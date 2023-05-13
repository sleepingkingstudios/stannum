# frozen_string_literal: true

require 'stannum/entities'
require 'stannum/schema'

module Stannum::Entities
  # Methods for defining and accessing entity associations.
  module Associations
    # @param properties [Hash] the properties used to initialize the entity.
    def initialize(**properties)
      @associations = {}

      super
    end

    # Retrieves the association value for the requested key.
    #
    # If the :safe flag is set, will verify that the association name is valid
    # (a non-empty String or Symbol) and that there is a defined association by
    # that name. By default, :safe is set to true.
    #
    # @param key [String, Symbol] the key of the association to retrieve.
    # @param safe [Boolean] if true, validates the association key.
    #
    # @return [Object] the value of the requested association.
    #
    # @api private
    def read_association(key, safe: true) # rubocop:disable Lint/UnusedMethodArgument
      @associations[key.to_s]
    end

    # Assigns the association value for the requested key.
    #
    # If the :safe flag is set, will verify that the association name is valid
    # (a non-empty String or Symbol) and that there is a defined association by
    # that name. By default, :safe is set to true.
    #
    # @param key [String, Symbol] the key of the association to assign.
    # @oaram value [Object] the value to assign.
    # @param safe [Boolean] if true, validates the association key.
    #
    # @return [Object] the assigned value.
    #
    # @api private
    def write_association(key, value, safe: true) # rubocop:disable Lint/UnusedMethodArgument
      @associations[key.to_s] = value
    end
  end
end
