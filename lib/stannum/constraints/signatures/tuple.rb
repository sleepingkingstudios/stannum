# frozen_string_literal: true

require 'stannum/constraints/signatures'

module Stannum::Constraints::Signatures
  # Constraint for matching tuple-like objects.
  class Tuple < Stannum::Constraints::Signature
    EXPECTED_METHODS = %i[[] each size].freeze
    private_constant :EXPECTED_METHODS

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(*EXPECTED_METHODS, **options)
    end
  end
end
