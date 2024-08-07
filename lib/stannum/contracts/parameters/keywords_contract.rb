# frozen_string_literal: true

require 'stannum/constraints/parameters/extra_keywords'
require 'stannum/contracts/indifferent_hash_contract'
require 'stannum/contracts/parameters'

module Stannum::Contracts::Parameters
  # @api private
  #
  # A KeywordsContract constrains the keywords given for a method.
  class KeywordsContract < Stannum::Contracts::IndifferentHashContract
    # Value used when keywords hash does not have a value for the given key.
    UNDEFINED = Object.new.freeze

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      super(
        allow_extra_keys: false,
        **options
      )
    end

    # Adds a keyword constraint to the contract.
    #
    # Generates a keyword constraint based on the given type. If the type is
    # a constraint, then the given constraint will be copied with the given
    # options and added for the given keyword. If the type is a Class or a
    # Module, then a Stannum::Constraints::Type constraint will be created with
    # the given type and options and added for the keyword.
    #
    # @param keyword [Symbol] The keyword to constrain.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the argument.
    # @param default [Boolean] If true, the keyword has a default value, and
    #   the constraint will ignore keywords with no value at that key.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @return [Stannum::Contracts::Parameters::KeywordsContract] the contract.
    def add_keyword_constraint(keyword, type, default: false, **options)
      unless keyword.is_a?(Symbol)
        raise ArgumentError, 'keyword must be a symbol'
      end

      constraint = Stannum::Support::Coercion.type_constraint(type, **options)

      add_key_constraint(keyword, constraint, default: !!default, **options)

      self
    end

    # Sets a constraint for the variadic keywords.
    #
    # The given constraint must match the variadic keywords hash as a whole.
    # To constraint each individual value, use #set_variadic_value_constraint.
    #
    # @param constraint [Stannum::Constraints::Base] The constraint to add.
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
    # @param value_type [Stannum::Constraints::Base, Class, Module] The type or
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
      constraint = Stannum::Constraints::Types::HashType.new(
        key_type:   Stannum::Constraints::Types::SymbolType.new,
        value_type: type
      )

      set_variadic_constraint(constraint, as:)
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
      return super unless options[:property_type] == :key

      return super unless actual.is_a?(Hash)

      return super if actual.key?(options[:property])

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

    def add_extra_keys_constraint
      keys = -> { expected_keys }

      @variadic_constraint = Stannum::Constraints::Delegator.new(
        Stannum::Constraints::Parameters::ExtraKeywords.new(keys)
      )

      add_constraint @variadic_constraint

      @variadic_definition = @constraints.last
    end

    def coerce_value_type(value_type)
      Stannum::Support::Coercion.type_constraint(value_type, as: 'value type')
    end
  end
end
