# frozen_string_literal: true

require 'stannum/constraints/types'
require 'stannum/support/coercion'

module Stannum::Constraints::Types
  # An Array type constraint asserts that the object is an Array.
  #
  # @example Using an Array type constraint
  #   constraint = Stannum::Constraints::Types::ArrayType.new
  #
  #   constraint.matches?(nil)        # => false
  #   constraint.matches?(Object.new) # => false
  #   constraint.matches?([])         # => true
  #   constraint.matches?([1, 2, 3])  # => true
  #
  # @example Using an Array type constraint with an item constraint
  #   constraint = Stannum::Constraints::Types::ArrayType.new(item_type: String)
  #
  #   constraint.matches?(nil)               # => false
  #   constraint.matches?(Object.new)        # => false
  #   constraint.matches?([])                # => true
  #   constraint.matches?([1, 2, 3])         # => false
  #   constraint.matches?(%w[one two three]) # => true
  #
  # @example Using an Array type constraint with a presence constraint
  #   constraint = Stannum::Constraints::Types::ArrayType.new(allow_empty: false)
  #
  #   constraint.matches?(nil)               # => false
  #   constraint.matches?(Object.new)        # => false
  #   constraint.matches?([])                # => false
  #   constraint.matches?([1, 2, 3])         # => true
  #   constraint.matches?(%w[one two three]) # => true
  class ArrayType < Stannum::Constraints::Type
    # @param allow_empty [true, false] If false, then the constraint will not
    #   match against an Array with no items.
    # @param item_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each item in the Array against
    #   the expected type and will fail if any items do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(allow_empty: true, item_type: nil, **options)
      super(
        ::Array,
        allow_empty: !!allow_empty,
        item_type:   coerce_item_type(item_type),
        **options
      )
    end

    # @return [true, false] if false, then the constraint will not
    #   match against an Array with no items.
    def allow_empty?
      options[:allow_empty]
    end

    # Checks that the object is not an Array instance.
    #
    # @return [true, false] true if the object is not an Array instance,
    #   otherwise false.
    #
    # @see Stannum::Constraints::Types::ArrayType#matches?
    def does_not_match?(actual) # rubocop:disable Naming/PredicateName
      !matches_type?(actual)
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      return super unless actual.is_a?(expected_type)

      errors ||= Stannum::Errors.new

      return add_presence_error(errors) unless presence_matches?(actual)

      unless item_type_matches?(actual)
        non_matching_items(actual).each do |item, index|
          item_type.errors_for(item, errors: errors[index])
        end
      end

      errors
    end

    # @return [Stannum::Constraints::Base, nil] the expected type for the items
    #   in the array.
    def item_type
      options[:item_type]
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
    # @see Stannum::Constraints::Types::ArrayType#does_not_match?
    def matches?(actual)
      return false unless super

      return false unless presence_matches?(actual)

      return false unless item_type_matches?(actual)

      true
    end
    alias match? matches?

    private

    def add_presence_error(errors)
      errors.add(
        Stannum::Constraints::Presence::TYPE,
        **error_properties
      )
    end

    def coerce_item_type(item_type)
      Stannum::Support::Coercion.type_constraint(
        item_type,
        allow_nil: true,
        as:        'item type'
      )
    end

    def error_properties
      super.merge(allow_empty: allow_empty?)
    end

    def item_type_matches?(actual)
      return true unless item_type

      return true if actual.nil?

      actual.all? { |item| item_type.matches?(item) }
    end

    def non_matching_items(actual)
      actual.each.with_index.reject { |item, _| item_type.matches?(item) }
    end

    def presence_matches?(actual)
      allow_empty? || !actual.empty?
    end
  end
end
