# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Abstract base class for contract builder classes.
  #
  # A contract builder provides a Domain-Specific Language for defining
  # constraints on a contract. They are typically used during initialization if
  # a block is passed to Contract#new.
  class Builder
    # @param contract [Stannum::Contract] The contract to which constraints are
    #   added.
    def initialize(contract)
      @contract = contract
    end

    # @return [Stannum::Contract] The contract to which constraints are added.
    attr_reader :contract

    # Adds a constraint to the contract.
    #
    # @overload constraint(constraint, **options)
    #   Adds the given constraint to the contract.
    #
    #   @param constraint [Stannum::Constraints::Base] The constraint to add to
    #     the contract.
    #   @param options [Hash<Symbol, Object>] Options for the constraint.
    #
    # @overload constraint(**options, &block)
    #   Creates an instance of Stannum::Constraint using the given block and
    #   adds it to the contract.
    #
    #   @param options [Hash<Symbol, Object>] Options for the constraint.
    #   @option options negated_type [String] The error type generated for a
    #     matching object.
    #   @option options type [String] The error type generated for a
    #     non-matching object.
    def constraint(constraint = nil, **options, &block)
      constraint = resolve_constraint(constraint, **options, &block)

      contract.add_constraint(constraint, **options)

      self
    end

    private

    def ambiguous_values_error(constraint)
      'expected either a block or a constraint instance, but received both a ' \
        "block and #{constraint.inspect}"
    end

    def resolve_constraint(constraint = nil, **options, &block)
      if block_given? && constraint
        raise ArgumentError, ambiguous_values_error(constraint), caller(1..-1)
      end

      return constraint if valid_constraint?(constraint)

      return Stannum::Constraint.new(**options, &block) if block

      raise ArgumentError,
        "invalid constraint #{constraint.inspect}",
        caller(1..-1)
    end

    def valid_constraint?(constraint)
      constraint.is_a?(Stannum::Constraints::Base)
    end
  end
end
