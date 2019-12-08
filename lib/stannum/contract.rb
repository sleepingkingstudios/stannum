# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum
  # @todo Document Stannum::Contract.
  class Contract < Stannum::Constraints::Base
    def initialize
      @constraints = []
    end

    # @!method errors_for(actual)
    #   @todo Document Stannum::Contract#add_constraint.

    # @!method negated_errors_for(actual)
    #   @todo Document Stannum::Contract#add_constraint.

    # @todo Document Stannum::Contract#add_constraint.
    def add_constraint(constraint)
      validate_constraint(constraint)

      @constraints << {
        constraint: constraint,
        property:   nil
      }

      self
    end

    # @todo Document Stannum::Contract#does_not_match?
    def does_not_match?(object)
      return true if constraints.empty?

      # rubocop:disable Lint/UnusedBlockArgument
      constraints.all? do |constraint:, property:|
        constraint.does_not_match?(object)
      end
      # rubocop:enable Lint/UnusedBlockArgument
    end

    # @todo Document Stannum::Contract#matches?
    def matches?(object)
      return true if constraints.empty?

      # rubocop:disable Lint/UnusedBlockArgument
      constraints.all? do |constraint:, property:|
        constraint.matches?(object)
      end
      # rubocop:enable Lint/UnusedBlockArgument
    end
    alias match? matches?

    protected

    def update_errors_for(actual:, errors:)
      return errors if constraints.empty?

      constraints.reduce(errors) do |err, hsh|
        constraint = hsh.fetch(:constraint)

        next err if constraint.matches?(actual)

        constraint.update_errors_for(actual: actual, errors: err)
      end
    end

    def update_negated_errors_for(actual:, errors:)
      return errors if constraints.empty?

      constraints.reduce(errors) do |err, hsh|
        constraint = hsh.fetch(:constraint)

        next err if constraint.does_not_match?(actual)

        constraint.update_negated_errors_for(actual: actual, errors: err)
      end
    end

    private

    attr_reader :constraints

    def validate_constraint(constraint)
      return if constraint.is_a?(Stannum::Constraints::Base)

      raise ArgumentError, 'must be an instance of Stannum::Constraints::Base'
    end
  end
end
