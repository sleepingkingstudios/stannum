# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A Nil type constraint asserts that the object is nil.
  class NilType < Stannum::Constraints::Type
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.types.is_nil'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.types.is_not_nil'

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::NilClass, **options)
    end
  end
end
