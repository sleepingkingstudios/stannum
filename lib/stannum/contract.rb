# frozen_string_literal: true

require 'stannum'
require 'stannum/contracts/base'

module Stannum
  # A Contract defines constraints on an object and its properties.
  #
  # @example Creating A Contract With Property Constraints
  #   Widget = Struct.new(:name, :manufacturer)
  #   Manufacturer = Struct.new(:factory)
  #   Factory = Struct.new(:address)
  #
  #   type_constraint = Stannum::Constraints::Type.new(Widget)
  #   name_constraint =
  #     Stannum::Constraint.new(type: 'wrong_name', negated_type: 'right_name') do |value|
  #       value == 'Self-sealing Stem Bolt'
  #     end
  #   address_constraint =
  #     Stannum::Constraint.new(type: 'wrong_address', negated_type: 'right_address') do |value|
  #       value == '123 Example Street'
  #     end
  #   contract =
  #     Stannum::Contract.new
  #     .add_constraint(type_constraint)
  #     .add_constraint(name_constraint, property: :name)
  #     .add_constraint(address_constraint, property: %i[manufacturer factory address])
  #
  # @example With An Object That Matches None Of The Property Constraints
  #   # With a non-Widget object.
  #   contract.matches?(nil) #=> false
  #   errors = contract.errors_for(nil)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_not_type', data: { type: Widget }, path: [], message: nil },
  #     { type: 'wrong_name', data: {}, path: [:name], message: nil },
  #     { type: 'wrong_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
  #   ]
  #   errors[:name].to_a
  #   #=> [
  #     { type: 'wrong_name', data: {}, path: [], message: nil }
  #   ]
  #   errors[:manufacturer].to_a
  #   #=> [
  #     { type: 'wrong_address', data: {}, path: [:factory, :address], message: nil }
  #   ]
  #
  #   contract.does_not_match?(nil)          #=> true
  #   contract.negated_errors_for?(nil).to_a #=> []
  #
  # @example With An Object That Matches Some Of The Property Constraints
  #   contract.matches?(Widget.new) #=> false
  #   errors = contract.errors_for(Widget.new)
  #   errors.to_a
  #   #=> [
  #     { type: 'wrong_name', data: {}, path: [:name], message: nil },
  #     { type: 'wrong_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
  #   ]
  #
  #   contract.does_not_match?(Widget.new) #=> false
  #   errors = contract.negated_errors_for(Widget.new)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Widget }, path: [], message: nil }
  #   ]
  #
  # @example With An Object That Matches All Of The Property Constraints
  #   factory      = Factory.new('123 Example Street')
  #   manufacturer = Manufacturer.new(factory)
  #   widget       = Widget.new('Self-sealing Stem Bolt', manufacturer)
  #   contract.matches?(widget)        #=> true
  #   contract.errors_for(widget).to_a #=> []
  #
  #   contract.does_not_match?(widget) #=> true
  #   errors = contract.negated_errors_for(widget)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Widget }, path: [], message: nil },
  #     { type: 'right_name', data: {}, path: [:name], message: nil },
  #     { type: 'right_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
  #   ]
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
  class Contract < Stannum::Contracts::Base
    # Builder class for defining item constraints for a Contract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for Contract.
    #
    # @api private
    class Builder < Stannum::Contracts::Base::Builder
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
      def property(property, constraint = nil, **options, &)
        self.constraint(
          constraint,
          property:,
          **options,
          &
        )
      end
    end

    # (see Stannum::Contracts::Base#add_constraint)
    #
    # If the :property option is set, this defines a property constraint. See
    # #add_property_constraint for more information.
    #
    # @param property [String, Symbol, Array<String, Symbol>, nil] The
    #   property to match.
    #
    # @see #add_property_constraint.
    def add_constraint(constraint, property: nil, sanity: false, **options)
      validate_constraint(constraint)
      validate_property(property:, **options)

      @constraints << Stannum::Contracts::Definition.new(
        constraint:,
        contract:   self,
        options:    options.merge(property:, sanity:)
      )

      self
    end

    # Adds a property constraint to the contract.
    #
    # When the contract is called, the contract will find the value of that
    # property for the given object. If the property is an array, the contract
    # will recursively retrieve each property.
    #
    # A property of nil will match against the given object itself, rather
    # than one of its properties.
    #
    # If the value does not match the constraint, then the error from the
    # constraint will be added in an error namespace matching the constraint.
    # For example, a property of :name will add the error message to
    # errors.dig(:name), while a property of [:manufacturer, :address, :street]
    # will add the error message to
    # errors.dig(:manufacturer, :address, :street).
    #
    # @param property [String, Symbol, Array<String, Symbol>, nil] The
    #   property to match.
    # @param constraint [Stannum::Constraints::Base] The constraint to add.
    # @param sanity [true, false] Marks the constraint as a sanity constraint,
    #   which is always matched first and will always short-circuit on a failed
    #   match.
    # @param options [Hash<Symbol, Object>] Options for the constraint. These
    #   can be used by subclasses to define the value and error mappings for the
    #   constraint.
    #
    # @return [self] the contract.
    #
    # @see #add_constraint.
    def add_property_constraint(property, constraint, sanity: false, **options)
      add_constraint(constraint, property:, sanity:, **options)
    end

    protected

    def map_errors(errors, **options)
      property_name = options.fetch(:property_name, options[:property])

      return errors if property_name.nil?

      errors.dig(*Array(property_name))
    end

    def map_value(actual, **options)
      property = options[:property]

      return actual if property.nil?

      access_nested_property(actual, property)
    end

    private

    def access_nested_property(object, property)
      Array(property).reduce(object) { |obj, prop| access_property(obj, prop) }
    end

    def access_property(object, property)
      object.send(property) if object.respond_to?(property, true)
    end

    def valid_property?(property: nil, **_options)
      if property.is_a?(Array)
        return false if property.empty?

        return property.all? { |item| valid_property_name?(item) }
      end

      valid_property_name?(property)
    end

    def valid_property_name?(name)
      return false unless name.is_a?(String) || name.is_a?(Symbol)

      !name.empty?
    end

    def validate_property(**options)
      return unless validate_property?(**options)

      return if valid_property?(**options)

      raise ArgumentError,
        "invalid property name #{options[:property].inspect}",
        caller(1..-1)
    end

    def validate_property?(property: nil, **_options)
      !property.nil?
    end
  end
end
