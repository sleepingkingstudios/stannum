# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # A Hash type constraint asserts that the object is a Hash.
  #
  # @example Using a Hash type constraint
  #   constraint = Stannum::Constraints::Types::Hash.new
  #
  #   constraint.matches?(nil)              # => false
  #   constraint.matches?(Object.new)       # => false
  #   constraint.matches?({})               # => true
  #   constraint.matches?({ key: 'value' }) # => true
  #
  # @example Using a Hash type constraint with a key constraint
  #   constraint = Stannum::Constraints::Types::Hash.new(key_type: String)
  #
  #   constraint.matches?(nil)                  # => false
  #   constraint.matches?(Object.new)           # => false
  #   constraint.matches?({})                   # => true
  #   constraint.matches?({ key: 'value' })     # => false
  #   constraint.matches?({ 'key' => 'value' }) # => true
  #
  # @example Using a Hash type constraint with a value constraint
  #   constraint = Stannum::Constraints::Types::Hash.new(value_type: String)
  #
  #   constraint.matches?(nil)              # => false
  #   constraint.matches?(Object.new)       # => false
  #   constraint.matches?({})               # => true
  #   constraint.matches?({ key: :value })  # => false
  #   constraint.matches?({ key: 'value' }) # => true
  class Hash < Stannum::Constraints::Type
    # The :type of the error generated for a hash with invalid keys.
    INVALID_KEY_TYPE = 'stannum.constraints.types.hash.invalid_key'

    # The :type of the error generated for a hash with invalid values.
    INVALID_VALUE_TYPE = 'stannum.constraints.types.hash.invalid_value'

    # @param key_type [Stannum::Constraints::Base, Class, nil] If set, then the
    #   constraint will check the types of each key in the Hash against the
    #   expected type and will fail if any keys do not match.
    # @param value_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each value in the Hash against
    #   the expected type and will fail if any values do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(key_type: nil, value_type: nil, **options)
      super(
        ::Hash,
        key_type:   key_type,
        value_type: value_type,
        **options
      )

      @key_type   = validate_key_type(key_type)
      @value_type = validate_value_type(value_type)
    end

    # @return [Stannum::Constraints::Base, nil] the expected type for the keys
    #   in the hash.
    attr_reader :key_type

    # @return [Stannum::Constraints::Base, nil] the expected type for the values
    #   in the hash.
    attr_reader :value_type

    # Checks that the object is not a Hash instance.
    #
    # @return [true, false] true if the object is not a Hash instance, otherwise
    #   false.
    #
    # @see Stannum::Constraints::Types::Hash#matches?
    def does_not_match?(actual)
      !matches_type?(actual)
    end

    # Checks that the object is a Hash instance and that the keys/values match.
    #
    # If the constraint was configured with a key_type, each key in the hash
    # will be compared to the expected type. Likewise, if the constraint was
    # configured with a value_type, each value in the hash will be compared. If
    # any keys and/or values do not match the expectation, then #matches? will
    # return false.
    #
    # @return [true, false] true if the object is a Hash instance with matching
    #   keys and values, otherwise false.
    #
    # @see Stannum::Constraints::Types::Hash#does_not_match?
    def matches?(actual)
      return false unless super

      return false unless key_type_matches?(actual)

      return false unless value_type_matches?(actual)

      true
    end
    alias match? matches?

    private

    def key_type_matches?(actual)
      return true unless key_type

      actual.each_key.all? { |key| key_type.matches?(key) }
    end

    def non_matching_keys(actual)
      actual.each_key.reject { |key| key_type.matches?(key) }
    end

    def non_matching_values(actual)
      actual.each_value.reject { |value| value_type.matches?(value) }
    end

    def update_errors_for(actual:, errors:)
      return super unless actual.is_a?(expected_type)

      unless key_type_matches?(actual)
        errors.add(INVALID_KEY_TYPE, keys: non_matching_keys(actual))
      end

      unless value_type_matches?(actual)
        errors.add(INVALID_VALUE_TYPE, values: non_matching_values(actual))
      end

      errors
    end

    def validate_key_type(key_type)
      return nil if key_type.nil?

      return key_type if key_type.is_a?(Stannum::Constraints::Base)

      return Stannum::Constraints::Type.new(key_type) if key_type.is_a?(Class)

      raise ArgumentError,
        'key_type must be a Class or a constraint',
        caller(1..-1)
    end

    def validate_value_type(value_type)
      return nil if value_type.nil?

      return value_type if value_type.is_a?(Stannum::Constraints::Base)

      if value_type.is_a?(Class)
        return Stannum::Constraints::Type.new(value_type)
      end

      raise ArgumentError,
        'value_type must be a Class or a constraint',
        caller(1..-1)
    end

    def value_type_matches?(actual)
      return true unless value_type

      actual.each_value.all? { |value| value_type.matches?(value) }
    end
  end
end
