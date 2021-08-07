# frozen_string_literal: true

require 'stannum'

module Stannum
  # Provides a DSL for validating method parameters.
  #
  # Use the .validate_parameters method to define parameter validation for an
  # instance method of the class or module.
  #
  # Ruby does not distinguish between an explicit nil versus an undefined value
  # in an Array or Hash, but does distinguish between a nil value and a missing
  # parameter. Be careful when validating methods with optional or default
  # arguments or keywords:
  #
  # * If the actual value can be nil, or if the default parameter is nil, then
  #   use the optional: true option. This will match an empty arguments list, or
  #   an arguments list with nil as the first value:
  #
  #     def method_with_optional_argument(name: nil)
  #       @name = name || 'Alan Bradley'
  #     end
  #
  #     validate_parameters(:method_with_optional_argument) do
  #       argument :name, optional: true
  #     end
  #
  # * If the default parameter is any other value, then use the default: true
  #   option. This will match an empty arguments list, but not an arguments list
  #   with nil as the first value:
  #
  #     def method_with_default_argument(role: 'User')
  #       @role = role
  #     end
  #
  #     validate_parameters(:method_with_default_argument) do
  #       argument :role, default: true
  #     end
  #
  # @example Validating Parameters
  #   class PerformAction
  #     include Stannum::ParameterValidation
  #
  #     def perform(action, record_class = nil, user:, role: 'User')
  #     end
  #
  #     validate_parameters(:perform) do
  #       argument :action,       Symbol
  #       argument :record_class, Class,  optional: true
  #       keyword  :role,         String, default:  true
  #       keyword  :user,         Stannum::Constraints::Type.new(User)
  #     end
  #   end
  #
  # @example Validating Class Methods
  #   module Authorization
  #     extend Stannum::ParameterValidation
  #
  #     class << self
  #       def authorize_user(user, role: 'User')
  #       end
  #
  #       validate_parameters(:authorize_user) do
  #         argument :user, User
  #         argument :role, String, default: true
  #       end
  #     end
  #   end
  #
  # @see Stannum::Contracts::ParametersContract.
  module ParameterValidation
    # @api private
    #
    # Value used to indicate a successful validation of the parameters.
    VALIDATION_SUCCESS = Object.new.freeze

    # @api private
    #
    # Base class for modules that handle tracking validated methods.
    class MethodValidations < Module
      def initialize
        super

        @contracts = {}
      end

      def add_contract(method_name, contract)
        @contracts[method_name] = contract
      end

      # @return [Hash] the validation contracts defined for the class.
      def contracts
        ancestors
          .select do |ancestor|
            ancestor.is_a? Stannum::ParameterValidation::MethodValidations
          end
          .map(&:own_contracts)
          .reduce(:merge)
      end

      # @api private
      def own_contracts
        @contracts
      end
    end

    # Defines a DSL for validating method parameters.
    #
    # @see ParameterValidation.
    module ClassMethods
      # rubocop:disable Metrics/MethodLength

      # Creates a validation contract and wraps the named method.
      #
      # The provided block is used to create a ParametersContract, and supports
      # the same DSL used to define one.
      #
      # @see Stannum::Contracts::ParametersContract
      def validate_parameters(method_name, &validations)
        method_name = method_name.intern
        contract    = Stannum::Contracts::ParametersContract.new(&validations)

        self::MethodValidations.add_contract(method_name, contract)

        self::MethodValidations.define_method(method_name) \
        do |*arguments, **keywords, &block|
          result = match_parameters_to_contract(
            arguments:   arguments,
            block:       block,
            contract:    contract,
            keywords:    keywords,
            method_name: method_name
          )

          return result unless result == VALIDATION_SUCCESS

          if keywords.empty?
            super(*arguments, &block)
          else
            super(*arguments, **keywords, &block)
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      private

      def inherited(subclass)
        super

        Stannum::ParameterValidation.add_method_validations(subclass)

        subclass::MethodValidations.include(self::MethodValidations)
      end
    end

    class << self
      # @api private
      def add_method_validations(other)
        other.extend(ClassMethods)

        validations = MethodValidations.new

        other.const_set(:MethodValidations, validations)
        other.prepend(validations)
      end

      private

      def extended(other)
        super

        add_method_validations(other.singleton_class)
      end

      def included(other)
        super

        add_method_validations(other)
      end
    end

    private

    def handle_invalid_parameters(errors:, method_name:)
      error_message = "invalid parameters for ##{method_name}"
      error_message += ": #{errors.summary}" unless errors.empty?

      raise ArgumentError, error_message
    end

    def match_parameters_to_contract( # rubocop:disable Metrics/MethodLength
      contract:,
      method_name:,
      arguments: [],
      block:     nil,
      keywords:  {}
    )
      match, errors = contract.match(
        {
          arguments: arguments,
          keywords:  keywords,
          block:     block
        }
      )

      return VALIDATION_SUCCESS if match

      handle_invalid_parameters(
        errors:      errors,
        method_name: method_name
      )
    end
  end
end
