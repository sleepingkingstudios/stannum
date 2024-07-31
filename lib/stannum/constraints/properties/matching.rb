# frozen_string_literal: true

require 'stannum/constraints/properties'
require 'stannum/constraints/properties/base'

module Stannum::Constraints::Properties
  # Abstract base class for property matching constraints.
  class Matching < Stannum::Constraints::Properties::Base
    # @param reference_name [String, Symbol] the name of the reference property
    #   to compare to.
    # @param property_names [Array<String, Symbol>] the name or names of the
    #   properties to compare.
    # @param options [Hash<Symbol, Object>] configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @option options allow_empty [true, false] if true, will match against an
    #   object with empty property values, such as an empty string.
    # @option options allow_nil [true, false] if true, will match against an
    #   object with nil property values.
    def initialize(reference_name, *property_names, **options)
      @reference_name = reference_name

      validate_reference_name

      super(*property_names, reference_name:, **options)
    end

    # @return [String, Symbol] the name of the reference property to compare to.
    attr_reader :reference_name

    private

    def each_matching_property( # rubocop:disable Metrics/MethodLength
      actual:,
      expected:,
      include_all: false,
      &block
    )
      unless block_given?
        return to_enum(
          __method__,
          actual:,
          expected:,
          include_all:
        )
      end

      enumerator = each_property(actual)

      unless include_all
        enumerator = enumerator.reject { |_, value| skip_property?(value) }
      end

      enumerator = enumerator.select { |_, value| valid?(expected, value) }

      block_given? ? enumerator.each(&block) : enumerator
    end

    def each_non_matching_property( # rubocop:disable Metrics/MethodLength
      actual:,
      expected:,
      include_all: false,
      &block
    )
      unless block_given?
        return to_enum(
          __method__,
          actual:,
          expected:,
          include_all:
        )
      end

      enumerator = each_property(actual)

      unless include_all
        enumerator = enumerator.reject { |_, value| skip_property?(value) }
      end

      enumerator = enumerator.reject { |_, value| valid?(expected, value) }

      block_given? ? enumerator.each(&block) : enumerator
    end

    def expected_value(actual)
      actual[reference_name]
    end

    def filter_parameters?
      return @filter_parameters unless @filter_parameters.nil?

      filters = filtered_parameters.map { |param| Regexp.new(param.to_s) }

      @filter_parameters =
        [reference_name, *property_names].any? do |property_name|
          filters.any? { |filter| filter.match?(property_name.to_s) }
        end
    end

    def generic_errors(errors)
      errors.add(Stannum::Constraints::Base::NEGATED_TYPE)
    end

    def valid?(expected, value)
      value == expected
    end

    def validate_reference_name
      tools.assertions.validate_name(reference_name, as: 'reference name')
    end
  end
end
