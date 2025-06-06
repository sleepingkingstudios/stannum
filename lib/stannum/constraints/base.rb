# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # A constraint codifies a particular expectation about an object.
  class Base
    # Builder class for defining constraints for a Contract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for Contract.
    #
    # @api private
    class Builder < Stannum::Contracts::Builder
    end

    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.valid'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.invalid'

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    # @option options [String] :message The default error message generated for
    #   a non-matching object.
    # @option options [String] :negated_message The default error message
    #   generated for a matching object.
    # @option options [String] :negated_type The type of the error generated for
    #    a matching object.
    # @option options [String] :type The type of the error generated for a
    #    non-matching object.
    def initialize(**options)
      self.options = options
    end

    # @return [Hash<Symbol, Object>] Configuration options for the constraint.
    attr_reader :options

    # Performs an equality comparison.
    #
    # @param other [Object] The object to compare.
    #
    # @return [true, false] true if the other object has the same class and
    #   options; otherwise false.
    def ==(other)
      other.class == self.class && options == other.options
    end

    # Produces a shallow copy of the constraint.
    #
    # @param freeze [true, false, nil] If true or false, sets the frozen status
    #   of the cloned constraint; otherwise, copies the frozen status of the
    #   original. Defaults to nil.
    #
    # @return [Stannum::Constraints::Base] the cloned constraint.
    def clone(freeze: nil)
      super.copy_properties(self)
    end

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
    # @param actual [Object] The object to match.
    #
    # @return [true, false] false if the object matches the expected properties
    #   or behavior, otherwise true.
    #
    # @see #matches?
    def does_not_match?(actual) # rubocop:disable Naming/PredicatePrefix
      !matches?(actual)
    end

    # Produces a shallow copy of the constraint.
    #
    # @return [Stannum::Constraints::Base] the duplicated constraint.
    def dup
      super.copy_properties(self)
    end

    # Generates an errors object for the given object.
    #
    # The errors object represents the difference between the given object and
    # the expected properties or behavior. It may be the same for all objects,
    # or different based on the details of the object or the constraint.
    #
    # @param actual [Object] The object to generate errors for.
    # @param errors [Stannum::Errors] The errors object to append errors to. If
    #   an errors object is not given, a new errors object will be created.
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
    # @return [Stannum::Errors] the given or generated errors object.
    #
    # @see #matches?
    # @see #negated_errors_for
    def errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new).add(type, message:)
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
    # @param actual [Object] The object to match.
    #
    # @see #errors_for
    # @see #matches?
    def match(actual)
      return [true, Stannum::Errors.new] if matches?(actual)

      [false, errors_for(actual)]
    end

    # @overload matches?(actual)
    #   Checks that the given object matches the constraint.
    #
    #   @param actual [Object] The object to match.
    #
    #   @return [true, false] true if the object matches the expected properties
    #     or behavior, otherwise false.
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
    # @see #does_not_match?
    def matches?(_actual)
      false
    end
    alias match? matches?

    # @return [String, nil] the default error message generated for a
    #   non-matching object.
    def message
      options[:message]
    end

    # Generates an errors object for the given object when negated.
    #
    # The errors object represents the difference between the given object and
    # the expected properties or behavior when the constraint is negated. It may
    # be the same for all objects, or different based on the details of the
    # object or the constraint.
    #
    # @param actual [Object] The object to generate errors for.
    # @param errors [Stannum::Errors] The errors object to append errors to. If
    #   an errors object is not given, a new errors object will be created.
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
    # @return [Stannum::Errors] the given or generated errors object.
    #
    # @see #does_not_match?
    # @see #errors_for
    def negated_errors_for(actual, errors: nil) # rubocop:disable Lint/UnusedMethodArgument
      (errors || Stannum::Errors.new)
        .add(negated_type, message: negated_message)
    end

    # Checks the given object against the constraint and returns errors, if any.
    #
    # This method checks the given object against the expected properties or
    # behavior. If the object matches the constraint, #negated_match will return
    # false and the generated errors for that object. If the object does not
    # match the constraint, #negated_match will return true.
    #
    # @param actual [Object] The object to match.
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
      return [true, Stannum::Errors.new] if does_not_match?(actual)

      [false, negated_errors_for(actual)]
    end

    # @return [String, nil] The default error message generated for a matching
    #   object.
    def negated_message
      options[:negated_message]
    end

    # @return [String] the error type generated for a matching object.
    def negated_type
      options.fetch(:negated_type, self.class::NEGATED_TYPE)
    end

    # @return [String] the error type generated for a non-matching object.
    def type
      options.fetch(:type, self.class::TYPE)
    end

    # Creates a copy of the constraint and updates the copy's options.
    #
    # @param options [Hash] The options to update.
    #
    # @return [Stannum::Constraints::Base] the copied constraint.
    def with_options(**options)
      dup.copy_properties(self, options: self.options.merge(options))
    end

    protected

    attr_writer :options

    def copy_properties(source, options: nil, **_)
      self.options = options || source.options.dup

      self
    end
  end
end
