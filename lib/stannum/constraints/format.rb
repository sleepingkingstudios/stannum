# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # A Format constraint asserts the value is a string matching the given format.
  #
  # @example Using a Format constraint with a String format.
  #   format = 'Greetings'
  #   constraint = Stannum::Constraints::Format.new(format)
  #
  #   constraint.matches?(nil)                    #=> false
  #   constraint.matches?('Hello, world')         #=> false
  #   constraint.matches?('Greetings, programs!') #=> true
  #
  # @example Using a Format constraint with a Regex format.
  #   format = /\AGreetings/
  #   constraint = Stannum::Constraints::Format.new(format)
  #
  #   constraint.matches?(nil)                    #=> false
  #   constraint.matches?('Hello, world')         #=> false
  #   constraint.matches?('Greetings, programs!') #=> true
  class Format < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.matches_format'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.does_not_match_format'

    # @param expected_format [Regex, String] The expected object.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(expected_format, **options)
      @expected_format = expected_format

      super(expected_format:, **options)
    end

    # @return [Regex, String] the expected format.
    attr_reader :expected_format

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      return super if type_constraint.matches?(actual)

      type_constraint.errors_for(actual, errors:)
    end

    # Checks that the object is a string with the expected format.
    #
    # @return [true, false] true if the object is a string with the expected
    #   format, otherwise false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      return false unless type_constraint.matches?(actual)

      if expected_format.is_a?(String)
        actual.include?(expected_format)
      else
        actual.match?(expected_format)
      end
    end
    alias match? matches?

    private

    def type_constraint
      @type_constraint ||= Stannum::Constraints::Type.new(String)
    end
  end
end
