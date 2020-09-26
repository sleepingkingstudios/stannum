# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # An example constraint that matches any object, even nil.
  #
  # @example
  #   constraint = Stannum::Constraints::Anything.new
  #   constraint.matches?(Object.new)
  #   #=> true
  #   constraint.does_not_match?(Object.new)
  #   #=> false
  class Anything < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.anything'

    # Returns true for all objects.
    #
    # @return [true] in all cases.
    #
    # @see Stannum::Constraint#matches?
    def matches?(_actual)
      true
    end
    alias match? matches?
  end
end
