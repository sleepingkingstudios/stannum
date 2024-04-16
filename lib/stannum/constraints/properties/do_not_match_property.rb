# frozen_string_literal: true

require 'stannum/constraints/properties'
require 'stannum/constraints/properties/matching'

module Stannum::Constraints::Properties
  # Compares the properties of the given object with the specified property.
  #
  # If none of the property values equal the expected value, the constraint will
  # match the object; otherwise, if there are any matching values, the
  # constraint will not match.
  #
  # @example Using an Properties::Match constraint
  #   UpdatePassword = Struct.new(:old_password, :new_password)
  #   constraint    = Stannum::Constraints::Properties::DoNotMatchProperty.new(
  #     :old_password,
  #     :new_password
  #   )
  #
  #   params = UpdatePassword.new('tronlives', 'ifightfortheusers')
  #   constraint.matches?(params)
  #   #=> true
  #
  #   params = UpdatePassword.new('tronlives', 'tronlives')
  #   constraint.matches?(params)
  #   #=> false
  #   constraint.errors_for(params)
  #   #=> [
  #     {
  #       path: [:confirmation],
  #       type: 'stannum.constraints.is_equal_to',
  #       data: { expected: '[FILTERED]', actual: '[FILTERED]' }
  #     }
  #   ]
  class DoNotMatchProperty < Stannum::Constraints::Properties::Matching
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = Stannum::Constraints::Equality::TYPE

    # The :type of the error generated for a non-matching object.
    TYPE = Stannum::Constraints::Equality::NEGATED_TYPE

    # @return [true, false] true if the property values match the reference
    #   property value; otherwise false.
    def does_not_match?(actual)
      return false unless can_match_properties?(actual)

      expected = expected_value(actual)

      return false if skip_property?(expected)

      each_non_matching_property(
        actual:      actual,
        expected:    expected,
        include_all: true
      )
        .none?
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)
      matching = each_matching_property(actual: actual, expected: expected)

      return generic_errors(errors) if matching.count.zero?

      matching.each do |property_name, _| # rubocop:disable Style/HashEachMethods
        errors[property_name].add(type, message: message)
      end

      errors
    end

    # @return [true, false] false if any of the property values match the
    #   reference property value; otherwise true.
    def matches?(actual)
      return false unless can_match_properties?(actual)

      expected = expected_value(actual)

      return true if skip_property?(expected)

      each_matching_property(actual: actual, expected: expected).none?
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      errors ||= Stannum::Errors.new

      return invalid_object_errors(errors) unless can_match_properties?(actual)

      expected = expected_value(actual)
      matching = each_non_matching_property(
        actual:      actual,
        expected:    expected,
        include_all: true
      )

      return generic_errors(errors) if matching.count.zero?

      matching.each do |property_name, value|
        errors[property_name].add(
          negated_type,
          message:  negated_message,
          expected: filter_parameters? ? '[FILTERED]' : expected_value(actual),
          actual:   filter_parameters? ? '[FILTERED]' : value
        )
      end

      errors
    end
  end
end
