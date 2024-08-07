# frozen_string_literal: true

require 'stannum/constraints/base'
require 'stannum/support/optional'

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
  class Type < Stannum::Constraints::Base
    include Stannum::Support::Optional

    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_type'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_type'

    # @param expected_type [Class, Module, String] The type the object is
    #   expected to belong to. Can be a Class or a Module, or the name of a
    #   class or module.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(expected_type, optional: nil, required: nil, **options)
      expected_type = resolve_expected_type(expected_type)

      super(
        expected_type:,
        **resolve_required_option(
          optional:,
          required:,
          **options
        )
      )
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new).add(type, **error_properties)
    end

    # @return [Class, Module, String] the type the object is expected to belong
    #   to.
    def expected_type
      options[:expected_type]
    end

    # Checks that the object is an instance of the expected type.
    #
    # @return [true, false] true if the object is an instance of the expected
    #   type, otherwise false.
    #
    # @see Stannum::Constraint#matches?
    def matches?(actual)
      matches_type?(actual)
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new).add(negated_type, **error_properties)
    end

    # (see Stannum::Constraints::Base#with_options)
    def with_options(**options)
      options = options.merge(required_by_default: required?)

      super(**resolve_required_option(**options))
    end

    private

    def error_properties
      { required: required?, type: expected_type }
    end

    def matches_type?(actual)
      actual.is_a?(expected_type) || (optional? && actual.nil?)
    end

    def resolve_expected_type(type_or_name)
      return type_or_name if type_or_name.is_a?(Module)

      return Object.const_get(type_or_name) if type_or_name.is_a?(String)

      raise ArgumentError,
        'expected type must be a Class or Module',
        caller[1..]
    end
  end
end
