# frozen_string_literal: true

require 'bigdecimal'

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A BigDecimal type constraint asserts that the object is a BigDecimal.
  class BigDecimalType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::BigDecimal, **options)
    end
  end
end
