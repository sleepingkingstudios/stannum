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

    # @param negated_type [String] The error type generated for a matching
    #   object.
    def initialize(negated_type: nil, **options)
      @negated_type = negated_type || NEGATED_TYPE

      super(negated_type: @negated_type, **options)
    end

    # @return [String] the error type generated for a matching object.
    attr_reader :negated_type

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
