# frozen_string_literal: true

require 'stannum/constraints/types'

module Stannum::Constraints::Types
  # An Array type constraint asserts that the object is an Array.
  #
  # @example Using an Array type constraint
  #   constraint = Stannum::Constraints::Types::Array.new
  #
  #   constraint.matches?(nil)        # => false
  #   constraint.matches?(Object.new) # => false
  #   constraint.matches?([])         # => true
  #   constraint.matches?([1, 2, 3])  # => true
  #
  # @example Using an Array type constraint with a key constraint
  #   constraint = Stannum::Constraints::Types::Array.new(item_type: String)
  #
  #   constraint.matches?(nil)               # => false
  #   constraint.matches?(Object.new)        # => false
  #   constraint.matches?([])                # => true
  #   constraint.matches?([1, 2, 3])         # => false
  #   constraint.matches?(%w[one two three]) # => true
  class Array < Stannum::Constraints::Type
    # The :type of the error generated for an array with invalid items.
    INVALID_ITEM_TYPE = 'stannum.constraints.types.array.invalid_item'

    # @param item_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each item in the Array against
    #   the expected type and will fail if any items do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(item_type: nil, **options)
      super(
        ::Array,
        item_type: item_type,
        **options
      )

      @item_type = validate_item_type(item_type)
    end

    # @return [Stannum::Constraints::Base, nil] the expected type for the items
    #   in the array.
    attr_reader :item_type

    # Checks that the object is not an Array instance.
    #
    # @return [true, false] true if the object is not an Array instance,
    #   otherwise false.
    #
    # @see Stannum::Constraints::Types::Array#matches?
    def does_not_match?(actual)
      !matches_type?(actual)
    end

    # Checks that the object is an Array instance and that the items match.
    #
    # If the constraint was configured with an item_type, each item in the Array
    # will be compared to the expected type. If any items do not match the
    # expectation, then #matches? will return false.
    #
    # @return [true, false] true if the object is an Array instance with
    #   matching items, otherwise false.
    #
    # @see Stannum::Constraints::Types::Array#does_not_match?
    def matches?(actual)
      return false unless super

      return false unless item_type_matches?(actual)

      true
    end
    alias match? matches?

    private

    def item_type_matches?(actual)
      return true unless item_type

      actual.all? { |item| item_type.matches?(item) }
    end

    def non_matching_items(actual)
      actual.reject { |item| item_type.matches?(item) }
    end

    def update_errors_for(actual:, errors:)
      return super unless actual.is_a?(expected_type)

      unless item_type_matches?(actual)
        errors.add(INVALID_ITEM_TYPE, items: non_matching_items(actual))
      end

      errors
    end

    def validate_item_type(item_type)
      return nil if item_type.nil?

      return item_type if item_type.is_a?(Stannum::Constraints::Base)

      return Stannum::Constraints::Type.new(item_type) if item_type.is_a?(Class)

      raise ArgumentError,
        'item_type must be a Class or a constraint',
        caller(1..-1)
    end
  end
end
