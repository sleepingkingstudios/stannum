# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # An Identity constraint checks for the exact object given.
  #
  # @example Using an Identity constraint
  #   string     = 'Greetings, programs!'
  #   constraint = Stannum::Constraints::Identity.new(string)
  #
  #   constraint.matches?(nil)        #=> false
  #   constraint.matches?('a string') #=> false
  #   constraint.matches?(string.dup) #=> false
  #   constraint.matches?(string)     #=> true
  class Identity < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_value'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_value'

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
      expected_value.equal?(actual)
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
