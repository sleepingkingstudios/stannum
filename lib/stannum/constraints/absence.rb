# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # An absence constraint asserts that the object is nil or empty.
  #
  # @example Using an Absence constraint
  #   constraint = Stannum::Constraints::Absence.new
  #
  #   constraint.matches?(nil) #=> true
  #   constraint.matches?(Object.new)  #=> false
  #
  # @example Using a Absence constraint with an Array
  #   constraint.matches?([])        #=> true
  #   constraint.matches?([1, 2, 3]) #=> false
  #
  # @example Using a Absence constraint with an Hash
  #   constraint.matches?({})               #=> true
  #   constraint.matches?({ key: 'value' }) #=> false
  class Absence < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = Stannum::Constraints::Presence::TYPE

    # The :type of the error generated for a non-matching object.
    TYPE = Stannum::Constraints::Presence::NEGATED_TYPE

    # Checks that the object is nil or empty.
    #
    # @return [true, false] true if the object is nil or empty, otherwise false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      return true if actual.nil?

      return true if actual.respond_to?(:empty?) && actual.empty?

      false
    end
    alias match? matches?
  end
end
