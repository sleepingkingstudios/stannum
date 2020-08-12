# frozen_string_literal: true

require 'stannum/constraints/tuples'

module Stannum::Constraints::Tuples
  # Constraint for validating the length of an indexed object.
  #
  # @example
  #   constraint = Stannum::Constraints::Tuples::ExtraItems.new(3)
  #
  #   constraint.matches?([])           #=> true
  #   constraint.matches?([1])          #=> true
  #   constraint.matches?([1, 2, 3])    #=> true
  #   constraint.matches?([1, 2, 3, 4]) #=> false
  class ExtraItems < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.tuples.no_extra_items'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.tuples.extra_items'

    # @todo Document #initialize.
    def initialize(expected_count, **options)
      super(**options)

      @expected_count = expected_count
    end

    # @todo Document #does_not_match?
    def does_not_match?(actual)
      return false unless actual.respond_to?(:size)

      actual.size > expected_count
    end

    # @todo Document #expected_count.
    def expected_count
      @expected_count.is_a?(Proc) ? @expected_count.call : @expected_count
    end

    # @todo Document #matches?
    def matches?(actual)
      return false unless actual.respond_to?(:size)

      actual.size <= expected_count
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

    def add_invalid_tuple_error(errors)
      errors.add(
        Stannum::Constraints::Type::TYPE,
        methods: %i[size],
        missing: %i[size]
      )
    end

    def each_extra_item(actual, &block)
      return if matches?(actual)

      actual[expected_count..-1].each.with_index(expected_count, &block)
    end

    def update_errors_for(actual:, errors:)
      return add_invalid_tuple_error(errors) unless actual.respond_to?(:size)

      each_extra_item(actual) do |item, index|
        errors[index].add(type, value: item)
      end

      errors
    end

    def update_negated_errors_for(actual:, errors:)
      return add_invalid_tuple_error(errors) unless actual.respond_to?(:size)

      super
    end
  end
end
