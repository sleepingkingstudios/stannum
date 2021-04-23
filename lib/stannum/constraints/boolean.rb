# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # A Boolean constraint matches only true or false.
  #
  # @example Using a Boolean constraint
  #   constraint = Stannum::Constraints::Boolean.new
  #
  #   constraint.matches?(nil)        #=> false
  #   constraint.matches?('a string') #=> false
  #   constraint.matches?(false)      #=> true
  #   constraint.matches?(true)       #=> true
  class Boolean < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_boolean'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_boolean'

    # Checks that the object is either true or false.
    #
    # @return [true, false] true if the object is true or false, otherwise
    #   false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      true.equal?(actual) || false.equal?(actual)
    end
    alias match? matches?
  end
end
