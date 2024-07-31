# frozen_string_literal: true

begin
  require 'rspec/sleeping_king_studios/matchers/core/deep_matcher'
rescue NameError
  # Optional dependency.
end

require 'stannum/constraints/parameters/extra_keywords'
require 'stannum/rspec'
require 'stannum/support/coercion'

module Stannum::RSpec
  # Asserts that the command validates the given method parameter.
  class ValidateParameterMatcher # rubocop:disable Metrics/ClassLength
    include RSpec::Mocks::ExampleMethods

    class InvalidParameterHandledError < StandardError; end
    private_constant :InvalidParameterHandledError

    class << self
      # @private
      def add_parameter_mapping(map:, match:)
        raise ArgumentError, 'map must be a Proc'   unless map.is_a?(Proc)
        raise ArgumentError, 'match must be a Proc' unless match.is_a?(Proc)

        parameter_mappings << { match:, map: }
      end

      # @private
      def map_parameters(actual:, method_name:)
        parameter_mappings.each do |keywords|
          match = keywords.fetch(:match)
          map   = keywords.fetch(:map)

          next unless match.call(actual:, method_name:)

          return map.call(actual:, method_name:)
        end

        unwrapped_method(actual:, method_name:).parameters
      end

      private

      def default_parameter_mappings
        [
          {
            match: lambda do |actual:, method_name:, **_|
              actual.is_a?(Class) && method_name == :new
            end,
            map:   lambda do |actual:, **_|
              actual.instance_method(:initialize).parameters
            end
          }
        ]
      end

      def parameter_mappings
        @parameter_mappings ||= default_parameter_mappings
      end

      def unwrapped_method(actual:, method_name:)
        method      = actual.method(method_name)
        validations = Stannum::ParameterValidation::MethodValidations

        until method.nil?
          return method unless method.owner.is_a?(validations)

          method = method.super_method
        end
      end
    end

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

    # @return [Hash] the configured parameters to match.
    attr_reader :parameters

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
          "##{method_name} does not expect a #{parameter_name.inspect} " \
          "#{parameter_type}"
        when :valid_parameter_value
          "#{valid_value.inspect} is a valid value for the " \
          "#{parameter_name.inspect} #{parameter_type}"
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
    def matches?(actual) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      @actual         = actual
      @failure_reason = nil

      return false unless supports_parameter_validation?
      return false unless responds_to_method?
      return false unless validates_method?
      return false unless method_has_parameter?

      if @expected_constraint.nil? && @parameters.nil? && @parameter_value.nil?
        return validates_method_parameter?
      end

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

    # Specifies custom parameters to test.
    #
    # The matcher will pass if and only if the method fails validation with the
    # specified parameters.
    #
    # @param arguments [Array] A list of arguments to test.
    # @param keywords [Hash] A hash of keywords to test.
    #
    # @return [Stannum::RSpec::ValidateParameterMatcher] the matcher.
    def with_parameters(*arguments, **keywords, &block)
      if @parameter_value
        raise 'cannot use both #with_parameters and #with_value'
      end

      @parameters = [
        arguments,
        keywords,
        block
      ]

      self
    end

    # Specifies an invalid value for the parameter.
    #
    # @param parameter_value [Object] The invalid value for the validated
    #   parameter.
    #
    # @return [Stannum::RSpec::ValidateParameterMatcher] the matcher.
    def with_value(parameter_value)
      raise 'cannot use both #with_parameters and #with_value' if @parameters

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
        @parameter_index = find_parameter_index(method_parameters)

        [[*Array.new(parameter_index, nil), parameter_value], {}, nil]
      when :keyword
        [[], { parameter_name => parameter_value }, nil]
      when :block
        [[], {}, parameter_value]
      end
    end

    def call_validated_method
      arguments, keywords, block = @parameters || build_parameters

      mock_validation_handler do
        actual.send(method_name, *arguments, **keywords, &block)
      rescue InvalidParameterHandledError
        # Do nothing.
      end
    rescue ArgumentError
      # Do nothing.
    end

    def disallow_fluent_options! # rubocop:disable Metrics/MethodLength
      unless @expected_constraint.nil?
        raise RuntimeError,
          '#does_not_match? with #using_constraint is not supported',
          caller[1..]
      end

      unless @parameters.nil?
        raise RuntimeError,
          '#does_not_match? with #with_parameters is not supported',
          caller[1..]
      end

      return if @parameter_value.nil?

      raise RuntimeError,
        '#does_not_match? with #with_value is not supported',
        caller[1..]
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
        Stannum::Constraints::Parameters::ExtraArguments::TYPE
      extra_keywords_type =
        Stannum::Constraints::Parameters::ExtraKeywords::TYPE

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

      @expected_errors = expected_constraint.errors_for(parameter_value)

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
      @method_parameters ||=
        self.class.map_parameters(actual:, method_name:)
    end

    def mock_validation_handler
      @validation_handler_called = false
      @validation_errors         = nil

      allow(actual).to receive(:handle_invalid_parameters) do |keywords|
        @validation_handler_called = true
        @validation_errors         = keywords[:errors]

        raise InvalidParameterHandledError
      end

      yield

      allow(actual).to receive(:handle_invalid_parameters).and_call_original
    end

    def responds_to_method?
      return true if actual.respond_to?(method_name)

      @failure_reason = :does_not_respond_to_method

      false
    end

    def scoped_errors(indexed: false) # rubocop:disable Metrics/MethodLength
      return [] if @validation_errors.nil?

      case parameter_type
      when :argument
        @parameter_index ||= find_parameter_index(method_parameters)
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

    def valid_value # rubocop:disable Metrics/MethodLength
      return @parameter_value if @parameter_value

      return nil unless @parameters

      case parameter_type
      when :argument
        @parameter_index ||= find_parameter_index(method_parameters)

        parameters[0][parameter_index]
      when :keyword
        parameters[1][parameter_name]
      when :block
        parameters[2]
      end
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

    def validates_method_parameter? # rubocop:disable Metrics/MethodLength
      validates_parameter =
        case parameter_type
        when :argument
          validates_method_argument?
        when :keyword
          validates_method_keyword?
        when :block
          validates_method_block?
        end

      return true if validates_parameter

      @failure_reason = :parameter_not_validated

      false
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
