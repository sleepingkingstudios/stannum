# frozen_string_literal: true

require 'stannum/contracts/parameters'

module Stannum::Contracts::Parameters
  # @api private
  #
  # A KeywordsContract constrains the keywords given for a method.
  class KeywordsContract < Stannum::Contracts::HashContract
    # The :type of the error generated for extra keywords.
    EXTRA_KEYWORDS_TYPE = 'stannum.constraints.parameters.extra_keywords'

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      super(
        allow_extra_keys: false,
        allow_hash_like:  false,
        key_type:         Stannum::Constraints::Hashes::IndifferentKey.new,
        **options
      )
    end

    # Sets a constraint for the variadic keywords.
    #
    # The given constraint must match the variadic keywords hash as a whole.
    # To constraint each individual value, use #set_variadic_value_constraint.
    #
    # @param type [Stannum::Constraints::Base] The constraint constraint to add.
    #   The variadic keywords (a hash) as a whole must match the given
    #   constraint.
    # @param as [Symbol] A human-friendly reference for the additional
    #   keywords. Used when generating errors. Should be the same name used in
    #   the method definition.
    #
    # @return [self] the contract.
    #
    # @raise [RuntimeError] if the variadic keywords constraint is already set.
    #
    # @see #set_variadic_item_constraint
    def set_variadic_constraint(constraint, as: nil)
      raise 'variadic keywords constraint is already set' if allow_extra_keys?

      options[:allow_extra_keys] = true

      variadic_constraint.receiver = constraint

      variadic_definition.options[:property_name] = as if as

      self
    end

    # Sets a constraint for the variadic keyword values.
    #
    # The given type or constraint must individually match each value (if any)
    # in the variadic keywords. To constrain the variadic keywords as a whole,
    # use #set_variadic_constraint.
    #
    # @param type [Stannum::Constraints::Base, Class, Module] The type or
    #   constraint to add. If the type is a Class or Module, then it is
    #   converted to a Stannum::Constraints::Type. Each value in the variadic
    #   keywords must match the given constraint.
    # @param as [Symbol] A human-friendly reference for the additional
    #   keywords. Used when generating errors. Should be the same name used in
    #   the method definition.
    #
    # @return [self] the contract.
    #
    # @raise [RuntimeError] if the variadic keywords constraint is already set.
    #
    # @see #set_variadic_constraint
    def set_variadic_value_constraint(value_type, as: nil)
      type       = coerce_value_type(value_type)
      constraint = Stannum::Constraints::Types::Hash.new(
        key_type:   Stannum::Constraints::Types::Symbol.new,
        value_type: type
      )

      set_variadic_constraint(constraint, as: as)
    end

    private

    attr_reader :variadic_constraint

    attr_reader :variadic_definition

    def add_extra_keys_constraint
      keys = -> { expected_keys }

      @variadic_constraint = Stannum::Constraints::Delegator.new(
        Stannum::Constraints::Hashes::ExtraKeys.new(
          keys,
          type: EXTRA_KEYWORDS_TYPE
        )
      )

      add_constraint @variadic_constraint

      @variadic_definition = @constraints.last
    end

    def coerce_value_type(value_type)
      Stannum::Support::Coercion.type_constraint(value_type, as: 'value type')
    end
  end
end
