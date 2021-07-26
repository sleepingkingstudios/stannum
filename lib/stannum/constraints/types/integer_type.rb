# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # An IntegerType constraint asserts that the object is an Integer.
  class IntegerType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Integer, **options)
    end
  end
end
