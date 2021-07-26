# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A FloatType constraint asserts that the object is a Float.
  class FloatType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Float, **options)
    end
  end
end
