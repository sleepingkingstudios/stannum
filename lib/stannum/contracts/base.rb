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
  #
  # @example Creating A Contract With A Sanity Constraint
  #   format_constraint =
  #     Stannum::Constraint.new(type: 'invalid_format', negated_type: 'valid_format') do |actual|
  #       actual =~ /\A0x[0-9A-Fa-f]*\z/
  #     end
  #   length_constraint =
  #     Stannum::Constraint.new(type: 'invalid_length', negated_type: 'valid_length') do |actual|
  #       actual.length > 2
  #     end
  #   string_constraint = Stannum::Constraints::Type.new(String)
  #   contract =
  #     Stannum::Contracts::Base.new
  #     .add_constraint(string_constraint, sanity: true)
  #     .add_constraint(format_constraint)
  #     .add_constraint(length_constraint)
  #
  # @example With An Object That Does Not Match The Sanity Constraint
  #   contract.matches?(nil) #=> false
  #   errors = contract.errors_for(nil) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> [
  #     {
  #       data:    { type: String},
  #       message: nil,
  #       path:    [],
  #       type:    'stannum.constraints.is_not_type'
  #     }
  #   ]
  #
  #   contract.does_not_match?(nil) #=> true
  #   errors = contract.negated_errors_for(nil) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> []
  class Base < Stannum::Constraints::Base # rubocop:disable Metrics/ClassLength
    STOP_ITERATION = Object.new.freeze
    private_constant :STOP_ITERATION

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options, &block)
      @constraints = []
      @included    = []

      super(**options)

      define_constraints(&block)
    end

    # Performs an equality comparison.
    #
    # @param other [Object] The object to compare.
    #
    # @return [true, false] true if the other object has the same class,
    #   options, and constraints; otherwise false.
    def ==(other)
      super && equal_definitions?(other)
    end

    # @!method errors_for(actual)
    #   Aggregates errors for each constraint that does not match the object.
    #
    #   For each defined constraint, the constraint is matched against the
    #   mapped value for that constraint and the object. If the constraint does
    #   not match the mapped value, the corresponding errors will be added to
    #   the errors object.
    #
    #   If the contract defines sanity constraints, the sanity constraints will
    #   be matched first. If any of the sanity constraints fail, #errors_for
    #   will immediately return the errors for the failed constraint.
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
    #   If the contract defines sanity constraints, the sanity constraints will
    #   be matched first. If any of the sanity constraints fail, #errors_for
    #   will immediately return any errors already added to the errors object.
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
    # @param sanity [true, false] Marks the constraint as a sanity constraint,
    #   which is always matched first and will always short-circuit on a failed
    #   match.
    # @param options [Hash<Symbol, Object>] Options for the constraint. These
    #   can be used by subclasses to define the value and error mappings for the
    #   constraint.
    #
    # @return [self] the contract.
    def add_constraint(constraint, sanity: false, **options)
      validate_constraint(constraint)

      @constraints << Stannum::Contracts::Definition.new(
        constraint: constraint,
        contract:   self,
        options:    options.merge(sanity: sanity)
      )

      self
    end

    # Checks that none of the added constraints match the object.
    #
    # If the contract defines sanity constraints, the sanity constraints will be
    # matched first. If any of the sanity constraints fail (#does_not_match?
    # for the constraint returns true), then this method will immediately return
    # true and all subsequent constraints will be skipped.
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
        if definition.contract.match_negated_constraint(definition, value)
          next unless definition.sanity?

          return true
        end

        return false
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
    # If the contract defines sanity constraints, the sanity constraints will be
    # returned or yielded first, followed by the remaining constraints.
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

      each_unscoped_constraint do |definition|
        yield definition if definition.sanity?
      end

      each_unscoped_constraint do |definition|
        yield definition unless definition.sanity?
      end
    end

    # Iterates through the constraints and mapped values.
    #
    # For each constraint defined for the contract, the contract defines a data
    # mapping representing the object or property that the constraint will
    # match. Calling #each_pair for an object yields the constraint and the
    # mapped object or property for that constraint and object.
    #
    # If the contract defines sanity constraints, the sanity constraints will be
    # returned or yielded first, followed by the remaining constraints.
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
    # If the contract defines sanity constraints, the sanity constraints will be
    # matched first. If any of the sanity constraints fail (#matches? for the
    # constraint returns false), then this method will immediately return
    # false and the errors for the failed sanity constraint; and all subsequent
    # constraints will be skipped.
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
        next if definition.contract.match_constraint(definition, value)

        status = false

        definition.contract.send(:add_errors_for, definition, value, errors)

        return [status, errors] if definition.sanity?
      end

      [status, errors]
    end

    # Checks that all of the added constraints match the object.
    #
    # If the contract defines sanity constraints, the sanity constraints will be
    # matched first. If any of the sanity constraints fail (#does_not_match?
    # for the constraint returns true), then this method will immediately return
    # false and all subsequent constraints will be skipped.
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
        unless definition.contract.match_constraint(definition, value)
          return false
        end
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
    # If the contract defines sanity constraints, the sanity constraints will be
    # matched first. If any of the sanity constraints fail (#does_not_match?
    # for the constraint returns true), then this method will immediately return
    # true and any errors already set; and all subsequent constraints will be
    # skipped.
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
    def negated_match(actual) # rubocop:disable Metrics/MethodLength
      status = true
      errors = Stannum::Errors.new

      each_pair(actual) do |definition, value|
        if definition.contract.match_negated_constraint(definition, value)
          next unless definition.sanity?

          return [true, errors]
        end

        status = false

        definition.contract.add_negated_errors_for(definition, value, errors)
      end

      [status, errors]
    end

    protected

    attr_accessor :constraints

    attr_accessor :included

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

    def copy_properties(source, options: nil, **_)
      super

      self.constraints = source.constraints.dup
      self.included    = source.included.dup

      self
    end

    def each_unscoped_constraint
      return enum_for(:each_unscoped_constraint) unless block_given?

      each_included_contract do |contract|
        contract.each_constraint { |definition| yield definition }
      end

      @constraints.each { |definition| yield definition }
    end

    def match_constraint(definition, value)
      definition.constraint.matches?(value)
    end

    def match_negated_constraint(definition, value)
      definition.constraint.does_not_match?(value)
    end

    def map_errors(errors, **_options)
      errors
    end

    def map_value(actual, **_options)
      actual
    end

    private

    def define_constraints(&block)
      self.class::Builder.new(self).instance_exec(&block) if block_given?
    end

    def each_included_contract
      return enum_for(:each_included_contract) unless block_given?

      @included.each { |contract| yield contract }
    end

    def equal_definitions?(other) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      own_defns   = each_unscoped_constraint
      other_defns = other.each_unscoped_constraint

      loop do
        # rubocop:disable Layout/EmptyLinesAroundExceptionHandlingKeywords, Lint/RedundantCopDisableDirective
        u = begin; own_defns.next;   rescue StopIteration; STOP_ITERATION; end
        v = begin; other_defns.next; rescue StopIteration; STOP_ITERATION; end
        # rubocop:enable Layout/EmptyLinesAroundExceptionHandlingKeywords, Lint/RedundantCopDisableDirective

        return true if u == STOP_ITERATION && v == STOP_ITERATION

        return false if u == STOP_ITERATION || v == STOP_ITERATION

        unless u.constraint == v.constraint && u.options == v.options
          return false
        end
      end
    end

    def update_errors_for(actual:, errors:)
      each_pair(actual) do |definition, value|
        next if match_constraint(definition, value)

        definition.contract.add_errors_for(definition, value, errors)

        return errors if definition.sanity?
      end

      errors
    end

    def update_negated_errors_for(actual:, errors:)
      each_pair(actual) do |definition, value|
        if match_negated_constraint(definition, value)
          next unless definition.sanity?

          return errors
        end

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
