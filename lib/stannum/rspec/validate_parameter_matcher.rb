# frozen_string_literal: true

begin
  require 'rspec/sleeping_king_studios/matchers/core/deep_matcher'
rescue NameError # rubocop:disable Lint/HandleExceptions
  # Optional dependency.
end

require 'stannum/rspec'
require 'stannum/support/coercion'

module Stannum::RSpec
  # Asserts that the command validates the given method parameter.
  class ValidateParameterMatcher # rubocop:disable Metrics/ClassLength
    include RSpec::Mocks::ExampleMethods

    # @param method_name [String, Symbol] The name of the method with validated
    #   parameters.
    # @param parameter_name [String, Symbol] The name of the validated method
    #   parameter.
    def initialize(method_name:, parameter_name:)
      @method_name    = method_name.intern
      @parameter_name = parameter_name.intern
    end

    # @return [Stannum::Constraints::Base, nil] the constraint used to generate
    #   the expected error(s).
    attr_reader :expected_constraint

    # @return [String, Symbol] the name of the method with validated parameters.
    attr_reader :method_name

    # @return [String, Symbol] the name of the validated method parameter.
    attr_reader :parameter_name

    # @return [Object] the invalid value for the validated parameter.
    attr_reader :parameter_value

    # @return [String] a short description of the matcher and expected
    #   properties.
    def description
      "validate the #{parameter_name.inspect} #{parameter_type || 'parameter'}"
    end

    # Asserts that the object does not validate the specified method parameter.
    #
    # @param actual [Object] The object to match.
    #
    # @return [true, false] false if the object validates the parameter,
    #   otherwise true.
    def does_not_match?(actual)
      disallow_fluent_options!

      @actual         = actual
      @failure_reason = nil

      return true  unless supports_parameter_validation?
      return false unless responds_to_method?
      return true  unless validates_method?
      return false unless method_has_parameter?

      !validates_method_parameter?
    end

    # @return [String] a summary message describing a failed expectation.
    def failure_message # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      message = "expected ##{method_name} to #{description}"
      reason  =
        case @failure_reason
        when :does_not_respond_to_method
          "the object does not respond to ##{method_name}"
        when :does_not_support_parameter_validation
          'the object does not implement parameter validation'
        when :does_not_validate_method
          "the object does not validate the parameters of ##{method_name}"
        when :errors_do_not_match
          "the errors do not match:\n\n#{equality_matcher_failure_message}"
        when :method_does_not_have_parameter
          "##{method_name} does not have a #{parameter_name.inspect} parameter"
        when :parameter_not_validated
          "##{method_name} does not expect a #{parameter_name.inspect}" \
          " #{parameter_type}"
        when :valid_parameter_value
          "#{parameter_value.inspect} is a valid value for the" \
          " #{parameter_name.inspect} #{parameter_type}"
        end

      [message, reason].compact.join(', but ')
    end

    # @return [String] a summary message describing a failed negated
    #   expectation.
    def failure_message_when_negated
      message = "expected ##{method_name} not to #{description}"
      reason  =
        case @failure_reason
        when :does_not_respond_to_method
          "the object does not respond to ##{method_name}"
        when :method_does_not_have_parameter
          "##{method_name} does not have a #{parameter_name.inspect} parameter"
        end

      [message, reason].compact.join(', but ')
    end

    # Asserts that the object validates the specified method parameter.
    #
    # @param actual [Object] The object to match.
    #
    # @return [true, false] true if the object validates the parameter,
    #   otherwise false.
    def matches?(actual) # rubocop:disable Metrics/CyclomaticComplexity
      @actual         = actual
      @failure_reason = nil

      return false unless supports_parameter_validation?
      return false unless responds_to_method?
      return false unless validates_method?
      return false unless method_has_parameter?

      call_validated_method

      return false if extra_parameter?
      return false if valid_parameter?

      matches_expected_error?
    end

    # Specifies a constraint or type used to validate the parameter.
    #
    # @param constraint [Stannum::Constraints::Base, Class, Module] The
    #   constraint or type.
    #
    # @return [Stannum::RSpec::ValidateParameterMatcher] the matcher.
    def using_constraint(constraint, **options)
      @expected_constraint = Stannum::Support::Coercion.type_constraint(
        constraint,
        as: 'constraint',
        **options
      )

      self
    end

    # Specifies an invalid value for the parameter.
    #
    # @param parameter_value [Object] The invalid value for the validated
    #   parameter.
    #
    # @return [Stannum::RSpec::ValidateParameterMatcher] the matcher.
    def with_value(parameter_value)
      @parameter_value = parameter_value

      self
    end

    private

    attr_reader :actual

    attr_reader :parameter_index

    attr_reader :parameter_type

    def build_parameters
      case parameter_type
      when :argument
        parameters       = method_parameters
        @parameter_index = find_parameter_index(parameters)

        [[*Array.new(parameter_index, nil), parameter_value], {}, nil]
      when :keyword
        [[], { parameter_name => parameter_value }, nil]
      when :block
        [[], {}, parameter_value]
      end
    end

    def call_validated_method
      arguments, keywords, block = build_parameters

      mock_validation_handler do
        actual.send(method_name, *arguments, **keywords, &block)
      end
    rescue ArgumentError # rubocop:disable Lint/HandleExceptions
    end

    def disallow_fluent_options!
      unless @expected_constraint.nil?
        raise RuntimeError,
          '#does_not_match? with #using_constraint is not supported',
          caller[1..-1]
      end

      return if @parameter_value.nil?

      raise RuntimeError,
        '#does_not_match? with #with_value is not supported',
        caller[1..-1]
    end

    def equality_matcher
      RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
        .new(@expected_errors.to_a)
    rescue NameError
      # :nocov:
      RSpec::Matchers::BuiltIn::Eq.new(@expected_errors.to_a)
      # :nocov:
    end

    def equality_matcher_failure_message
      equality_matcher
        .tap { |matcher| matcher.matches?(scoped_errors.to_a) }
        .failure_message
    end

    def extra_parameter?
      extra_arguments_type =
        Stannum::Contracts::Parameters::ArgumentsContract::EXTRA_ARGUMENTS_TYPE
      extra_keywords_type =
        Stannum::Contracts::Parameters::KeywordsContract::EXTRA_KEYWORDS_TYPE

      return false unless scoped_errors(indexed: true).any? do |error|
        error[:type] == extra_arguments_type ||
        error[:type] == extra_keywords_type
      end

      @failure_reason = :parameter_not_validated

      true
    end

    def find_parameter_index(parameters)
      parameters.index { |_, name| name == parameter_name }
    end

    def find_parameter_type
      parameters = method_parameters
      type, _    = parameters.find { |_, name| name == parameter_name }

      case type
      when :req, :opt
        :argument
      when :keyreq, :key
        :keyword
      when :block
        :block
      end
    end

    def matches_expected_error?
      return true unless expected_constraint

      @expected_errors = expected_constraint.errors_for(actual)

      if @expected_errors.all? { |error| scoped_errors.include?(error) }
        return true
      end

      @failure_reason = :errors_do_not_match

      false
    end

    def method_has_parameter?
      @parameter_type = find_parameter_type

      return true unless parameter_type.nil?

      @failure_reason = :method_does_not_have_parameter

      false
    end

    def method_parameters
      if actual.is_a?(Class) && method_name == :new
        return actual.instance_method(:initialize).parameters
      end

      # Call #super_method to bypass the validation wrapper.
      actual.method(method_name).super_method.parameters
    end

    def mock_validation_handler
      @validation_handler_called = false
      @validation_errors         = nil

      allow(actual).to receive(:handle_invalid_parameters) \
      do |errors:, **_|
        @validation_handler_called = true
        @validation_errors         = errors
      end

      yield

      allow(actual).to receive(:handle_invalid_parameters).and_call_original
    end

    def responds_to_method?
      return true if actual.respond_to?(method_name)

      @failure_reason = :does_not_respond_to_method

      false
    end

    def scoped_errors(indexed: false)
      case parameter_type
      when :argument
        parameter_key = indexed ? parameter_index : parameter_name

        @validation_errors[:arguments][parameter_key]
      when :keyword
        @validation_errors[:keywords][parameter_name]
      when :block
        @validation_errors[:block]
      end
    end

    def supports_parameter_validation?
      return true if actual.is_a?(Stannum::ParameterValidation)

      @failure_reason = :does_not_support_parameter_validation

      false
    end

    def valid_parameter?
      return false unless scoped_errors.empty?

      @failure_reason = :valid_parameter_value

      true
    end

    def validates_method?
      return true if validation_contracts.include?(method_name)

      @failure_reason = :does_not_validate_method

      false
    end

    def validates_method_argument?
      contract = validation_contracts.fetch(method_name)

      contract.send(:arguments_contract).each_constraint.any? do |definition|
        definition.property_name == parameter_name
      end
    end

    def validates_method_block?
      contract = validation_contracts.fetch(method_name)

      !contract.send(:block_constraint).nil?
    end

    def validates_method_keyword?
      contract = validation_contracts.fetch(method_name)

      contract.send(:keywords_contract).each_constraint.any? do |definition|
        definition.property_name == parameter_name
      end
    end

    def validates_method_parameter?
      case parameter_type
      when :argument
        validates_method_argument?
      when :keyword
        validates_method_keyword?
      when :block
        validates_method_block?
      end
    end

    def validation_contracts
      if actual.is_a?(Module)
        actual.singleton_class::MethodValidations.contracts
      else
        actual.class::MethodValidations.contracts
      end
    end
  end
end
