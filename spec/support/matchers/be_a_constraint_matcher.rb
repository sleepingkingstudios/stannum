# frozen_string_literal: true

require 'rspec/sleeping_king_studios/matchers/core/deep_match'

require 'stannum/constraints/base'

require 'support/matchers'

module Spec::Support::Matchers
  class BeAConstraintMatcher
    include RSpec::Matchers::Composable

    # @param expected [Class, #matches?, nil] The expected constraint type. Can
    #   be a Class that extends Stannum::Constraint::Base or an RSpec matcher.
    #   Defaults to nil, which matches any constraint.
    def initialize(expected = nil)
      @expected         = expected
      @expected_options = {}
    end

    # @return [Class, #matches?, nil] The expected constraint type.
    attr_reader :expected

    # @return [Hash<Symbol, Object>] The expected options.
    attr_reader :expected_options

    # @return [String] A description of the expectation
    def description
      constraint_description + options_description
    end

    # @param actual [Object] The actual object.
    #
    # @return [true, false] False if the actual object matches the expected
    #   constraint and has the expected options (if any); otherwise true.
    def does_not_match?(actual)
      if expected_options?
        raise StandardError,
          '`expect().not_to be_a_constraint().with_options()` is not supported'
      end

      !matches?(actual)
    end

    # @return [String] The message displayed when the expectation does not match
    #   the actual object.
    def failure_message
      message = "expected #{actual.inspect} to #{constraint_description}"

      return "#{message}, but is not a constraint" unless constraint?

      if matches_constraint?
        message += ", but the options do not match:\n"

        return message + tools.str.indent(@options_matcher.failure_message, 2)
      end

      if expected.is_a?(Class)
        return message + ", but is not an instance of #{expected}"
      end

      expected.failure_message
    end

    # @return [String] The message displayed when the negated expectation
    #   matches the the actual object.
    def failure_message_when_negated
      "expected #{actual.inspect} not to #{constraint_description}"
    end

    # @param actual [Object] The actual object.
    #
    # @return [true, false] True if the actual object matches the expected
    #   constraint and has the expected options (if any); otherwise false.
    def matches?(actual)
      @actual = actual

      constraint? && matches_constraint? && options_match?
    end

    # @param options [Hash<Symbol, Object>] The expected options.
    def with_options(**expected_options)
      @expected_options = expected_options

      self
    end

    private

    attr_reader :actual

    def constraint?
      actual.is_a?(Stannum::Constraints::Base)
    end

    def constraint_description
      return 'be a constraint' if expected.nil?

      return "be a #{expected.name}" if expected.is_a?(Class)

      expected.description
    end

    def expected_options?
      !expected_options.empty?
    end

    def matches_constraint?
      return actual.is_a?(Stannum::Constraints::Base) if expected.nil?

      return actual.is_a?(expected) if expected.is_a?(Class)

      expected.matches?(actual)
    end

    def options_description
      return '' unless expected_options?

      formatted_options =
        expected_options
        .map { |option, value| "#{option}: #{value.inspect}" }
        .join(', ')

      " with options #{formatted_options}"
    end

    def options_match?
      return true unless expected_options?

      @options_matcher =
        RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher.new(
          expected_options
        )

      @options_matcher.matches?(actual.options)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
