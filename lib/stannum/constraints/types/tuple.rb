# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # Constraint for matching tuple-like objects.
  class Tuple < Stannum::Constraints::Methods
    EXPECTED_METHODS = %i[[] each size].freeze
    private_constant :EXPECTED_METHODS

    def initialize
      super(*EXPECTED_METHODS)
    end
  end
end
