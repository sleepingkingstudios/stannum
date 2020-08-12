# frozen_string_literal: true

require 'stannum/contracts'
require 'stannum/contracts/base'

module Stannum::Contracts
  # A PropertyContract defines constraints on an object's properties.
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
  #   property_contract =
  #     Stannum::Contract.new
  #     .add_constraint(type_constraint)
  #     .add_constraint(name_constraint, property: :name)
  #     .add_constraint(address_constraint, property: %i[manufacturer factory address])
  #
  # @example With An Object That Matches None Of The Property Constraints
  #   # With a non-Widget object.
  #   property_contract.matches?(nil) #=> false
  #   errors = property_contract.errors_for(nil)
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
  #   property_contract.does_not_match?(nil)          #=> true
  #   property_contract.negated_errors_for?(nil).to_a #=> []
  #
  # @example With An Object That Matches Some Of The Property Constraints
  #   property_contract.matches?(Widget.new) #=> false
  #   errors = property_contract.errors_for(Widget.new)
  #   errors.to_a
  #   #=> [
  #     { type: 'wrong_name', data: {}, path: [:name], message: nil },
  #     { type: 'wrong_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
  #   ]
  #
  #   property_contract.does_not_match?(Widget.new) #=> false
  #   errors = property_contract.negated_errors_for(Widget.new)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Widget }, path: [], message: nil }
  #   ]
  #
  # @example With An Object That Matches All Of The Property Constraints
  #   factory      = Factory.new('123 Example Street')
  #   manufacturer = Manufacturer.new(factory)
  #   widget       = Widget.new('Self-sealing Stem Bolt', manufacturer)
  #   property_contract.matches?(widget)        #=> true
  #   property_contract.errors_for(widget).to_a #=> []
  #
  #   property_contract.does_not_match?(widget) #=> true
  #   errors = property_contract.negated_errors_for(widget)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Widget }, path: [], message: nil },
  #     { type: 'right_name', data: {}, path: [:name], message: nil },
  #     { type: 'right_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
  #   ]
  class PropertyContract < Stannum::Contracts::Base
    # @!method add_constraint(constraint, property: nil, **options)
    #   Adds a property constraint to the contract.
    #
    #   When the contract is called, the contract will find the value of that
    #   property for the given object. If the property is an array, the contract
    #   will recursively retrieve each property.
    #
    #   A property of nil will match against the given object itself, rather
    #   than one of its properties.
    #
    #   If the value does not match the constraint, then the error from the
    #   constraint will be added in an error namespace matching the constraint.
    #   For example, a property of :name will add the error message to
    #   errors.dig(:name), while a property
    #   of [:manufacturer, :address, :street] will add the error message to
    #   errors.dig(:manufacturer, :address, :street).
    #
    #   @param constraint [Stannum::Constraints::Base] The constraint to add.
    #
    #   @param property [String, Symbol, Array<String, Symbol>, nil] The
    #     property to match.
    #
    #   @param options [Hash<Symbol, Object>] Options for the constraint.
    #
    #   @return [self] the contract.

    # @!method yard_hack

    protected

    def map_errors(errors, **options)
      property = options[:property]

      return errors if property.nil?

      errors.dig(*Array(property))
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
  end
end
