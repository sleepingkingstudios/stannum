# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Struct that encapsulates a constraint definition on a contract.
  class Definition
    # @param attributes [Hash] The attributes for the definition.
    # @option attributes [Stannum::Constraints::Base] :constraint The constraint
    #   to define for the contract.
    # @option attributes [Stannum::Contracts::Base] :contract The contract for
    #   which the constraint is defined.
    # @option attributes [Hash<Symbol, Object>] :options The options for the
    #   constraint.
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

    # Compares the other object with the definition.
    #
    # @param other [Object] The object to compare.
    #
    # @return [Boolean] true if the other object is a Definition with the same
    #   attributes; otherwise false.
    def ==(other)
      other.is_a?(self.class) &&
        other.constraint == constraint &&
        other.contract.equal?(contract) &&
        other.options == options
    end

    # @return [nil, String, Symbol, Array<String, Symbol>] the property scope of
    #   the constraint.
    def property
      options[:property]
    end

    # @return [nil, String, Symbol, Array<String, Symbol>] the property name of
    #   the constraint, used for generating errors. If not given, defaults to
    #   the value of #property.
    def property_name
      options.fetch(:property_name, options[:property])
    end

    # @return [Boolean] true if options[:sanity] is set to a truthy value;
    #   otherwise false.
    def sanity?
      !!options[:sanity]
    end
  end
end
