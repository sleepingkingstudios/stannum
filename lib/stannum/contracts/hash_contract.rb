# frozen_string_literal: true

require 'stannum/contracts'
require 'stannum/contracts/map_contract'
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
  class HashContract < Stannum::Contracts::MapContract
    # @param allow_extra_keys [true, false] If true, the contract will match
    #   hashes with keys that are not constrained by the contract.
    # @param key_type [Stannum::Constraints::Base, Class, nil] If set, then the
    #   constraint will check the types of each key in the Hash against the
    #   expected type and will fail if any keys do not match.
    # @param value_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each value in the Hash against
    #   the expected type and will fail if any values do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(
      allow_extra_keys: false,
      key_type:         nil,
      value_type:       nil,
      **options,
      &block
    )
      super(
        allow_extra_keys: allow_extra_keys,
        key_type:         key_type,
        value_type:       value_type,
        **options,
        &block
      )
    end

    # @return [Stannum::Constraints::Base, Class, nil] the expected type for the
    #   keys in the Hash, if any.
    def key_type
      options[:key_type]
    end

    # @return [Stannum::Constraints::Base, Class, nil] the expected type for the
    #   values in the Hash, if any.
    def value_type
      options[:value_type]
    end

    private

    def add_type_constraint
      add_constraint(
        Stannum::Constraints::Types::HashType.new(
          key_type:   key_type,
          value_type: value_type
        ),
        sanity: true
      )
    end
  end
end
