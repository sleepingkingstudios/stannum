# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # Asserts that the object is a Hash with String keys.
  class HashWithStringKeys < Stannum::Constraints::Types::HashType
    # @param value_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each value in the Hash against
    #   the expected type and will fail if any values do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(value_type: nil, **options)
      super(
        key_type:   Stannum::Constraints::Types::StringType.new,
        value_type: coerce_value_type(value_type),
        **options
      )
    end
  end
end
