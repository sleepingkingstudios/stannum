# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Constraint for matching objects by the methods they respond to.
  #
  # @example
  #   constraint = Stannum::Constraints::Signature.new(:[], :keys)
  #
  #   constraint.matches?(Object.new) #=> false
  #   constraint.matches?([])         #=> false
  #   constraint.matches?({})         #=> true
  class Signature < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.has_methods'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.does_not_have_methods'

    # @param expected_methods [Array<String, Symbol>] The methods the object is
    #   expected to respond to.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(*expected_methods, **options)
      validate_expected_methods(expected_methods)

      @expected_methods = expected_methods

      super(expected_methods: expected_methods, **options)
    end

    # @return [Array<String, Symbol>] the methods the object is expected to
    #   respond to.
    attr_reader :expected_methods

    # @return [true, false] true if the object does not respond to any of the
    #   expected methods; otherwise false.
    def does_not_match?(actual)
      each_missing_method(actual).to_a == expected_methods
    end

    # @return [true, false] true if the object responds to all of the expected
    #   methods; otherwise false.
    def matches?(actual)
      each_missing_method(actual).none?
    end
    alias match? matches?

    private

    def each_missing_method(actual)
      return enum_for(:each_missing_method, actual) unless block_given?

      expected_methods.each do |method_name|
        yield method_name unless actual.respond_to?(method_name)
      end
    end

    def update_errors_for(actual:, errors:)
      errors.add(
        type,
        methods: expected_methods,
        missing: each_missing_method(actual).to_a
      )
    end

    def update_negated_errors_for(actual:, errors:)
      errors.add(
        negated_type,
        methods: expected_methods,
        missing: each_missing_method(actual).to_a
      )
    end

    def validate_expected_methods(expected_methods)
      if expected_methods.empty?
        raise ArgumentError, 'expected methods can\'t be blank', caller(1..-1)
      end

      return if expected_methods.all? do |method_name|
        method_name.is_a?(String) || method_name.is_a?(Symbol)
      end

      raise ArgumentError, 'expected method must be a String or Symbol'
    end
  end
end
