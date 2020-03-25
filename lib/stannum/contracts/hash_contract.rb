# frozen_string_literal: true

require 'stannum/constraints/type'
require 'stannum/contracts/map_contract'

module Stannum::Contracts
  # Contract that defines constraints on a hash and its keys and values.
  #
  # @example Creating A Contract
  #   contract = Stannum::Contracts::HashContract.new do
  #     property :name,   name_constraint
  #     property :size,   ->(value) { value.is_a?(Integer) }
  #     property :weight, Spec::WeightConstraint.new
  #   end
  #
  # @example With A Non-Hash Object
  #   contract.matches?(nil) #=> false
  #   errors = contract.errors_for(nil) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> [
  #   #     {
  #   #       data: { type: Hash },
  #   #       type: 'stannum.constraints.is_not_type'
  #   #     }
  #   #   ]
  #
  # @example With A Hash With Non-Matching Key-Value Pairs
  #   contract.matches?({}) => false
  #   errors = contract.errors_for({}) #=> Cuprum::Errors
  #   errors.to_a
  #   #=> [
  #   #     {
  #   #       type: 'spec.is_not_a_name'
  #   #     },
  #   #     {
  #   #       type: 'stannum.constraints.invalid'
  #   #     },
  #   #     {
  #   #       type: 'spec.is_not_a_valid_weight'
  #   #     }
  #   #   ]
  class HashContract < MapContract # rubocop:disable Metrics/ClassLength
    # @api private
    #
    # Mixin for HashContract instances that permit any objects as Hash keys.
    #
    # @see Stannum::Contracts::HashContract
    module AnyKeys
      private

      def valid_property?(_property_name)
        true
      end
    end

    # @api private
    #
    # Mixin for HashContract instances that permit either Strings or Symbols
    # as Hash keys.
    #
    # @see Stannum::Contracts::HashContract
    module IndifferentKeys
      private

      def access_property(object, property)
        return nil unless object.respond_to?(:[]) && object.respond_to?(:key?)

        string_key = property.to_s
        symbol_key = property.intern

        object.key?(string_key) ? object[string_key] : object[symbol_key]
      end
    end

    # @api private
    #
    # Mixin for HashContract instances that permit only Strings as Hash keys.
    #
    # @see Stannum::Contracts::HashContract
    module StringKeys
      private

      def valid_property?(property_name)
        property_name.is_a?(String) && !property_name.empty?
      end
    end

    # @api private
    #
    # Mixin for HashContract instances that permit only Symbols as Hash keys.
    #
    # @see Stannum::Contracts::HashContract
    module SymbolKeys
      private

      def valid_property?(property_name)
        property_name.is_a?(Symbol) && !property_name.empty?
      end
    end

    KEY_TYPES = {
      any:         AnyKeys,
      indifferent: IndifferentKeys,
      string:      StringKeys,
      symbol:      SymbolKeys
    }.freeze
    private_constant :KEY_TYPES

    # The :type of the error generated for a hash with extra keys.
    EXTRA_KEYS_TYPE = 'stannum.constraints.hash_with_extra_keys'

    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_hash_like'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_hash_like'

    # @param allow_extra_keys [Boolean] If false, the contract will fail on a
    #   Hash that has keys not specified in the contract. Defaults to true.
    # @param allow_hash_like [Boolean] If true, the contract will match objects
    #   that are not Hash instances, but that implement the expected Hash
    #   methods. Defaults to true.
    # @param key_type [Symbol] The expected type of the Hash keys. Must be one
    #   of :any (key can be any object), :indifferent (key can be either a
    #   String or a Symbol), :string, or :symbol. Defaults to :any.
    #
    # @yield Creates an instance of MapContract::Builder with the new contract
    #   and executes the block in the context of the builder.
    #
    # @see Stannum::Contracts::MapContract::Builder
    def initialize(
      allow_extra_keys: true,
      allow_hash_like:  true,
      key_type:         :any,
      &block
    )
      apply_key_type(key_type)

      super(&block)

      @options = {
        allow_extra_keys: allow_extra_keys,
        allow_hash_like:  allow_hash_like,
        key_type:         key_type
      }
    end

    attr_reader :options

    # @return [Boolean] if false, the contract will fail on a Hash that has keys
    #   not specified in the contract.
    def allow_extra_keys?
      @options[:allow_extra_keys]
    end

    # @return [Boolean] if true, the contract will match objects that are not
    #   Hash instances, but that implement the expected Hash methods.
    def allow_hash_like?
      @options[:allow_hash_like]
    end

    # @!method errors_for(actual)
    #   (see Stannum::Constraints::Base#errors_for)

    # @!method negated_errors_for(actual)
    #   (see Stannum::Constraints::Base#negated_errors_for)

    # (see Stannum::Constraints::Base#does_not_match?)
    def does_not_match?(actual)
      return false if hash_like?(actual)

      super
    end

    # @return [Symbol] the expected type of the Hash keys.
    def key_type
      @options[:key_type]
    end

    # (see Stannum::Constraints::Base#matches?)
    def matches?(actual)
      return false unless hash_like?(actual)

      return false unless extra_keys(actual).empty?

      super
    end

    # @return [String] the error type generated for a matching object.
    def negated_type
      NEGATED_TYPE
    end

    # @return [String] the error type generated for a non-matching object.
    def type
      TYPE
    end

    private

    def access_property(object, property)
      object.respond_to?(:[]) ? object[property] : nil
    end

    def apply_key_type(key_type)
      validate_key_type(key_type)

      extend(KEY_TYPES[key_type])
    end

    def extra_keys(actual)
      return [] if allow_extra_keys?

      expected_keys = constraints.map { |hsh| hsh[:property] }

      actual.keys - expected_keys
    end

    def hash_like?(actual)
      return actual.is_a?(Hash) unless allow_hash_like?

      actual.respond_to?(:[]) &&
        actual.respond_to?(:key?) &&
        actual.respond_to?(:keys)
    end

    def update_errors_for(actual:, errors:)
      if hash_like?(actual)
        err = super

        update_extra_keys_error(actual: actual, errors: err)
      elsif allow_hash_like?
        errors.add(type)
      else
        errors.add(Stannum::Constraints::Type::TYPE, type: Hash)
      end
    end

    def update_extra_keys_error(actual:, errors:)
      keys = extra_keys(actual)

      return errors if keys.empty?

      errors.add(EXTRA_KEYS_TYPE, keys: keys)
    end

    def update_negated_errors_for(actual:, errors:)
      if allow_hash_like? && hash_like?(actual)
        errors.add(negated_type)
      elsif hash_like?(actual)
        errors.add(Stannum::Constraints::Type::NEGATED_TYPE, type: Hash)
      else
        super
      end
    end

    def validate_key_type(key_type)
      return if KEY_TYPES.keys.include?(key_type)

      raise ArgumentError,
        'key_type must be :any, :indifferent, :string, or :symbol',
        caller[1..-1]
    end
  end
end
