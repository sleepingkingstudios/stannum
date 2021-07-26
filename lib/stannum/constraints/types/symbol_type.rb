# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A Symbol type constraint asserts that the object is a Symbol.
  class SymbolType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Symbol, **options)
    end
  end
end
