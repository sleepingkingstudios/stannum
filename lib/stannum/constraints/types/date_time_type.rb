# frozen_string_literal: true

require 'date'

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A DateTimeType constraint asserts that the object is a DateTime.
  class DateTimeType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::DateTime, **options)
    end
  end
end
