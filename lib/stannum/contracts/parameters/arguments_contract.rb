# frozen_string_literal: true

require 'stannum/contracts/parameters'
require 'stannum/support/coercion'

module Stannum::Contracts::Parameters
  # @api private
  #
  # An ArgumentsContract constrains the arguments given for a method.
  class ArgumentsContract < Stannum::Contracts::TupleContract
    # The :type of the error generated for extra arguments.
    EXTRA_ARGUMENTS_TYPE = 'stannum.constraints.parameters.extra_arguments'

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      super(allow_extra_items: false, **options)
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
      constraint = Stannum::Constraints::Types::Array.new(item_type: type)

      set_variadic_constraint(constraint, as: as)
    end

    private

    attr_reader :variadic_constraint

    attr_reader :variadic_definition

    def add_extra_items_constraint
      count = -> { expected_count }

      @variadic_constraint = Stannum::Constraints::Delegator.new(
        Stannum::Constraints::Tuples::ExtraItems.new(
          count,
          type: EXTRA_ARGUMENTS_TYPE
        )
      )

      add_constraint @variadic_constraint

      @variadic_definition = @constraints.last
    end

    def coerce_item_type(item_type)
      Stannum::Support::Coercion.type_constraint(item_type, as: 'item type')
    end
  end
end
