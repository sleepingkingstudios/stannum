# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Contract that defines constraints on an ordered data structure.
  #
  # @example Creating A Contract With Items
  #   length_constraint =
  #     Stannum::Constraint.new { |value| value.is_a?(Integer) }
  #
  #   contract = Stannum::Contracts::MapContract.new do
  #     item length_constraint
  #     item Spec::ManufacturerContract.new
  #     item { |value| value.is_a?(String) }
  #   end
  class TupleContract < Stannum::Contract
    # The :type of the error generated for a tuple with extra items.
    EXTRA_ITEM_TYPE = 'stannum.constraints.tuple_extra_item'

    # The :type of the error generated for a tuple with missing items.
    MISSING_ITEM_TYPE = 'stannum.constraints.tuple_missing_item'

    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_tuple'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_tuple'

    # Builder class for defining property constraints for a TupleContract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for TupleContract.
    #
    # @api private
    class Builder < Stannum::Contracts::Builder
      # @param contract [Stannum::Contract] The contract to which constraints
      #   are added.
      def initialize(contract)
        super

        @next_index = 0
      end

      # Defines an item constraint on the contract.
      #
      # @overload item(constraint)
      #   Adds the given constraint to the contract for the next index.
      #
      #   @param constraint [Stannum::Constraint::Base] The constraint to add.
      #
      # @overload item { |value| }
      #   Creates a new Stannum::Constraint object with the given block, and
      #   adds that constraint to the contract for the next index.
      #
      #   @yieldparam value [Object] The value at the index when called.
      #
      # @raise ArgumentError if the property name is not valid.
      #
      # @see Stannum::Contract#add_constraint.
      def item(constraint = nil, &block)
        constraint = resolve_constraint(constraint, &block)

        contract.add_constraint(constraint, property: @next_index)

        @next_index += 1
      end
    end

    # @return [Hash] The options defined for the contract.
    attr_reader :options

    # @param allow_extra_items [Boolean] If false, the contract will fail when
    #   checking an object with more items than are expected. Defaults to false.
    def initialize(allow_extra_items: false, &block)
      super()

      @options = {
        allow_extra_items: allow_extra_items
      }

      build_constraints(block) if block_given?
    end

    # @return [Boolean] If false, the contract will fail when checking an object
    #   with more items than are expected.
    def allow_extra_items?
      @options[:allow_extra_items]
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity

    # Checks if the given object matches any of the constraints.
    #
    # @see Stannum::Contract#does_not_match?
    def does_not_match?(object)
      return true unless tuple?(object)

      return true if !allow_extra_items? && extra_items?(object)

      return true if missing_items?(object)

      if item_constraints.empty? && (object.empty? || allow_extra_items?)
        return false
      end

      super
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # The :type of the error generated for a tuple with extra items.
    def extra_item_type
      EXTRA_ITEM_TYPE
    end

    # Checks if the given object matches all of the constraints.
    #
    # @see Stannum::Contract#matches?
    def matches?(object)
      return false unless tuple?(object)

      return false if !allow_extra_items? && extra_items?(object)

      return false if missing_items?(object)

      super
    end
    alias match? matches?

    # The :type of the error generated for a tuple with missing items.
    def missing_item_type
      MISSING_ITEM_TYPE
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
      object[property]
    end

    def build_constraints(block)
      self.class::Builder.new(self).instance_exec(&block)
    end

    def each_extra_item(actual, &block)
      return unless !allow_extra_items? && extra_items?(actual)

      first_index = item_constraints.size

      actual[first_index..-1].each.with_index(first_index, &block)
    end

    def each_missing_item(actual, &block)
      return unless missing_items?(actual)

      actual.size.upto(item_constraints.size - 1).each(&block)
    end

    def errors_for_constraint(
      actual:,
      constraint:,
      errors:,
      property:,
      **_keywords
    )
      return if property.is_a?(Integer) && property >= actual.size

      super
    end

    def extra_items?(actual)
      item_constraints.size < actual.size
    end

    def item_constraints
      constraints.select { |constraint| constraint[:property].is_a?(Integer) }
    end

    def missing_items?(actual)
      item_constraints.size > actual.size
    end

    def tuple?(object)
      object.respond_to?(:[]) && !object.respond_to?(:key?)
    end

    def update_errors_for(actual:, errors:)
      return errors.add(type) unless tuple?(actual)

      each_missing_item(actual) do |index|
        errors[index].add(missing_item_type)
      end

      each_extra_item(actual) do |item, index|
        errors[index].add(extra_item_type, value: item)
      end

      super
    end

    def update_negated_errors_for(actual:, errors:)
      return errors.add(negated_type) if item_constraints.empty?

      return errors unless tuple?(actual)

      super
    end
  end
end
