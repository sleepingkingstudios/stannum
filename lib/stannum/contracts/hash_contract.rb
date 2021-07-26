# frozen_string_literal: true

require 'stannum/contracts'
require 'stannum/support/coercion'

module Stannum::Contracts
  # A HashContract defines constraints on an hash's values.
  #
  # @example Creating A Hash Contract
  #   hash_contract = Stannum::Contracts::HashContract.new
  #
  #   hash_contract.add_constraint(
  #     negated_type:  'example.is_boolean',
  #     property:      :ok,
  #     property_type: :key,
  #     type:          'example.is_not_boolean'
  #   ) { |actual| actual == true || actual == false }
  #   hash_contract.add_constraint(
  #     Stannum::Constraints::Type.new(Hash),
  #     property:      :data,
  #     property_type: :key,
  #   )
  #   hash_contract.add_constraint(
  #     Stannum::Constraints::Presence.new,
  #     property:      :signature,
  #     property_type: :key,
  #   )
  #
  # @example With A Non-Hash Object
  #   hash_contract.matches?(nil) #=> false
  #   errors = hash_contract.errors_for(nil)
  #   #=> [{ type: 'is_not_type', data: { type: Hash }, path: [], message: nil }]
  #
  #   hash_contract.does_not_match?(nil)          #=> true
  #   hash_contract.negated_errors_for?(nil).to_a #=> []
  #
  # @example With A Hash That Matches None Of The Key Constraints
  #   hash_contract.matches?({}) #=> false
  #   errors = hash_contract.errors_for({})
  #   errors.to_a
  #   #=> [
  #     { type: 'is_not_boolean', data: {}, path: [:ok], message: nil },
  #     { type: 'is_not_type', data: { type: Hash }, path: [:data], message: nil },
  #     { type: 'absent', data: {}, path: [:signature], message: nil }
  #   ]
  #
  #   hash_contract.does_not_match?({}) #=> false
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Hash }, path: [], message: nil }
  #   ]
  #
  # @example With A Hash That Matches Some Of The Key Constraints
  #   hash = { ok: true, signature: '' }
  #   hash_contract.matches?(hash) #=> false
  #   errors = hash_contract.errors_for(hash)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_not_type', data: { type: Hash }, path: [:data], message: nil },
  #     { type: 'absent', data: {}, path: [:signature], message: nil }
  #   ]
  #
  #   hash_contract.does_not_match?(hash) #=> false
  #   errors = hash_contract.negated_errors_for?(hash)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Hash }, path: [], message: nil },
  #     { type: 'is_boolean', data: {}, path: [:ok], message: nil }
  #   ]
  #
  # @example With A Hash That Matches All Of The Key Constraints
  #   hash = { ok: true, data: {}, signature: 'abc' }
  #   hash_contract.matches?(hash)        #=> true
  #   hash_contract.errors_for(hash).to_a #=> []
  #
  #   hash_contract.does_not_match?(hash) #=> false
  #   errors = hash_contract.negated_errors_for?(hash)
  #   errors.to_a
  #   #=> [
  #     { type: 'is_type', data: { type: Hash }, path: [], message: nil },
  #     { type: 'is_boolean', data: {}, path: [:ok], message: nil },
  #     { type: 'present', data: {}, path: [:signature], message: nil },
  #   ]
  class HashContract < Stannum::Contracts::PropertyContract
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
    # @param allow_hash_like [true, false] If true, the contract will match
    #   hash-like objects that respond to the #[], #each, and #keys methods.
    # @param key_type [Stannum::Constraints::Base, Class, nil] If set, adding
    #   a key constraint with a key that does not match the class or constraint
    #   will raise an exception.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(
      allow_extra_keys: false,
      allow_hash_like:  false,
      key_type:         nil,
      **options,
      &block
    )
      super(
        allow_extra_keys: allow_extra_keys,
        allow_hash_like:  allow_hash_like,
        key_type:         coerce_key_type(key_type),
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

    # (see Stannum::Contracts::Base#each_constraint)
    def each_constraint
      return enum_for(:each_constraint) unless block_given?

      super do |definition|
        # Extra keys should be handled only by the top-level constraint;
        # otherwise, an included HashContract with a subset of the expected keys
        # would cause a false negative.
        if definition.constraint.is_a?(Stannum::Constraints::Hashes::ExtraKeys)
          next unless equal?(definition.contract)
        end

        yield definition
      end
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
      if options[:allow_hash_like]
        add_constraint Stannum::Constraints::Signatures::Map.new, sanity: true
      else
        add_constraint Stannum::Constraints::Types::HashType.new, sanity: true
      end
    end

    def coerce_key_type(key_type)
      Stannum::Support::Coercion.type_constraint(
        key_type,
        allow_nil: true,
        as:        'key type'
      )
    end

    def define_constraints(&block)
      add_type_constraint

      add_extra_keys_constraint

      super
    end

    def key_type
      options[:key_type]
    end

    def key_type?
      !options[:key_type].nil?
    end

    def valid_property?(property: nil, property_type: nil, **_options)
      return super unless property_type == :key

      key_type.matches?(property)
    end

    def validate_property?(**options)
      return super unless options[:property_type] == :key

      key_type?
    end
  end
end
