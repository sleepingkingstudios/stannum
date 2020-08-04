# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum
  # A contract aggregates constraints about the given object or its properties.
  #
  # @example Creating A Contract With Constraints
  #   numeric_constraint =
  #     Stannum::Constraint.new(type: 'not_numeric', negated_type: 'numeric') do |actual|
  #       actual.is_a?(Numeric)
  #     end
  #   integer_constraint =
  #     Stannum::Constraint.new(type: 'not_integer', negated_type: 'integer') do |actual|
  #       actual.is_a?(Integer)
  #     end
  #   range_constraint =
  #     Stannum::Constraint.new(type: 'not_in_range', negated_type: 'in_range') do |actual|
  #       actual >= 0 && actual <= 10 rescue false
  #     end
  #   contract =
  #     Stannum::Contract.new
  #     .add_constraint(numeric_constraint)
  #     .add_constraint(integer_constraint)
  #     .add_constraint(range_constraint)
  #
  # @example With An Object That Matches None Of The Constraints
  #   contract.matches?(nil) #=> false
  #   errors = contract.errors_for(nil) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> [
  #     { type: 'not_numeric',  data: {}, path: [], message: nil },
  #     { type: 'not_integer',  data: {}, path: [], message: nil },
  #     { type: 'not_in_range', data: {}, path: [], message: nil }
  #   ]
  #
  #   contract.does_not_match?(nil) #=> true
  #   errors = contract.negated_errors_for(nil) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> []
  #
  # @example With An Object That Matches Some Of The Constraints
  #   contract.matches?(11) #=> false
  #   contract.errors_for(11).to_a
  #   #=> [
  #     { type: 'not_in_range', data: {}, path: [], message: nil }
  #   ]
  #
  #   contract.does_not_match?(11) #=> true
  #   contract.negated_errors_for(11).to_a
  #   #=> [
  #     { type: 'numeric',  data: {}, path: [], message: nil },
  #     { type: 'integer',  data: {}, path: [], message: nil }
  #   ]
  #
  # @example With An Object That Matches All Of The Constraints
  #   contract.matches?(5)        #=> true
  #   contract.errors_for(5).to_a #=> []
  #
  #   contract.does_not_match?(5) #=> false
  #   contract.negated_errors_for(5)
  #   #=> [
  #     { type: 'numeric',  data: {}, path: [], message: nil },
  #     { type: 'integer',  data: {}, path: [], message: nil },
  #     { type: 'in_range', data: {}, path: [], message: nil }
  #   ]
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
  class Contract < Stannum::Constraints::Base # rubocop:disable Metrics/ClassLength
    def initialize(**options)
      @constraints = []
      @included    = []

      super(**options)
    end

    # @!method errors_for(actual)
    #   Generates an errors object for a non-matching object.
    #
    #   Creates an empty errors object. For each constraint, if the constraint
    #   does not match the given object, then the constraint's errors will be
    #   merged into the errors object.
    #
    #   If the constraint has a property reference, then the constraint will be
    #   matched against the value of that property for the given object, and the
    #   errors (if any) will be merged into the nested errors object for that
    #   property.
    #
    #   @example With A Contract With Constraints
    #     errors = contract.errors_for(nil) #=> Cuprum::Errors
    #     errors.to_a
    #     #=> [
    #       { type: 'not_numeric',  data: {}, path: [], message: nil },
    #       { type: 'not_integer',  data: {}, path: [], message: nil },
    #       { type: 'not_in_range', data: {}, path: [], message: nil }
    #     ]
    #
    #     contract.errors_for(11.5).to_a
    #     #=> [
    #       { type: 'not_integer',  data: {}, path: [], message: nil },
    #       { type: 'not_in_range', data: {}, path: [], message: nil }
    #     ]
    #
    #     contract.errors_for(11).to_a
    #     #=> [
    #       { type: 'not_in_range', data: {}, path: [], message: nil }
    #     ]
    #
    #   @example With A Contract With Property Constraints
    #     errors = property_contract.errors_for(nil) #=> Cuprum::Errors
    #     errors.to_a
    #     #=> [
    #       { type: 'is_not_type', data: { type: Widget }, path: [], message: nil },
    #       { type: 'wrong_name', data: {}, path: [:name], message: nil },
    #       { type: 'wrong_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
    #     ]
    #
    #     errors[:name].to_a
    #     #=> [
    #       { type: 'wrong_name', data: {}, path: [], message: nil },
    #     ]
    #
    #     errors.dig(:manufacturer, :factory, :address).to_a
    #     #=> [
    #       { type: 'wrong_address', data: {}, path: [], message: nil }
    #     ]
    #
    #   @see #matches?
    #   @see Stannum::Constraints::Base#errors_for.

    # @!method negated_errors_for(actual)
    #   Generates an errors object for a matching object.
    #
    #   Creates an empty errors object. For each constraint, if the constraint
    #   matches the given object, then the constraint's errors will be merged
    #   into the errors object.
    #
    #   If the constraint has a property reference, then the constraint will be
    #   matched against the value of that property for the given object, and the
    #   errors (if any) will be merged into the nested errors object for that
    #   property.
    #
    #   @example With A Contract With Constraints
    #     errors = contract.negated_errors_for(5) #=> Cuprum::Errors
    #     errors.to_a
    #     #=> [
    #       { type: 'numeric',  data: {}, path: [], message: nil },
    #       { type: 'integer',  data: {}, path: [], message: nil },
    #       { type: 'in_range', data: {}, path: [], message: nil }
    #     ]
    #
    #     contract.negated_errors_for(11).to_a
    #     #=> [
    #       { type: 'numeric',  data: {}, path: [], message: nil },
    #       { type: 'integer',  data: {}, path: [], message: nil }
    #     ]
    #
    #     contract.negated_errors_for(11.5).to_a
    #     #=> [
    #       { type: 'numeric',  data: {}, path: [], message: nil }
    #     ]
    #
    #   @example With A Contract With Property Constraints
    #     factory      = Factory.new('123 Example Street')
    #     manufacturer = Manufacturer.new(factory)
    #     widget       = Widget.new('Self-sealing Stem Bolt', manufacturer)
    #
    #     errors = property_contract.errors_for(widget) #=> Cuprum::Errors
    #     errors.to_a
    #     #=> [
    #       { type: 'is_type', data: { type: Widget }, path: [], message: nil },
    #       { type: 'right_name', data: {}, path: [:name], message: nil },
    #       { type: 'right_address', data: {}, path: [:manufacturer, :factory, :address], message: nil }
    #     ]
    #
    #     errors[:name].to_a
    #     #=> [
    #       { type: 'right_name', data: {}, path: [], message: nil },
    #     ]
    #
    #     errors.dig(:manufacturer, :factory, :address).to_a
    #     #=> [
    #       { type: 'right_address', data: {}, path: [], message: nil }
    #     ]
    #
    #   @see #does_not_match?
    #   @see #errors_for

    # Adds a constraint on the given object or its properties.
    #
    # If the property is nil, then the constraint will be applied to the object
    # itself. For example, a type constraint would be applied to the base
    # object.
    #
    # If the property is a string or symbol, then the contract will call the
    # corresponding method of the given object, and compare the constraint to
    # the value returned.
    #
    # If the property is an array of strings and/or symbols, then the contract
    # will recursively call the methods - the first property will be called on
    # the given object, the second property called on the value returned by the
    # first method call, and so on. The contract will compare the constraint to
    # the nested value returned.
    #
    # @param constraint [Stannum::Constraint] The constraint to add.
    # @param property [nil, String, Symbol, Array<String, Symbol>] The property
    #   on the object to constrain. The default value is nil.
    #
    # @return [Stannum::Contract] the contract.
    #
    # @example Adding A Constraint
    #   # Checks that the given object is a Widget.
    #   contract = Stannum::Contract.new
    #   contract.add_constraint(Stannum::Constraints::Type(Widget))
    #
    # @example Adding A Property Constraint
    #   # Checks that the given object's name is 'Gadget'
    #   constraint = Stannum::Constraint.new { |name| name == 'Gadget'}
    #   contract   = Stannum::Contract.new
    #   contract.add_constraint(constraint, property: :name)
    #
    # @example Adding A Nested Property Constraint
    #   # Checks the given object's manufacturer's factory's address.
    #   constraint = Stannum::Constraint.new { |address| address == 'None' }
    #   contract   = Stannum::Contract.new
    #   property   = [:manufacturer, :factory, :address]
    #   contract.add_constraint(constraint, property: property)
    def add_constraint(constraint, property: nil)
      validate_constraint(constraint)

      @constraints << {
        constraint: constraint,
        property:   property
      }

      self
    end

    # Checks if the given object matches any of the constraints.
    #
    # For each constraint, if the constraint does not have a property, the
    # #does_not_match? method on the constraint is called with the object. If
    # the constraint has a property, then the #does_not_match? method is called
    # with the value of that property on the given object.
    #
    # This method returns true only if none of the constraints match the given
    # object. An object which satisfies some, but not all of the constraints
    # will fail on both #matches? and #does_not_match? calls.
    #
    # @param object [Object] The object to match against the constraints.
    #
    # @return [true, false] true if none of the constraints match the given
    #   object; otherwise false.
    #
    # @example With A Contract With Constraints
    #   # With a nil (non-Numeric) object.
    #   contract.does_not_match?(nil)  #=> true
    #
    #   # With a non-Integer numeric object.
    #   contract.does_not_match?(11.5) #=> false
    #
    #   # With an Integer outside the range.
    #   contract.does_not_match?(11)   #=> false
    #
    #   # With an Integer in the range.
    #   contract.does_not_match?(10)   #=> false
    #
    # @example With A Contract With Property Constraints
    #   # With a non-Widget object.
    #   property_contract.does_not_match?(nil) #=> true
    #
    #   # With a Widget with non-matching properties.
    #   property_contract.does_not_match?(Widget.new) #=> false
    #
    #   # With a Widget with matching properties.
    #   factory      = Factory.new('123 Example Street')
    #   manufacturer = Manufacturer.new(factory)
    #   widget       = Widget.new('Self-sealing Stem Bolt', manufacturer)
    #   property_contract.does_not_match?(widget) #=> false
    #
    # @see #matches?
    # @see #negated_errors_for
    def does_not_match?(object)
      return true if constraints_empty?

      each_constraint.all? do |constraint|
        value = access_nested_property(object, constraint.fetch(:property))

        constraint.fetch(:constraint).does_not_match?(value)
      end
    end

    # Include the constraints from the given other contract.
    #
    # Merges the constraints from the included contract into the original. This
    # is a dynamic process - if constraints are added to the included contract
    # at a later point, they will also be added to the original. This is also
    # recursive - including a contract will also merge the constraints from any
    # contracts that were themselves included in the included contract.
    #
    # There are two approaches for adding one contract to another. The first and
    # simplest is to take advantage of the fact that each contract is, itself, a
    # constraint. Adding the new contract to the original via #add_constraint
    # works in most cases - the new contract will be called during #matches? and
    # when generating errors. However, functionality that inspects the
    # constraints directly (such as the :allow_extra_keys functionality in
    # HashContract) will fail.
    #
    # Including a contract in another is a much closer relationship. Each time
    # the constraints on the original contract are enumerated, it will also
    # yield the constraints from the included contract (and from any contracts
    # that are included in that contract, recursively).
    #
    # To sum up, use #add_constraint when you want to constrain a property of
    # the actual object with a contract. Use #include when you want to add more
    # constraints about the object itself.
    #
    # @example Including A Contract
    #   included_contract = Stannum::Contract.new
    #     .add_constraint(Stannum::Constraint.new { |int| int < 10 })
    #
    #   original_contract = Stannum::Contract.new
    #     .add_constraint(Stannum::Constraint.new { |int| int >= 0 })
    #     .include(included_contract)
    #
    #   original_contract.matches?(-1) #=> a failing result
    #   original_contract.matches?(0)  #=> a passing result
    #   original_contract.matches?(5)  #=> a passing result
    #   original_contract.matches?(10) #=> a failing result
    #
    # @param contract [Stannum::Contract] the other contract.
    #
    # @return [Stannum::Contract] the original contract.
    #
    # @see #add_constraint
    def include(contract)
      validate_contract(contract)

      @included << contract

      self
    end

    # Checks if the given object matches all of the constraints.
    #
    # For each constraint, if the constraint does not have a property, the
    # #matches? method on the constraint is called with the object. If the
    # constraint has a property, then the #matches? method is called with the
    # value of that property on the given object.
    #
    # This method returns true only if all of the constraints match the given
    # object. An object which satisfies some, but not all of the constraints
    # will fail on both #matches? and #does_not_match? calls.
    #
    # @param object [Object] The object to match against the constraints.
    #
    # @return [true, false] true if all of the constraints match the given
    #   object; otherwise false.
    #
    # @example With A Contract With Constraints
    #   # With a nil (non-Numeric) object.
    #   contract.matches?(nil)  #=> false
    #
    #   # With a non-Integer numeric object.
    #   contract.matches?(11.5) #=> false
    #
    #   # With an Integer outside the range.
    #   contract.matches?(11)   #=> false
    #
    #   # With an Integer in the range.
    #   contract.matches?(10)   #=> true
    #
    # @example With A Contract With Property Constraints
    #   # With a non-Widget object.
    #   property_contract.matches?(nil) #=> false
    #
    #   # With a Widget with non-matching properties.
    #   property_contract.matches?(Widget.new) #=> false
    #
    #   # With a Widget with matching properties.
    #   factory      = Factory.new('123 Example Street')
    #   manufacturer = Manufacturer.new(factory)
    #   widget       = Widget.new('Self-sealing Stem Bolt', manufacturer)
    #   property_contract.matches?(widget) #=> true
    #
    # @see #does_not_match?
    # @see #errors_for
    def matches?(object)
      return true if constraints_empty?

      each_constraint.all? do |constraint|
        value = access_nested_property(object, constraint.fetch(:property))

        constraint.fetch(:constraint).matches?(value)
      end
    end
    alias match? matches?

    protected

    def access_nested_property(object, property)
      Array(property).reduce(object) { |obj, prop| access_property(obj, prop) }
    end

    def access_property(object, property)
      object.send(property) if object.respond_to?(property, true)
    end

    def constraints_empty?
      return false unless @constraints.empty?

      @included.all? do |included_contract|
        included_contract.send :constraints_empty?
      end
    end

    def each_constraint
      return enum_for(:each_constraint) unless block_given?

      @constraints.each { |item| yield item }

      @included.each do |contract|
        contract.each_constraint { |item| yield item }
      end
    end

    def each_included
      return enum_for(:each_included) unless block_given?

      @included.each do |contract|
        yield contract

        contract.each_included { |inner| yield inner }
      end
    end

    def errors_for_constraint(
      actual:,
      constraint:,
      errors:,
      property:,
      **_keywords
    )
      value = access_nested_property(actual, property)

      return if constraint.matches?(value)

      scoped = property.nil? ? errors : errors.dig(property)

      constraint.send(:update_errors_for, actual: value, errors: scoped)
    end

    def negated_errors_for_constraint(
      actual:,
      constraint:,
      errors:,
      property:,
      **_keywords
    )
      value = access_nested_property(actual, property)

      return if constraint.does_not_match?(value)

      scoped = property.nil? ? errors : errors.dig(property)

      constraint.send(:update_negated_errors_for, actual: value, errors: scoped)
    end

    def update_errors_for(actual:, errors:)
      return errors if constraints_empty?

      each_constraint do |hsh|
        errors_for_constraint(actual: actual, errors: errors, **hsh)
      end

      errors
    end

    def update_negated_errors_for(actual:, errors:)
      return errors if constraints_empty?

      each_constraint do |hsh|
        negated_errors_for_constraint(actual: actual, errors: errors, **hsh)
      end

      errors
    end

    private

    def constraints
      each_constraint.to_a
    end

    def included
      each_included.to_a
    end

    def validate_constraint(constraint)
      return if constraint.is_a?(Stannum::Constraints::Base)

      raise ArgumentError, 'must be an instance of Stannum::Constraints::Base'
    end

    def validate_contract(constraint)
      return if constraint.is_a?(Stannum::Contract)

      raise ArgumentError, 'must be an instance of Stannum::Contract'
    end
  end
end
