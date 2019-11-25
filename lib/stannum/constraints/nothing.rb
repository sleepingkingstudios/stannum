# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # An example constraint that does not match any object, even nil.
  #
  # @example
  #   constraint = Stannum::Constraints::Nothing.new
  #   constraint.matches?(Object.new)
  #   #=> false
  #   constraint.does_not_match?(Object.new)
  #   #=> true
  class Nothing < Stannum::Constraint
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.nothing'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.anything'

    # Returns false for all objects.
    #
    # @return [false] in all cases.
    #
    # @see Stannum::Constraint#matches?
    def matches?(_actual)
      false
    end
    alias match? matches?

    # @return [String] the error type generated for a matching object.
    def negated_type
      NEGATED_TYPE
    end

    # @return [String] the error type generated for a non-matching object.
    def type
      TYPE
    end
  end
end
