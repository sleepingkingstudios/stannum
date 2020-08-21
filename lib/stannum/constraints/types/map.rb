# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # Constraint for matching map-like objects.
  class Map < Stannum::Constraints::Methods
    EXPECTED_METHODS = %i[[] each keys].freeze
    private_constant :EXPECTED_METHODS

    def initialize
      super(*EXPECTED_METHODS)
    end
  end
end
