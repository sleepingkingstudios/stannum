# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A Proc type constraint asserts that the object is a Proc.
  class ProcType < Stannum::Constraints::Type
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(::Proc, **options)
    end
  end
end
