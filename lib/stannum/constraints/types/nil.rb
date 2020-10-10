# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A Nil type constraint asserts that the object is nil.
  class Nil < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::NilClass, **options)
    end
  end
end
