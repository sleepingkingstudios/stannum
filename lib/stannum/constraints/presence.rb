# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # A presence constraint asserts that the object is not nil and not empty.
  #
  # @example Using a Presence constraint
  #   constraint = Stannum::Constraints::Presence.new
  #
  #   constraint.matches?(nil) #=> false
  #   constraint.matches?(Object.new)  #=> false
  #
  # @example Using a Presence constraint with an Array
  #   constraint.matches?([])        #=> false
  #   constraint.matches?([1, 2, 3]) #=> true
  #
  # @example Using a Presence constraint with an Hash
  #   constraint.matches?({})               #=> false
  #   constraint.matches?({ key: 'value' }) #=> true
  class Presence < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.present'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.absent'

    # Checks that the object is not nil and not empty.
    #
    # @return [true, false] false if the object is nil or empty, otherwise true.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      return false if actual.nil?

      return false if actual.respond_to?(:empty?) && actual.empty?

      true
    end
    alias match? matches?
  end
end
