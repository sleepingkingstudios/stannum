# frozen_string_literal: true

require 'stannum/constraints/parameters/extra_arguments'
require 'stannum/contracts/parameters'
require 'stannum/support/coercion'

module Stannum::Contracts::Parameters
  # @api private
  #
  # An ArgumentsContract constrains the arguments given for a method.
  class ArgumentsContract < Stannum::Contracts::TupleContract
    # Value used when arguments array does not have a value for the given index.
    UNDEFINED = Object.new.freeze

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      super(allow_extra_items: false, **options)
    end

    # Adds an argument constraint to the contract.
    #
    # Generates an argument constraint based on the given type. If the type is
    # a constraint, then the given constraint will be copied with the given
    # options and added for the argument at the index. If the type is a Class or
    # a Module, then a Stannum::Constraints::Type constraint will be created
    # with the given type and options and added for the argument.
    #
    # If the index is specified, then the constraint will be added for the
    # argument at the specified index. If the index is not given, then the
    # constraint will be applied to the next unconstrained argument. For
    # example, the first argument constraint will be added for the argument at
    # index 0, the second constraint for the argument at index 1, and so on.
    #
    # @param index [Integer, nil] The index of the argument. If not given, then
    #   the next argument will be constrained with the type.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the argument.
    # @param default [Boolean] If true, the argument has a default value, and
    #   the constraint will ignore arguments with no value at that index.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @return [Stannum::Contracts::Parameters::ArgumentsContract] the contract.
    def add_argument_constraint(index, type, default: false, **options)
      index    ||= next_index
      constraint = Stannum::Support::Coercion.type_constraint(type, **options)

      add_index_constraint(index, constraint, default: !!default, **options)

      self
    end

    # Sets a constraint for the variadic arguments.
    #
    # The given constraint must match the variadic arguments array as a whole.
    # To constraint each individual item, use #set_variadic_item_constraint.
    #
    # @param constraint [Stannum::Constraints::Base] The constraint to add.
    #   The variadic arguments (an array) as a whole must match the given
    #   constraint.
    # @param as [Symbol] A human-friendly reference for the additional
    #   arguments. Used when generating errors. Should be the same name used in
    #   the method definition.
    #
    # @return [self] the contract.
    #
    # @raise [RuntimeError] if the variadic arguments constraint is already set.
    #
    # @see #set_variadic_item_constraint
    def set_variadic_constraint(constraint, as: nil)
      raise 'variadic arguments constraint is already set' if allow_extra_items?

      options[:allow_extra_items] = true

      variadic_constraint.receiver = constraint

      variadic_definition.options[:property_name] = as if as

      self
    end

    # Sets a constraint for the variadic argument items.
    #
    # The given type or constraint must individually match each item (if any) in
    # the variadic arguments. To constrain the variadic arguments as a whole,
    # use #set_variadic_constraint.
    #
    # @param item_type [Stannum::Constraints::Base, Class, Module] The type or
    #   constraint to add. If the type is a Class or Module, then it is
    #   converted to a Stannum::Constraints::Type. Each item in the variadic
    #   arguments must match the given constraint.
    # @param as [Symbol] A human-friendly reference for the additional
    #   arguments. Used when generating errors. Should be the same name used in
    #   the method definition.
    #
    # @return [self] the contract.
    #
    # @raise [RuntimeError] if the variadic arguments constraint is already set.
    #
    # @see #set_variadic_constraint
    def set_variadic_item_constraint(item_type, as: nil)
      type       = coerce_item_type(item_type)
      constraint = Stannum::Constraints::Types::ArrayType.new(item_type: type)

      set_variadic_constraint(constraint, as: as)
    end

    protected

    def add_errors_for(definition, value, errors)
      return super unless value == UNDEFINED

      super(definition, nil, errors)
    end

    def add_negated_errors_for(definition, value, errors)
      return super unless value == UNDEFINED

      super(definition, nil, errors)
    end

    def map_value(actual, **options)
      return super unless options[:property_type] == :index

      return super unless actual.is_a?(Array)

      return super if options[:property] < actual.size

      UNDEFINED
    end

    def match_constraint(definition, value)
      return super unless value == UNDEFINED

      definition.options[:default] ? true : super(definition, nil)
    end

    def match_negated_constraint(definition, value)
      return super unless value == UNDEFINED

      definition.options[:default] ? false : super(definition, nil)
    end

    private

    attr_reader :variadic_constraint

    attr_reader :variadic_definition

    def add_extra_items_constraint
      count = -> { expected_count }

      @variadic_constraint = Stannum::Constraints::Delegator.new(
        Stannum::Constraints::Parameters::ExtraArguments.new(count)
      )

      add_constraint @variadic_constraint

      @variadic_definition = @constraints.last
    end

    def coerce_item_type(item_type)
      Stannum::Support::Coercion.type_constraint(item_type, as: 'item type')
    end

    def next_index
      index = -1

      each_constraint do |definition|
        next unless definition.options[:property_type] == :index
        next unless definition.property.is_a?(Integer)

        index = definition.property if definition.property > index
      end

      1 + index
    end
  end
end
