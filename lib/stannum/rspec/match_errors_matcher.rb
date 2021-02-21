# frozen_string_literal: true

begin
  require 'rspec/sleeping_king_studios/matchers/core/deep_matcher'
rescue NameError
  # :nocov:
  Kernel.warn 'WARNING: RSpec::SleepingKingStudios is a dependency for using' \
              ' the MatchErrorsMatcher or the #match_errors method.'
  # :nocov:
end

require 'stannum/errors'
require 'stannum/rspec'

module Stannum::RSpec
  # Asserts that the expected and actual errors are equal.
  class MatchErrorsMatcher
    # @param expected [Stannum::Errors] The expected errors.
    def initialize(expected)
      @expected = expected.to_a
    end

    # @return [String] a short description of the matcher and expected
    #   properties.
    def description
      'match the expected errors'
    end

    # Checks that the given errors do not match the expected errors.
    def does_not_match?(actual)
      @actual = actual.is_a?(Stannum::Errors) ? actual.to_a : actual

      errors? && deep_matcher.does_not_match?(@actual)
    end

    # @return [String] a summary message describing a failed expectation.
    def failure_message
      unless errors?
        return 'expected the errors to match the expected errors, but the' \
               ' object is not an array or Errors object'
      end

      deep_matcher.failure_message
    end

    # @return [String] a summary message describing a failed negated
    #   expectation.
    def failure_message_when_negated
      unless errors?
        return 'expected the errors not to match the expected errors, but the' \
               ' object is not an array or Errors object'
      end

      deep_matcher.failure_message_when_negated
    end

    # Checks that the given errors match the expected errors.
    #
    # Returns false if the object is not a Stannum::Errors instance or an Array.
    # Otherwise, it converts the expected and actual errors to arrays and
    # performs a deep match.
    #
    # @param actual [Object] The actual object to match.
    #
    # @return [Boolean] true if the actual errors match the expected errors.
    def matches?(actual)
      @actual = actual.is_a?(Stannum::Errors) ? actual.to_a : actual

      errors? && deep_matcher.matches?(@actual)
    end

    private

    def deep_matcher
      @deep_matcher ||=
        RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
        .new(@expected)
    end

    def errors?
      @actual.is_a?(Stannum::Errors) || @actual.is_a?(Array)
    end
  end
end
