# frozen_string_literal: true

require 'forwardable'

require 'stannum/constraints'

module Stannum::Constraints
  # A Delegator constraint delegates the constraint methods to a receiver.
  #
  # Use the Delegator constraint when the behavior of a constraint needs to
  # change based on the context. For example, a contract may use a Delegator
  # constraint to wrap changes made after the contract is first initialized.
  #
  # @example Using a Delegator constraint
  #   receiver   = Stannum::Constraints::Type.new(String)
  #   constraint = Stannum::Constraints::Delegator.new(receiver)
  #
  #   constraint.matches?('a string') #=> true
  #   constraint.matches?(:a_symbol)  #=> false
  #
  #   constraint.receiver = Stannum::Constraints::Type.new(Symbol)
  #
  #   constraint.matches?('a string') #=> false
  #   constraint.matches?(:a_symbol)  #=> true
  class Delegator < Stannum::Constraints::Base
    extend Forwardable

    # @param receiver [Stannum::Constraints::Base] The constraint that methods
    #   will be delegated to.
    def initialize(receiver)
      super()

      self.receiver = receiver
    end

    def_delegators :@receiver,
      :does_not_match?,
      :errors_for,
      :match,
      :matches?,
      :negated_errors_for,
      :negated_match,
      :negated_type,
      :options,
      :type

    alias match? matches?

    # @return [Stannum::Constraints::Base] the constraint that methods will be
    #   delegated to.
    attr_reader :receiver

    # @param value [Stannum::Constraints::Base] The constraint that methods
    #   will be delegated to.
    def receiver=(value)
      validate_receiver(value)

      @receiver = value
    end

    protected

    def update_errors_for(actual:, errors:)
      receiver.send(:update_errors_for, actual: actual, errors: errors)
    end

    def update_negated_errors_for(actual:, errors:)
      receiver.send(:update_negated_errors_for, actual: actual, errors: errors)
    end

    private

    def validate_receiver(receiver)
      return if receiver.is_a?(Stannum::Constraints::Base)

      raise ArgumentError,
        'receiver must be a Stannum::Constraints::Base',
        caller(1..-1)
    end
  end
end
