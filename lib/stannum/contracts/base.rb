# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # A Contract aggregates constraints about the given object.
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
  #     Stannum::Contracts::Base.new
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
  class Base < Stannum::Constraints::Base # rubocop:disable Metrics/ClassLength
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      @constraints = []
      @included    = []

      super(**options)
    end

    # @!method errors_for(actual)
    #   Aggregates errors for each constraint that does not match the object.
    #
    #   For each defined constraint, the constraint is matched against the
    #   mapped value for that constraint and the object. If the constraint does
    #   not match the mapped value, the corresponding errors will be added to
    #   the errors object.
    #
    #   @param actual [Object] The object to match.
    #
    #   @return [Stannum::Errors] the generated errors object.
    #
    #   @see #each_pair
    #   @see #match
    #   @see #negated_errors_for

    # @!method negated_errors_for(actual)
    #   Aggregates errors for each constraint that matches the object.
    #
    #   For each defined constraint, the constraint is matched against the
    #   mapped value for that constraint and the object. If the constraint
    #   matches the mapped value, the corresponding errors will be added to
    #   the errors object.
    #
    #   @param actual [Object] The object to match.
    #
    #   @return [Stannum::Errors] the generated errors object.
    #
    #   @see #each_pair
    #   @see #errors_for
    #   @see #negated_match

    # Adds a constraint to the contract.
    #
    # When the contract is matched with an object, the constraint will be
    # evaluated with the object and the errors updated accordingly.
    #
    # @param constraint [Stannum::Constraints::Base] The constraint to add.
    #
    # @param options [Hash<Symbol, Object>] Options for the constraint. These
    #   can be used by subclasses to define the value and error mappings for the
    #   constraint.
    #
    # @return [self] the contract.
    def add_constraint(constraint, **options)
      validate_constraint(constraint)

      @constraints << Stannum::Contracts::Definition.new(
        constraint: constraint,
        contract:   self,
        options:    options
      )

      self
    end

    # Checks that none of the added constraints match the object.
    #
    # @param actual [Object] The object to match.
    #
    # @return [true, false] True if none of the constraints match the given
    #   object; otherwise false. If there are no constraints, returns true.
    #
    # @see #each_pair
    # @see #matches?
    # @see #negated_match
    def does_not_match?(actual)
      each_pair(actual) do |definition, value|
        return false unless definition.constraint.does_not_match?(value)
      end

      true
    end

    # Iterates through the constraints defined for the contract.
    #
    # Any constraints defined on included contracts are yielded, followed by any
    # constraints defined on the contract itself.
    #
    # Each constraint is represented as a Stannum::Contracts::Definition, which
    # encapsulates the constraint, the original contract, and the options
    # specified by #add_constraint.
    #
    # @overload each_constraint
    #   @return [Enumerator] An enumerator for the constraint definitions.
    #
    # @overload each_constraint
    #   @yieldparam definition [Stannum::Contracts::Definition] Each definition
    #     from the contract or included contracts.
    #
    # @see #each_pair
    # @see #include
    def each_constraint
      return enum_for(:each_constraint) unless block_given?

      @included.each do |contract|
        contract.each_constraint { |definition| yield definition }
      end

      @constraints.each { |definition| yield definition }
    end

    # Iterates through the constraints and mapped values.
    #
    # For each constraint defined for the contract, the contract defines a data
    # mapping representing the object or property that the constraint will
    # match. Calling #each_pair for an object yields the constraint and the
    # mapped object or property for that constraint and object.
    #
    # By default, this mapping returns the object itself; however, this can be
    # overriden in subclasses based on the constraint options, such as matching
    # constraints against the properties of an object rather than the object
    # itself.
    #
    # This enumerator is used internally to implement the Constraint interface
    # for subclasses of Contract.
    #
    # @param actual [Object] The object to match.
    #
    # @overload each_pair(actual)
    #   @return [Enumerator] An enumerator for the constraints and values.
    #
    # @overload each_pair(actual)
    #   @yieldparam definition [Stannum::Contracts::Definition] Each definition
    #     from the contract or included contracts.
    #   @yieldparam value [Object] The mapped value for that constraint.
    #
    # @see #each_constraint
    def each_pair(actual)
      return enum_for(:each_pair, actual) unless block_given?

      each_constraint do |definition|
        value = definition.contract.map_value(actual, **definition.options)

        yield definition, value
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
    # @param other [Stannum::Contract] the other contract.
    #
    # @return [Stannum::Contract] the original contract.
    #
    # @see #add_constraint
    def include(other)
      validate_contract(other)

      @included << other

      self
    end

    # Matches and generates errors for each constraint.
    #
    # For each defined constraint, the constraint is matched against the
    # mapped value for that constraint and the object. If the constraint does
    # not match the mapped value, the corresponding errors will be added to
    # the errors object.
    #
    # Finally, if all of the constraints match the mapped value, #match will
    # return true and the errors object. Otherwise, #match will return false and
    # the errors object.
    #
    # @param actual [Object] The object to match.
    #
    # @return [<Array(Boolean, Stannum::Errors)>] the status (true or false) and
    #   the generated errors object.
    #
    # @see #each_pair
    # @see #errors_for
    # @see #matches?
    # @see #negated_match
    def match(actual)
      status = true
      errors = Stannum::Errors.new

      each_pair(actual) do |definition, value|
        next if definition.constraint.matches?(value)

        status = false

        definition.contract.send(:add_errors_for, definition, value, errors)
      end

      [status, errors]
    end

    # Checks that all of the added constraints match the object.
    #
    # @param actual [Object] The object to match.
    #
    # @return [true, false] True if all of the constraints match the given
    #   object; otherwise false. If there are no constraints, returns true.
    #
    # @see #does_not_match?
    # @see #each_pair
    # @see #match
    def matches?(actual)
      each_pair(actual) do |definition, value|
        return false unless definition.constraint.matches?(value)
      end

      true
    end
    alias match? matches?

    # Matches and generates errors for each constraint.
    #
    # For each defined constraint, the constraint is matched against the
    # mapped value for that constraint and the object. If the constraint
    # matches the mapped value, the corresponding errors will be added to
    # the errors object.
    #
    # Finally, if none of the constraints match the mapped value, #match will
    # return true and the errors object. Otherwise, #match will return false and
    # the errors object.
    #
    # @param actual [Object] The object to match.
    #
    # @return [<Array(Boolean, Stannum::Errors)>] the status (true or false) and
    #   the generated errors object.
    #
    # @see #does_not_match?
    # @see #each_pair
    # @see #match
    # @see #negated_errors_for
    def negated_match(actual)
      status = true
      errors = Stannum::Errors.new

      each_pair(actual) do |definition, value|
        next if definition.constraint.does_not_match?(value)

        status = false

        definition.contract.add_negated_errors_for(definition, value, errors)
      end

      [status, errors]
    end

    protected

    def add_errors_for(definition, value, errors)
      definition
        .constraint
        .send(
          :update_errors_for,
          actual: value,
          errors: map_errors(errors, **definition.options)
        )
    end

    def add_negated_errors_for(definition, value, errors)
      definition
        .constraint
        .send(
          :update_negated_errors_for,
          actual: value,
          errors: map_errors(errors, **definition.options)
        )
    end

    def map_errors(errors, **_options)
      errors
    end

    def map_value(actual, **_options)
      actual
    end

    private

    def update_errors_for(actual:, errors:)
      each_pair(actual) do |definition, value|
        next if definition.constraint.matches?(value)

        definition.contract.add_errors_for(definition, value, errors)
      end

      errors
    end

    def update_negated_errors_for(actual:, errors:)
      each_pair(actual) do |definition, value|
        next if definition.constraint.does_not_match?(value)

        definition.contract.add_negated_errors_for(definition, value, errors)
      end

      errors
    end

    def validate_constraint(constraint)
      return if constraint.is_a?(Stannum::Constraints::Base)

      raise ArgumentError,
        'must be an instance of Stannum::Constraints::Base',
        caller(1..-1)
    end

    def validate_contract(constraint)
      return if constraint.is_a?(Stannum::Contracts::Base)

      raise ArgumentError,
        'must be an instance of Stannum::Contract',
        caller(1..-1)
    end
  end
end
