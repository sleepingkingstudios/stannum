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

    private

    def ambiguous_values_error(constraint)
      'expected either a block or a constraint instance, but received both a' \
      " block and #{constraint.inspect}"
    end

    def resolve_constraint(constraint = nil, &block)
      if block_given? && constraint
        raise ArgumentError, ambiguous_values_error(constraint), caller(1..-1)
      end

      return constraint if valid_constraint?(constraint)

      return Stannum::Constraint.new(&block) if block

      raise ArgumentError,
        "invalid constraint #{constraint.inspect}",
        caller(1..-1)
    end

    def valid_constraint?(constraint)
      constraint.is_a?(Stannum::Constraints::Base)
    end
  end
end
