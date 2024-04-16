# frozen_string_literal: true

require 'stannum/constraints/hashes'
require 'stannum/support/coercion'

module Stannum::Constraints::Hashes
  # Constraint for validating the keys of a hash-like object.
  #
  # When using this constraint, the keys must be strings or symbols, and the
  # hash keys must be of the same type. A constraint configured with string keys
  # will not match a hash with symbol keys, and vice versa.
  #
  # @example
  #   keys       = %i[fuel mass size]
  #   constraint = Stannum::Constraints::Hashes::ExpectedKeys.new(keys)
  #
  #   constraint.matches?({})                                #=> true
  #   constraint.matches?({ fuel: 'Monopropellant' })        #=> true
  #   constraint.matches?({ 'fuel' => 'Monopropellant' })    #=> false
  #   constraint.matches?({ electric: true, fuel: 'Xenon' }) #=> false
  #   constraint.matches?({ fuel: 'LF/O', mass: '1 ton', size: 'Medium' })
  #   #=> true
  #   constraint.matches?(
  #     { fuel: 'LF', mass: '2 tons', nuclear: true, size: 'Medium' }
  #   )
  #   #=> false
  class ExtraKeys < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.hashes.no_extra_keys'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.hashes.extra_keys'

    # @param expected_keys [Array, Proc] The expected keys. If a Proc, will be
    #   evaluated each time the constraint is matched.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(expected_keys, **options)
      validate_expected_keys(expected_keys)

      expected_keys = Set.new(expected_keys) if expected_keys.is_a?(Array)

      super(expected_keys: expected_keys, **options)
    end

    # @return [true, false] true if the object responds to #[] and #keys and the
    #   object has at least one key that is not in expected_keys.
    def does_not_match?(actual)
      return false unless hash?(actual)

      !(Set.new(actual.keys) <= expected_keys) # rubocop:disable Style/InverseMethods
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      errors ||= Stannum::Errors.new

      unless actual.respond_to?(:keys)
        return add_invalid_hash_error(actual: actual, errors: errors)
      end

      each_extra_key(actual) do |key, value|
        key = Stannum::Support::Coercion.error_key(key)

        errors[key].add(type, value: value)
      end

      errors
    end

    # @return [Set] the expected keys.
    def expected_keys
      keys = options[:expected_keys]

      return keys unless keys.is_a?(Proc)

      Set.new(keys.call)
    end

    # @return [true, false] true if the object responds to #[] and #keys and the
    #   object does not have any key that is not in expected_keys.
    def matches?(actual)
      return false unless actual.respond_to?(:keys)

      Set.new(actual.keys) <= expected_keys
    end
    alias match? matches?

    private

    def add_invalid_hash_error(actual:, errors:)
      Stannum::Constraints::Signature
        .new(:keys)
        .errors_for(actual, errors: errors)
    end

    def each_extra_key(actual)
      expected = expected_keys

      actual.each_key do |key|
        next if expected.include?(key)

        yield key, actual[key]
      end
    end

    def hash?(actual)
      actual.respond_to?(:[]) && actual.respond_to?(:keys)
    end

    def valid_key?(key)
      key.is_a?(String) || key.is_a?(Symbol)
    end

    def validate_expected_keys(expected_keys)
      expected_keys = expected_keys.call if expected_keys.is_a?(Proc)

      unless expected_keys.is_a?(Array)
        raise ArgumentError,
          'expected_keys must be an Array or a Proc',
          caller(1..-1)
      end

      return if expected_keys.all? { |key| valid_key?(key) }

      raise ArgumentError, 'key must be a String or Symbol', caller(1..-1)
    end
  end
end
