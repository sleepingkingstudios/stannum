# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # An example constraint that does not match any object, even nil.
  #
  # @example
  #   constraint = Stannum::Constraints::Nothing.new
  #   constraint.matches?(Object.new)
  #   #=> false
  #   constraint.does_not_match?(Object.new)
  #   #=> true
  class Nothing < Stannum::Constraints::Base
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
  end
end
