# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'

require 'stannum/constraints/properties'
require 'stannum/constraints/properties/base'

module Stannum::Constraints::Properties
  # A compares the properties of the given object with the specified property.
  #
  # @example Using an Properties::Match constraint
  #   ResetPassword = Struct.new(:password, :confirmation)
  #   constraint    = Stannum::Constraints::Properties::MatchProperty.new(
  #     :password,
  #     :confirmation
  #   )
  #
  #   params = ResetPassword.new('tronlives', 'ifightfortheusers')
  #   constraint.matches?(params)
  #   #=> false
  #   constraint.errors_for(params)
  #   #=> [
  #     {
  #       path: [:confirmation],
  #       type: 'stannum.constraints.is_not_equal_to',
  #       data: { expected: '[FILTERED]', actual: '[FILTERED]' }
  #     }
  #   ]
  #
  #   params = ResetPassword.new('tronlives', 'tronlives')
  #   constraint.matches?(params)
  #   #=> true
  class MatchProperty < Stannum::Constraints::Properties::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = Stannum::Constraints::Equality::NEGATED_TYPE

    # The :type of the error generated for a non-matching object.
    TYPE = Stannum::Constraints::Equality::TYPE

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

      super(*property_names, reference_name: reference_name, **options)
    end

    # @return [String, Symbol] the name of the reference property to compare to.
    attr_reader :reference_name

    # @return [true, false] false if the property values match the reference
    #   property value; otherwise true.
    def does_not_match?(actual)
      return false unless can_match_properties?(actual)

      expected = expected_value(actual)

      return false if allow_empty? && empty?(expected)
      return false if allow_nil?   && expected.nil?

      each_matching_property(actual: actual, expected: expected).none?
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil) # rubocop:disable Metrics/MethodLength
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)

      each_non_matching_property(actual: actual, expected: expected) \
      do |property_name, value|
        errors[property_name].add(
          type,
          message:  message,
          expected: filter_parameters? ? '[FILTERED]' : expected_value(actual),
          actual:   filter_parameters? ? '[FILTERED]' : value
        )
      end

      errors
    end

    # @return [true, false] true if the property values match the reference
    #   property value; otherwise false.
    def matches?(actual)
      return false unless can_match_properties?(actual)

      expected = expected_value(actual)

      return true if allow_empty? && empty?(expected)
      return true if allow_nil?   && expected.nil?

      each_non_matching_property(actual: actual, expected: expected).none?
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil)
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)
      matching = each_matching_property(actual: actual, expected: expected)

      return generic_errors(errors) if matching.count.zero?

      matching.each do |property_name, _|
        errors[property_name].add(negated_type, message: negated_message)
      end

      errors
    end

    private

    def each_matching_property(actual:, expected:, &block)
      unless block_given?
        return to_enum(__method__, actual: actual, expected: expected)
      end

      each_property(actual)
        .select { |_, value| value_matches?(expected: expected, value: value) }
        .each(&block)
    end

    def each_non_matching_property(actual:, expected:, &block)
      unless block_given?
        return to_enum(__method__, actual: actual, expected: expected)
      end

      each_property(actual)
        .reject { |_, value| value_matches?(expected: expected, value: value) }
        .each(&block)
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

    def validate_reference_name
      tools.assertions.validate_name(reference_name, as: 'reference name')
    end

    def value_matches?(expected:, value:)
      return true if allow_empty? && empty?(value)
      return true if allow_nil?   && value.nil?

      value == expected
    end
  end
end
