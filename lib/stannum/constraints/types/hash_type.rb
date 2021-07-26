# frozen_string_literal: true

require 'stannum/constraints/types'
require 'stannum/support/coercion'

module Stannum::Constraints::Types
  # A Hash type constraint asserts that the object is a Hash.
  #
  # @example Using a Hash type constraint
  #   constraint = Stannum::Constraints::Types::HashType.new
  #
  #   constraint.matches?(nil)              # => false
  #   constraint.matches?(Object.new)       # => false
  #   constraint.matches?({})               # => true
  #   constraint.matches?({ key: 'value' }) # => true
  #
  # @example Using a Hash type constraint with a key constraint
  #   constraint = Stannum::Constraints::Types::HashType.new(key_type: String)
  #
  #   constraint.matches?(nil)                  # => false
  #   constraint.matches?(Object.new)           # => false
  #   constraint.matches?({})                   # => true
  #   constraint.matches?({ key: 'value' })     # => false
  #   constraint.matches?({ 'key' => 'value' }) # => true
  #
  # @example Using a Hash type constraint with a value constraint
  #   constraint = Stannum::Constraints::Types::HashType.new(value_type: String)
  #
  #   constraint.matches?(nil)              # => false
  #   constraint.matches?(Object.new)       # => false
  #   constraint.matches?({})               # => true
  #   constraint.matches?({ key: :value })  # => false
  #   constraint.matches?({ key: 'value' }) # => true
  #
  # @example Using a Hash type constraint with a presence constraint
  #   constraint = Stannum::Constraints::Types::HashType.new(allow_empty: false)
  #
  #   constraint.matches?(nil)              # => false
  #   constraint.matches?(Object.new)       # => false
  #   constraint.matches?({})               # => false
  #   constraint.matches?({ key: :value })  # => true
  #   constraint.matches?({ key: 'value' }) # => true
  class HashType < Stannum::Constraints::Type
    # The :type of the error generated for a hash with invalid keys.
    INVALID_KEY_TYPE = 'stannum.constraints.types.hash.invalid_key'

    # The :type of the error generated for a hash with invalid values.
    INVALID_VALUE_TYPE = 'stannum.constraints.types.hash.invalid_value'

    # @param allow_empty [true, false] If false, then the constraint will not
    #   match against a Hash with no keys.
    # @param key_type [Stannum::Constraints::Base, Class, nil] If set, then the
    #   constraint will check the types of each key in the Hash against the
    #   expected type and will fail if any keys do not match.
    # @param value_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each value in the Hash against
    #   the expected type and will fail if any values do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(allow_empty: true, key_type: nil, value_type: nil, **options)
      super(
        ::Hash,
        allow_empty: !!allow_empty,
        key_type:    coerce_key_type(key_type),
        value_type:  coerce_value_type(value_type),
        **options
      )
    end

    # @return [true, false] if false, then the constraint will not
    #   match against a Hash with no keys.
    def allow_empty?
      options[:allow_empty]
    end

    # Checks that the object is not a Hash instance.
    #
    # @return [true, false] true if the object is not a Hash instance, otherwise
    #   false.
    #
    # @see Stannum::Constraints::Types::HashType#matches?
    def does_not_match?(actual)
      !matches_type?(actual)
    end

    # @return [Stannum::Constraints::Base, nil] the expected type for the keys
    #   in the hash.
    def key_type
      options[:key_type]
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
    # @see Stannum::Constraints::Types::HashType#does_not_match?
    def matches?(actual)
      return false unless super

      return false unless presence_matches?(actual)

      return false unless key_type_matches?(actual)

      return false unless value_type_matches?(actual)

      true
    end
    alias match? matches?

    # @return [Stannum::Constraints::Base, nil] the expected type for the values
    #   in the hash.
    def value_type
      options[:value_type]
    end

    private

    def add_invalid_key_errors(actual:, errors:)
      non_matching_values(actual).each do |key, value|
        errors[key].add(INVALID_VALUE_TYPE, value: value)
      end
    end

    def add_presence_error(errors)
      errors.add(
        Stannum::Constraints::Presence::TYPE,
        **error_properties
      )
    end

    def coerce_key_type(key_type)
      Stannum::Support::Coercion.type_constraint(
        key_type,
        allow_nil: true,
        as:        'key type'
      )
    end

    def coerce_value_type(value_type)
      Stannum::Support::Coercion.type_constraint(
        value_type,
        allow_nil: true,
        as:        'value type'
      )
    end

    def error_properties
      super().merge(allow_empty: allow_empty?)
    end

    def key_type_matches?(actual)
      return true unless key_type

      return true if actual.nil?

      actual.each_key.all? { |key| key_type.matches?(key) }
    end

    def non_matching_keys(actual)
      actual.each_key.reject { |key| key_type.matches?(key) }
    end

    def non_matching_values(actual)
      actual.each.reject { |_, value| value_type.matches?(value) }
    end

    def presence_matches?(actual)
      allow_empty? || !actual.empty?
    end

    def update_errors_for(actual:, errors:)
      return super unless actual.is_a?(expected_type)

      return add_presence_error(errors) unless presence_matches?(actual)

      unless key_type_matches?(actual)
        errors.add(INVALID_KEY_TYPE, keys: non_matching_keys(actual))
      end

      unless value_type_matches?(actual)
        add_invalid_key_errors(actual: actual, errors: errors)
      end

      errors
    end

    def value_type_matches?(actual)
      return true unless value_type

      return true if actual.nil?

      actual.each_value.all? { |value| value_type.matches?(value) }
    end
  end
end
