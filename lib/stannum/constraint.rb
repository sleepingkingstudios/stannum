# frozen_string_literal: true

require 'stannum'

module Stannum
  # A constraint codifies a particular expectation about an object.
  class Constraint
    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.invalid'

    # @overload errors_for(actual)
    #
    # Generates an errors object for the given object.
    #
    # The errors object represents the difference between the given object and
    # the expected properties or behavior. It may be the same for all objects,
    # or different based on the details of the object or the constraint.
    #
    # @example Generating errors for a non-matching object.
    #   constraint = CustomConstraint.new
    #   object     = NonMatchingObject.new
    #   errors     = constraint.errors_for(object)
    #
    #   errors.class #=> Stannum::Errors
    #   errors.to_a  #=> [{ type: 'some_error', message: 'some error message' }]
    #
    # @note This method should only be called for an object that does not match
    #   the constraint. Generating errors for a matching object can result in
    #   undefined behavior.
    #
    # @return [Stannum::Errors] the generated errors object.
    #
    # @see #matches?
    def errors_for(_actual)
      Stannum::Errors.new.add(type)
    end

    # Checks the given object against the constraint and returns errors, if any.
    #
    # This method checks the given object against the expected properties or
    # behavior. If the object matches the constraint, #match will return true.
    # If the object does not match the constraint, #match will return false and
    # the generated errors for that object.
    #
    # @example Checking a matching object.
    #   constraint = CustomConstraint.new
    #   object     = MatchingObject.new
    #
    #   success, errors = constraint.match(object)
    #   success #=> true
    #   errors  #=> nil
    #
    # @example Checking a non-matching object.
    #   constraint = CustomConstraint.new
    #   object     = NonMatchingObject.new
    #
    #   success, errors = constraint.match(object)
    #   success      #=> false
    #   errors.class #=> Stannum::Errors
    #   errors.to_a  #=> [{ type: 'some_error', message: 'some error message' }]
    #
    # @see #errors_for
    # @see #matches?
    def match(actual)
      matches?(actual) ? true : [false, errors_for(actual)]
    end

    # @overload matches?(actual)
    #
    # Checks the given object against the constraint.
    #
    # @example Checking a matching object.
    #   constraint = CustomConstraint.new
    #   object     = MatchingObject.new
    #
    #   constraint.matches?(object) #=> true
    #
    # @example Checking a non-matching object.
    #   constraint = CustomConstraint.new
    #   object     = NonMatchingObject.new
    #
    #   constraint.matches?(object) #=> false
    #
    # @return [true, false] true if the object matches the expected properties
    #   or behavior, otherwise false.
    def matches?(_actual)
      false
    end
    alias match? matches?

    # @return [String] the error type generated for a non-matching object.
    def type
      TYPE
    end
  end
end
