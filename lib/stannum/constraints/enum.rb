# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # An enum constraint asserts that the object is one of the given values.
  #
  # @example Using an Enum Constraint
  #   constraint = Stannum::Constraints::Enum.new('red', 'green', 'blue')
  #
  #   constraint.matches?('red')    #=> true
  #   constraint.matches?('yellow') #=> false
  class Enum < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_in_list'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_in_list'

    # @overload initialize(*expected_values, **options)
    #   @param expected_values [Array] the possible values for the object.
    #   @param options [Hash<Symbol, Object>] Configuration options for the
    #     constraint. Defaults to an empty Hash.
    def initialize(first, *rest, **options)
      expected_values = rest.unshift(first)

      super(expected_values: expected_values, **options)

      @matching_values = Set.new(expected_values)
    end

    # @return [Array] the possible values for the object.
    def expected_values
      options[:expected_values]
    end

    # Checks that the object is in the list of expected values.
    #
    # @return [true, false] false if the object is in the list of expected
    #   values, otherwise true.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      @matching_values.include?(actual)
    end
    alias match? matches?

    protected

    # rubocop:disable Lint/UnusedMethodArgument
    def update_errors_for(actual:, errors:)
      errors.add(type, values: expected_values)
    end

    def update_negated_errors_for(actual:, errors:)
      errors.add(negated_type, values: expected_values)
    end
    # rubocop:enable Lint/UnusedMethodArgument

    private

    attr_reader :matching_values
  end
end
