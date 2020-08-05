# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Struct that encapsulates a constraint definition on a contract.
  class Definition
    def initialize(attributes = {})
      attributes.each do |key, value|
        send(:"#{key}=", value)
      end
    end

    # @!attribute [rw] constraint
    #   @return [Stannum::Constraints::Base] the defined constraint.
    attr_accessor :constraint

    # @!attribute [rw] contract
    #   @return [Stannum::Contracts::Base] the contract containing the
    #     constraint.
    attr_accessor :contract

    # @!attribute [rw] options
    #   @return [Hash<Symbol, Object>] the options defined for the constraint.
    attr_accessor :options

    def ==(other)
      other.is_a?(self.class) &&
        other.constraint == constraint &&
        other.contract   == contract &&
        other.options    == options
    end
  end
end
