# frozen_string_literal: true

require 'stannum/constraints/properties'
require 'stannum/constraints/properties/matching'

module Stannum::Constraints::Properties
  # Compares the properties of the given object with the specified property.
  #
  # If all of the property values equal the expected value, the constraint will
  # match the object; otherwise, if there are any non-matching values, the
  # constraint will not match.
  #
  # @example Using an Properties::Match constraint
  #   ConfirmPassword = Struct.new(:password, :confirmation)
  #   constraint    = Stannum::Constraints::Properties::MatchProperty.new(
  #     :password,
  #     :confirmation
  #   )
  #
  #   params = ConfirmPassword.new('tronlives', 'ifightfortheusers')
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
  #   params = ConfirmPassword.new('tronlives', 'tronlives')
  #   constraint.matches?(params)
  #   #=> true
  class MatchProperty < Stannum::Constraints::Properties::Matching
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = Stannum::Constraints::Equality::NEGATED_TYPE

    # The :type of the error generated for a non-matching object.
    TYPE = Stannum::Constraints::Equality::TYPE

    # @return [true, false] false if any of the property values match the
    #   reference property value; otherwise true.
    def does_not_match?(actual) # rubocop:disable Naming/PredicatePrefix
      return false unless can_match_properties?(actual)

      expected = expected_value(actual)

      return false if skip_property?(expected)

      each_matching_property(
        actual:,
        expected:,
        include_all: true
      )
        .none?
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)
      matching = each_non_matching_property(actual:, expected:)

      return generic_errors(errors) if matching.none?

      matching.each do |property_name, value|
        errors[property_name].add(
          type,
          message:,
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

      return true if skip_property?(expected)

      each_non_matching_property(actual:, expected:).none?
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil) # rubocop:disable Metrics/MethodLength
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)
      matching = each_matching_property(
        actual:,
        expected:,
        include_all: true
      )

      return generic_errors(errors) if matching.none?

      matching.each do |property_name, _| # rubocop:disable Style/HashEachMethods
        errors[property_name].add(negated_type, message: negated_message)
      end

      errors
    end
  end
end
