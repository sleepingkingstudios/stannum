# frozen_string_literal: true

require 'date'

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A DateType constraint asserts that the object is a Date.
  class DateType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Date, **options)
    end
  end
end
