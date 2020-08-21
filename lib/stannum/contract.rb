# frozen_string_literal: true

require 'stannum'

module Stannum
  # Contract class for defining a custom or one-off contract instance.
  #
  # @example Defining A Custom Contract
  #   user_contract = Stannum::Contract.new do
  #     # Sanity constraints are evaluated first, and if a sanity constraint
  #     # fails, the contract will immediately halt.
  #     constraint Stannum::Constraints::Type.new(User), sanity: true
  #
  #     # You can also define a constraint using a block.
  #     constraint(type: 'example.is_not_user') do |user|
  #       user.role == 'user'
  #     end
  #
  #     # You can define a constraint on a property of the object.
  #     property :name, Stannum::Constraints::Presence.new
  #   end
  #
  # @see Stannum::Contracts::Base.
  class Contract < Stannum::Contracts::PropertyContract
    # Builder class for defining item constraints for a Contract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for Contract.
    #
    # @api private
    class Builder < Stannum::Contracts::Builder
      # Defines a property constraint on the contract.
      #
      # @overload property(property, constraint, **options)
      #   Adds the given constraint to the contract for the property.
      #
      #   @param property [String, Symbol, Array<String, Symbol>] The property
      #     to constrain.
      #   @param constraint [Stannum::Constraint::Base] The constraint to add.
      #   @param options [Hash<Symbol, Object>] Options for the constraint.
      #
      # @overload property(**options) { |value| }
      #   Creates a new Stannum::Constraint object with the given block, and
      #   adds that constraint to the contract for the property.
      def property(property, constraint = nil, **options, &block)
        self.constraint(
          constraint,
          property: property,
          **options,
          &block
        )
      end
    end

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options, &block)
      super(**options)

      self.class::Builder.new(self).instance_exec(&block) if block_given?
    end
  end
end
