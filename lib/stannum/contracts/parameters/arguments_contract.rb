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
    # @param type [Stannum::Constraints::Base, Class, Module] The type or
    #   constraint to add. If a constraint, the variadic arguments (if any) must
    #   match the constraint. If the type is a Class or Module, then the
    #   constraint is an Types::Array constraint with item_type: the given type,
    #   and each item in the variadic arguments must match the given type.
    #
    # @return [self] the contract.
    #
    # @raise [RuntimeError] if the variadic arguments constraint is already set.
    def set_variadic_constraint(type) # rubocop:disable Naming/AccessorMethodName
      raise 'variadic arguments constraint is already set' if allow_extra_items?

      options[:allow_extra_items] = true

      variadic_constraint.receiver = coerce_item_type(type)

      self
    end

    private

    attr_reader :variadic_constraint

    def add_extra_items_constraint
      count = -> { expected_count }

      @variadic_constraint = Stannum::Constraints::Delegator.new(
        Stannum::Constraints::Tuples::ExtraItems.new(
          count,
          type: EXTRA_ARGUMENTS_TYPE
        )
      )

      add_constraint @variadic_constraint
    end

    def coerce_item_type(item_type)
      Stannum::Support::Coercion.type_constraint(item_type, as: 'item type') \
      do |value, **options|
        Stannum::Constraints::Types::Array.new(
          item_type: Stannum::Constraints::Type.new(value),
          **options
        )
      end
    end
  end
end
