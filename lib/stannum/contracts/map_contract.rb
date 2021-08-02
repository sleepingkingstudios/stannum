# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # A MapContract defines constraints on an hash-like object's values.
  #
  # @example Creating A Map Contract
  #   Response     = Struct.new(:ok, :data, :signature)
  #   map_contract = Stannum::Contracts::MapContract.new
  #
  #   map_contract.add_constraint(
  #     negated_type:  'example.is_boolean',
  #     property:      :ok,
  #     property_type: :key,
  #     type:          'example.is_not_boolean'
  #   ) { |actual| actual == true || actual == false }
  #   map_contract.add_constraint(
  #     Stannum::Constraints::Type.new(Hash),
  #     property:      :data,
  #     property_type: :key,
  #   )
  #   map_contract.add_constraint(
  #     Stannum::Constraints::Presence.new,
  #     property:      :signature,
  #     property_type: :key,
  #   )
  #
  # @example With A Non-Map Object
  #   map_contract.matches?(nil) #=> false
  #   errors = map_contract.errors_for(nil)
  #   #=> [
  #     {
  #       type:    'stannum.constraints.does_not_have_methods',
  #       data:    { methods: [:[], :each, :keys], missing: [:[], :each, :keys] },
  #       message: nil,
  #       path:    []
  #     }
  #   ]
  #   map_contract.does_not_match?(nil)          #=> true
  #   map_contract.negated_errors_for?(nil).to_a #=> []
  #
  # @example With An Object That Matches None Of The Key Constraints
  #   response = Response.new
  #   map_contract.matches?(response) #=> false
  #   errors = map_contract.errors_for(response)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_not_boolean', data: {}, path: [:ok], message: nil },
  #     { type: 'is_not_type', data: { type: Hash }, path: [:data], message: nil },
  #     { type: 'absent', data: {}, path: [:signature], message: nil }
  #   ]
  #
  # @example With An Object That Matches Some Of The Key Constraints
  #   response = Response.new(true, nil, '')
  #   map_contract.matches?(response) #=> false
  #   errors = map_contract.errors_for(response)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_not_type', data: { type: Hash }, path: [:data], message: nil },
  #     { type: 'absent', data: {}, path: [:signature], message: nil }
  #   ]
  #
  # @example With An Object That Matches All Of The Key Constraints
  #   response = Response.new(true, {}, 'abc')
  #   hash_contract.matches?(response)        #=> true
  #   hash_contract.errors_for(response).to_a #=> []
  class MapContract < Stannum::Contracts::PropertyContract
    # Builder class for defining item constraints for a Contract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for HashContract.
    #
    # @api private
    class Builder < Stannum::Contracts::PropertyContract::Builder
      # Defines a key constraint on the contract.
      #
      # @overload key(key, constraint, **options)
      #   Adds the given constraint to the contract for the value at the given
      #   key.
      #
      #   @param key [String, Symbol, Array<String, Symbol>] The key to
      #     constrain.
      #   @param constraint [Stannum::Constraint::Base] The constraint to add.
      #   @param options [Hash<Symbol, Object>] Options for the constraint.
      #
      # @overload key(**options) { |value| }
      #   Creates a new Stannum::Constraint object with the given block, and
      #   adds that constraint to the contract for the value at the given key.
      def key(property, constraint = nil, **options, &block)
        self.constraint(
          constraint,
          property:      property,
          property_type: :key,
          **options,
          &block
        )
      end
    end

    # @param allow_extra_keys [true, false] If true, the contract will match
    #   hashes with keys that are not constrained by the contract.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(
      allow_extra_keys: false,
      **options,
      &block
    )
      super(
        allow_extra_keys: allow_extra_keys,
        **options,
        &block
      )
    end

    # Adds a key constraint to the contract.
    #
    # When the contract is called, the contract will find the value of the
    # object for the given key.
    #
    # @param key [Integer] The key of the value to match.
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
    # @see Stannum::Contracts::PropertyContract#add_constraint.
    def add_key_constraint(key, constraint, sanity: false, **options)
      add_constraint(
        constraint,
        property:      key,
        property_type: :key,
        sanity:        sanity,
        **options
      )
    end

    # @return [true, false] if true, the contract will match hashes with keys
    #   that are not constrained by the contract.
    def allow_extra_keys?
      options[:allow_extra_keys]
    end

    # @return [Array] the list of keys expected by the key constraints.
    def expected_keys
      each_constraint.reduce([]) do |keys, definition|
        next keys unless definition.options[:property_type] == :key

        keys << definition.options.fetch(:property)
      end
    end

    # (see Stannum::Contracts::Base#with_options)
    def with_options(**options)
      return super unless options.key?(:allow_extra_keys)

      raise ArgumentError, "can't change option :allow_extra_keys"
    end

    protected

    def map_value(actual, **options)
      return super unless options[:property_type] == :key

      actual[options[:property]]
    end

    private

    def add_extra_keys_constraint
      return if options[:allow_extra_keys]

      keys = -> { expected_keys }

      add_constraint Stannum::Constraints::Hashes::ExtraKeys.new(keys)
    end

    def add_type_constraint
      add_constraint Stannum::Constraints::Signatures::Map.new, sanity: true
    end

    def define_constraints(&block)
      add_type_constraint

      add_extra_keys_constraint

      super
    end
  end
end
