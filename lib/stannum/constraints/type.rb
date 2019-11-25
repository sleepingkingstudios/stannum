# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # A type constraint asserts that the object is of the expected type.
  #
  # @example Using a Type constraint with a Class
  #   constraint = Stannum::Constraints::Type.new(StandardError)
  #
  #   constraint.matches?(nil)               # => false
  #   constraint.matches?(Object.new)        # => false
  #   constraint.matches?(StandardError.new) # => true
  #   constraint.matches?(RuntimeError.new)  # => true
  #
  # @example Using a Type constraint with a Module
  #   constraint = Stannum::Constraints::Type.new(Enumerable)
  #
  #   constraint.matches?(nil)                           #=> false
  #   constraint.matches?(Object.new)                    #=> false
  #   constraint.matches?(Array)                         #=> true
  #   constraint.matches?(Object.new.extend(Enumerable)) #=> true
  #
  # @example Using a Type constraint with a Class name
  #   constraint = Stannum::Constraints::Type.new('StandardError')
  #
  #   constraint.matches?(nil)               # => false
  #   constraint.matches?(Object.new)        # => false
  #   constraint.matches?(StandardError.new) # => true
  #   constraint.matches?(RuntimeError.new)  # => true
  class Type < Stannum::Constraint
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_type'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_type'

    # @param expected_type [Class, Module, String] The type the object is
    #   expected to belong to. Can be a Class or a Module, or the name of a
    #   class or module.
    def initialize(expected_type)
      @expected_type = resolve_expected_type(expected_type)
    end

    # @return [Class, Module, String] the type the object is expected to belong
    #   to.
    attr_reader :expected_type

    # Checks that the object is an instance of the expected type.
    #
    # @return [true, false] true if the object is an instance of the expected
    #   type, otherwise false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      actual.is_a?(expected_type)
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

    protected

    # rubocop:disable Lint/UnusedMethodArgument
    def update_errors_for(actual:, errors:)
      errors.add(type, type: expected_type)
    end

    def update_negated_errors_for(actual:, errors:)
      errors.add(negated_type, type: expected_type)
    end
    # rubocop:enable Lint/UnusedMethodArgument

    private

    def resolve_expected_type(type_or_name)
      return type_or_name if type_or_name.is_a?(Module)

      return Object.const_get(type_or_name) if type_or_name.is_a?(String)

      raise ArgumentError,
        'expected type must be a Class or Module',
        caller[1..-1]
    end
  end
end
