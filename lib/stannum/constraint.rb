# frozen_string_literal: true

require 'stannum'

module Stannum
  # A constraint codifies a particular expectation about an object.
  class Constraint
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.valid'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.invalid'

    # Checks that the given object does not match the constraint.
    #
    # @example Checking a matching object.
    #   constraint = CustomConstraint.new
    #   object     = MatchingObject.new
    #
    #   constraint.does_not_match?(object) #=> false
    #
    # @example Checking a non-matching object.
    #   constraint = CustomConstraint.new
    #   object     = NonMatchingObject.new
    #
    #   constraint.does_not_match?(object) #=> true
    #
    # @return [true, false] false if the object matches the expected properties
    #   or behavior, otherwise true.
    #
    # @see #matches?
    def does_not_match?(actual)
      !matches?(actual)
    end

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
    # @see #negated_errors_for
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
    # Checks that the given object matches the constraint.
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
    #
    # @see #does_not_match?
    def matches?(_actual)
      false
    end
    alias match? matches?

    # @overload negated_errors_for(actual)
    #
    # Generates an errors object for the given object when negated.
    #
    # The errors object represents the difference between the given object and
    # the expected properties or behavior when the constraint is negated. It may
    # be the same for all objects, or different based on the details of the
    # object or the constraint.
    #
    # @example Generating errors for a matching object.
    #   constraint = CustomConstraint.new
    #   object     = MatchingObject.new
    #   errors     = constraint.negated_errors_for(object)
    #
    #   errors.class #=> Stannum::Errors
    #   errors.to_a  #=> [{ type: 'some_error', message: 'some error message' }]
    #
    # @note This method should only be called for an object that matches the
    #   constraint. Generating errors for a matching object can result in
    #   undefined behavior.
    #
    # @return [Stannum::Errors] the generated errors object.
    #
    # @see #does_not_match?
    # @see #errors_for
    def negated_errors_for(_actual)
      Stannum::Errors.new.add(negated_type)
    end

    # Checks the given object against the constraint and returns errors, if any.
    #
    # This method checks the given object against the expected properties or
    # behavior. If the object matches the constraint, #negated_match will return
    # false and the generated errors for that object. If the object does not
    # match the constraint, #negated_match will return true.
    #
    # @example Checking a matching object.
    #   constraint = CustomConstraint.new
    #   object     = MatchingObject.new
    #
    #   success, errors = constraint.negated_match(object)
    #   success      #=> false
    #   errors.class #=> Stannum::Errors
    #   errors.to_a  #=> [{ type: 'some_error', message: 'some error message' }]
    #
    # @example Checking a non-matching object.
    #   constraint = CustomConstraint.new
    #   object     = NonMatchingObject.new
    #
    #   success, errors = constraint.negated_match(object)
    #   success #=> true
    #   errors  #=> nil
    #
    # @see #does_not_match?
    # @see #match
    # @see #negated_errors_for
    def negated_match(actual)
      does_not_match?(actual) ? true : [false, negated_errors_for(actual)]
    end

    # @return [String] the error type generated for a matching object.
    def negated_type
      NEGATED_TYPE
    end

    # @return [String] the error type generated for a non-matching object.
    def type
      TYPE
    end
  end
end