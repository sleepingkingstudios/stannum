# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A String type constraint asserts that the object is a String.
  class String < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::String, **options)
    end
  end
end
