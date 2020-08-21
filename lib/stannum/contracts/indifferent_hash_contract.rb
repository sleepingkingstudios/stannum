# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # An IndifferentHashContract defines constraints on an hash's values.
  #
  # The keys for an IndifferentHashContract must be either strings or symbols.
  # The type of key is ignored when matching - a hash with a string key will
  # match an expected symbol key and vice versa.
  #
  # @example Creating An Indifferent Hash Contract
  #   hash_contract = Stannum::Contracts::HashContract.new
  #   hash_contract.add_constraint(
  #     Stannum::Constraints::Presence.new,
  #     property:      :data,
  #     property_type: :key,
  #   )
  #
  # @example With A Non-Hash Object
  #   hash_contract.matches?(nil) #=> false
  #   errors = hash_contract.errors_for(nil)
  #   #=> [{ type: 'is_not_type', data: { type: Hash }, path: [], message: nil }]
  #
  # @example With An Empty Hash
  #   hash_contract.matches?({}) #=> false
  #   errors = hash_contract.errors_for({})
  #   #=> [{ type: 'absent', data: {}, path: [:data], message: nil }]
  #
  # @example With A Hash With String Keys
  #   hash = { 'data' => {} }
  #   hash_contract.matches?(hash)   #=> true
  #   hash_contract.errors_for(hash) #=> []
  #
  # @example With A Hash With Symbol Keys
  #   hash = { data: {} }
  #   hash_contract.matches?(hash)   #=> true
  #   hash_contract.errors_for(hash) #=> []
  class IndifferentHashContract < HashContract
    # @param allow_extra_keys [true, false] If true, the contract will match
    #   hashes with keys that are not constrained by the contract.
    # @param allow_hash_like [true, false] If true, the contract will match
    #   hash-like objects that respond to the #[], #each, and #keys methods.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(
      allow_extra_keys: false,
      allow_hash_like:  false,
      **options,
      &block
    )
      super(
        allow_extra_keys: allow_extra_keys,
        allow_hash_like:  allow_hash_like,
        key_type:         Stannum::Constraints::Hashes::IndifferentKey.new,
        **options,
        &block
      )
    end

    protected

    def map_value(actual, **options)
      return super unless options[:property_type] == :key

      property = options[:property]

      case property
      when String
        actual.fetch(property) { actual[property.intern] }
      when Symbol
        actual.fetch(property) { actual[property.to_s] }
      end
    end
  end
end
