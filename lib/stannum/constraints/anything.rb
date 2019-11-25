# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # An example constraint that matches any object, even nil.
  #
  # @example
  #   constraint = Stannum::Constraints::Anything.new
  #   constraint.matches?(Object.new)
  #   #=> true
  #   constraint.does_not_match?(Object.new)
  #   #=> false
  class Anything < Stannum::Constraint
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.anything'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.nothing'

    # Returns true for all objects.
    #
    # @return [true] in all cases.
    #
    # @see Stannum::Constraint#matches?
    def matches?(_actual)
      true
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
