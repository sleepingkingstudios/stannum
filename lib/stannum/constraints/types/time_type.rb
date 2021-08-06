# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A TimeType constraint asserts that the object is a Time.
  class TimeType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Time, **options)
    end
  end
end
