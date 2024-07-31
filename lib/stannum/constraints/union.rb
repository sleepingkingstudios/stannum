# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum::Constraints
  # Asserts that the object matches one of the given constraints.
  #
  # @example Using a Union Constraint.
  #   false_constraint = Stannum::Constraint.new { |actual| actual == false }
  #   true_constraint  = Stannum::Constraint.new { |actual| actual == true }
  #   union_constraint = Stannum::Constraints::Union.new(
  #     false_constraint,
  #     true_constraint
  #   )
  #
  #   constraint.matches?(nil)   #=> false
  #   constraint.matches?(false) #=> true
  #   constraint.matches?(true)  #=> true
  class Union < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_in_union'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_in_union'

    # @overload initialize(*expected_constraints, **options)
    #   @param expected_constraints [Array<Stannum::Constraints::Base>] The
    #     possible values for the object.
    #   @param options [Hash<Symbol, Object>] Configuration options for the
    #     constraint. Defaults to an empty Hash.
    def initialize(first, *rest, **options)
      expected_constraints = rest.unshift(first)

      super(expected_constraints:, **options)

      @expected_constraints = expected_constraints
    end

    # @return [Array<Stannum::Constraints::Base>] the possible values for the
    #   object.
    attr_reader :expected_constraints

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new).add(type, constraints: expected_values)
    end

    # Checks that the object matches at least one of the given constraints.
    #
    # @return [true, false] false if the object matches a constraint, otherwise
    #   false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      expected_constraints.any? { |constraint| constraint.matches?(actual) }
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new)
        .add(negated_type, constraints: negated_values)
    end

    private

    def expected_values
      @expected_constraints.map do |constraint|
        {
          options: constraint.options,
          type:    constraint.type
        }
      end
    end

    def negated_values
      @expected_constraints.map do |constraint|
        {
          negated_type: constraint.negated_type,
          options:      constraint.options
        }
      end
    end
  end
end
