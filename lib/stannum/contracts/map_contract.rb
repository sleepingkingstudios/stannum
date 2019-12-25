# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Contract that defines constraints on an object's properties.
  #
  # @example Creating A Contract With Properties
  #   length_constraint =
  #     Stannum::Constraint.new { |value| value.is_a?(Integer) }
  #
  #   contract = Stannum::Contracts::MapContract.new do
  #     property :length,       length_constraint
  #     property :manufacturer, Spec::ManufacturerContract.new
  #     property :name,         -> { |value| value.is_a?(String) }
  #   end
  class MapContract < Stannum::Contract
    # Builder class for defining property constraints for a MapContract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for MapContract.
    #
    # @api private
    class Builder
      # @param contract [Stannum::Contract] The contract to which constraints
      #   are added.
      def initialize(contract)
        @contract = contract
      end

      # @return [Stannum::Contract] the contract to which constraints are added.
      attr_reader :contract

      # Defines a property constraint on the contract.
      #
      # @overload property(property_name, constraint)
      #   Adds the given constraint to the contract for the given property.
      #
      #   @param property_name [String, Symbol] The name of the property to
      #     constrain.
      #   @param constraint [Stannum::Constraint::Base] The constraint to add.
      #
      # @overload property(property_name) { |value| }
      #   Creates a new Stannum::Constraint object with the given block, and
      #   adds that constraint to the contract for the given property.
      #
      #   @param property_name [String, Symbol] The name of the property to
      #     constrain.
      #   @yieldparam value [Object] The value of the property when called.
      #
      # @raise ArgumentError if the property name is not valid.
      #
      # @see Stannum::Contract#add_constraint.
      def property(property_name, constraint = nil, &block)
        validate_property_name(property_name)

        constraint = resolve_constraint(block: block, constraint: constraint)

        contract.add_constraint(constraint, property: property_name)
      end

      private

      def ambiguous_values_error(constraint)
        'expected either a block or a constraint instance, but received both' \
        " a block and #{constraint.inspect}"
      end

      def resolve_constraint(block:, constraint:)
        if block && constraint
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

      def validate_property_name(property_name)
        return if contract.send(:valid_property?, property_name)

        raise ArgumentError,
          "invalid property name #{property_name.inspect}",
          caller(1..-1)
      end
    end

    # @yield Creates an instance of MapContract::Builder with the new contract
    #   and executes the block in the context of the builder.
    #
    # @see Stannum::Contracts::MapContract::Builder
    def initialize(&block)
      super

      build_constraints(block) if block_given?
    end

    private

    def build_constraints(block)
      self.class::Builder.new(self).instance_exec(&block)
    end

    def valid_property?(property_name)
      unless property_name.is_a?(String) || property_name.is_a?(Symbol)
        return false
      end

      !property_name.empty?
    end
  end
end
