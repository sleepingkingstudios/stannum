# frozen_string_literal: true

require 'stannum/constraints/hashes'

module Stannum::Constraints::Hashes
  # Constraint for validating the keys of a hash-like object.
  #
  # @example
  #   keys       = %[fuel mass size]
  #   constraint = Stannum::Constraints::Hashes::ExpectedKeys.new(keys)
  #
  #   constraint.matches?({})                                #=> true
  #   constraint.matches?({ fuel: 'Monopropellant' })        #=> true
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

      super(**options)

      @expected_keys =
        if expected_keys.is_a?(Array)
          Set.new(expected_keys)
        else
          expected_keys
        end
    end

    # @return [true, false] true if the object responds to #[] and #keys and the
    #   object has at least one key that is not in expected_keys.
    def does_not_match?(actual)
      return false unless hash?(actual)

      !(Set.new(actual.keys) <= expected_keys) # rubocop:disable Style/InverseMethods
    end

    # @return [Array] the expected keys.
    def expected_keys
      return @expected_keys unless @expected_keys.is_a?(Proc)

      Set.new(@expected_keys.call)
    end

    # @return [true, false] true if the object responds to #[] and #keys and the
    #   object does not have any key that is not in expected_keys.
    def matches?(actual)
      return false unless hash?(actual)

      Set.new(actual.keys) <= expected_keys
    end
    alias match? matches?

    # @return [String] the error type generated for a matching object.
    def negated_type
      NEGATED_TYPE
    end

    # @return [String] the error type generated for a non-matching object.
    def type
      TYPE
    end

    private

    def add_invalid_hash_error(errors)
      errors.add(
        Stannum::Constraints::Type::TYPE,
        methods: %i[[] keys],
        missing: %i[[] keys]
      )
    end

    def each_extra_key(actual)
      expected = expected_keys

      actual.keys.each do |key|
        next if expected.include?(key)

        yield key, actual[key]
      end
    end

    def hash?(actual)
      actual.respond_to?(:[]) && actual.respond_to?(:keys)
    end

    def update_errors_for(actual:, errors:)
      return add_invalid_hash_error(errors) unless hash?(actual)

      each_extra_key(actual) do |key, value|
        errors[key].add(type, value: value)
      end

      errors
    end

    def update_negated_errors_for(actual:, errors:)
      return add_invalid_hash_error(errors) unless hash?(actual)

      super
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