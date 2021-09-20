# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # An Equality constraint uses #== to compare the actual and expected objects.
  #
  # @example Using an Equality constraint
  #   string     = 'Greetings, programs!'
  #   constraint = Stannum::Constraints::Equality.new(string)
  #
  #   constraint.matches?(nil)         #=> false
  #   constraint.matches?('something') #=> false
  #   constraint.matches?('a string')  #=> true
  #   constraint.matches?(string.dup)  #=> true
  #   constraint.matches?(string)      #=> true
  class Equality < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_equal_to'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_equal_to'

    # @param expected_value [Object] The expected object.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(expected_value, **options)
      @expected_value = expected_value

      super(expected_value: expected_value, **options)
    end

    # @return [Object] the expected object.
    attr_reader :expected_value

    # Checks that the object is the expected value.
    #
    # @return [true, false] true if the object is the expected value, otherwise
    #   false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      expected_value == actual
    end
    alias match? matches?
  end
end
