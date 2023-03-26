# frozen_string_literal: true

require 'stannum/entities'

module Stannum::Entities
  # Methods for defining and accessing entity constraints.
  module Constraints
    # Class methods to extend the class when including Attributes.
    module AttributesMethods
      # Defines an attribute on the entity.
      #
      # Delegates to the superclass method, and then adds a type constraint to
      # ::Contract.
      #
      # @see Stannum::Entities::Attributes::ClassMethods#attribute.
      def attribute(attr_name, attr_type, **options) # rubocop:disable Metrics/MethodLength
        returned = super

        attribute  = attributes[attr_name.to_s]
        constraint = Stannum::Constraints::Type.new(
          attribute.type,
          required: attribute.required?
        )

        self::Contract.add_constraint(
          constraint,
          property: attribute.reader_name
        )

        returned
      end
      alias define_attribute attribute
    end

    # Class methods to extend the class when including Constraints.
    module ClassMethods
      # Defines a constraint on the entity or one of its properties.
      #
      # @overload constraint()
      #   Defines a constraint on the entity.
      #
      #   A new Stannum::Constraint instance will be generated, passing the
      #   block from .constraint to the new constraint. This constraint will be
      #   added to the contract.
      #
      #   @yieldparam entity [Stannum::Entities::Constraints] The entity at the
      #     time the constraint is evaluated.
      #
      # @overload constraint(constraint)
      #   Defines a constraint on the entity.
      #
      #   The given constraint is added to the contract. When the contract is
      #   evaluated, this constraint will be matched against the entity.
      #
      #   @param constraint [Stannum::Constraints::Base] The constraint to add.
      #
      # @overload constraint(attr_name)
      #   Defines a constraint on the given attribute or property.
      #
      #   A new Stannum::Constraint instance will be generated, passing the
      #   block from .constraint to the new constraint. This constraint will be
      #   added to the contract.
      #
      #   @param attr_name [String, Symbol] The name of the attribute or
      #     property to constrain.
      #
      #   @yieldparam value [Object] The value of the attribute or property of
      #     the entity at the time the constraint is evaluated.
      #
      # @overload constraint(attr_name, constraint)
      #   Defines a constraint on the given attribute or property.
      #
      #   The given constraint is added to the contract. When the contract is
      #   evaluated, this constraint will be matched against the value of the
      #   attribute or property.
      #
      #   @param attr_name [String, Symbol] The name of the attribute or
      #     property to constrain.
      #   @param constraint [Stannum::Constraints::Base] The constraint to add.
      def constraint(attr_name = nil, constraint = nil, &block)
        attr_name, constraint = resolve_constraint(attr_name, constraint)

        if block_given?
          constraint = Stannum::Constraint.new(&block)
        else
          validate_constraint(constraint)
        end

        contract.add_constraint(constraint, property: attr_name)
      end

      # @return [Stannum::Contract] The Contract object for the entity.
      def contract
        self::Contract
      end

      private

      def included(other)
        super

        other.include(Stannum::Entities::Constraints)

        Stannum::Entities::Constraints.apply(other) if other.is_a?(Class)
      end

      def inherited(other)
        super

        Stannum::Entities::Constraints.apply(other)
      end

      def resolve_constraint(attr_name, constraint)
        return [nil, attr_name] if attr_name.is_a?(Stannum::Constraints::Base)

        unless attr_name.nil?
          tools.assertions.validate_name(attr_name, as: 'attribute')
        end

        [attr_name.nil? ? attr_name : attr_name.intern, constraint]
      end

      def tools
        SleepingKingStudios::Tools::Toolbelt.instance
      end

      def validate_constraint(constraint)
        raise ArgumentError, "constraint can't be blank" if constraint.nil?

        return if constraint.is_a?(Stannum::Constraints::Base)

        raise ArgumentError, 'constraint must be a Stannum::Constraints::Base'
      end
    end

    class << self
      # Generates a Contract for the class.
      #
      # Creates a new Stannum::Contract and sets it as the class's :Contract
      # constant. If the superclass is an entity class (and already defines its
      # own Contract, concatenates the superclass Contract into the class
      # Contract).
      #
      # @param other [Class] the class to which attributes are added.
      def apply(other)
        return unless other.is_a?(Class)

        return if entity_class?(other)

        contract = Stannum::Contract.new

        other.const_set(:Contract, contract)

        return unless entity_class?(other.superclass)

        contract.concat(other.superclass::Contract)
      end

      private

      def entity_class?(other)
        other.const_defined?(:Contract, false)
      end

      def included(other)
        super

        other.extend(self::ClassMethods)

        if other < Stannum::Entities::Attributes
          other.extend(self::AttributesMethods)
        end

        apply(other) if other.is_a?(Class)
      end
    end
  end
end
