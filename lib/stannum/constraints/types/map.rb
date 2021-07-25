# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # Constraint for matching map-like objects.
  class Map < Stannum::Constraints::Signature
    EXPECTED_METHODS = %i[[] each keys].freeze
    private_constant :EXPECTED_METHODS

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(*EXPECTED_METHODS, **options)
    end
  end
end
