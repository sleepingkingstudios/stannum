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

    # @param expected_count [Integer, Proc] The number of expected items. If a
    #   Proc, will be evaluated each time the constraint is matched.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(expected_count, **options)
      super(expected_count:, **options)
    end

    # @return [true, false] true if the object responds to #size and the object
    #   size is greater than the number of expected items; otherwise false.
    def does_not_match?(actual) # rubocop:disable Naming/PredicatePrefix
      return false unless actual.respond_to?(:size)

      actual.size > expected_count
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      errors ||= Stannum::Errors.new

      unless actual.respond_to?(:size)
        return add_invalid_tuple_error(actual:, errors:)
      end

      each_extra_item(actual) do |item, index|
        errors[index].add(type, value: item)
      end

      errors
    end

    # @return [Integer] the number of expected items.
    def expected_count
      count = options[:expected_count]

      count.is_a?(Proc) ? count.call : count
    end

    # @return [true, false] true if the object responds to #size and the object
    #   size is less than or equal to than the number of expected items;
    #   otherwise false.
    def matches?(actual)
      return false unless actual.respond_to?(:size)

      actual.size <= expected_count
    end
    alias match? matches?

    private

    def add_invalid_tuple_error(actual:, errors:)
      Stannum::Constraints::Signature
        .new(:size)
        .errors_for(actual, errors:)
    end

    def each_extra_item(actual, &)
      return if matches?(actual)

      actual[expected_count..].each.with_index(expected_count, &)
    end
  end
end
