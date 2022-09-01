# frozen_string_literal: true

require 'stannum'
require 'stannum/constraints/base'

module Stannum
  # Constraint wrapper that swaps negated and non-negated methods.
  class InvertedConstraint < Stannum::Constraints::Base
    INVERTED_OPTIONS = [
      %i[message negated_message].freeze,
      %i[type negated_type].freeze
    ].freeze
    private_constant :INVERTED_OPTIONS

    # @param constraint [Stannum::Constraints::Base] the constraint to invert.
    # @param options [Hash<Symbol, Object>] configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(constraint, **options)
      @constraint = constraint.with_options(**invert_options(options))

      super()
    end

    # @return [Stannum::Constraints::Base] the constraint to invert.
    attr_reader :constraint

    # Performs an equality comparison.
    #
    # @param other [Object] The object to compare.
    #
    # @return [true, false] true if the other object has the same class and the
    #   wrapped constraints are equal; otherwise false.
    def ==(other)
      other.class == self.class && constraint == other.constraint
    end

    # (see Stannum::Constraints::Base#clone)
    def clone(freeze: nil)
      super(freeze: freeze).copy_constraint
    end

    # (see Stannum::Constraints::Base#does_not_match?)
    def does_not_match?(actual)
      constraint.matches?(actual)
    end

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      constraint.negated_errors_for(actual, errors: errors)
    end

    # (see Stannum::Constraints::Base#matches?)
    def matches?(actual)
      constraint.does_not_match?(actual)
    end
    alias match? matches?

    # (see Stannum::Constraints::Base#negated_errors_for)
    def negated_errors_for(actual, errors: nil)
      constraint.errors_for(actual, errors: errors)
    end

    # (see Stannum::Constraints::Base#options)
    def options
      invert_options(constraint.options)
    end

    # (see Stannum::Constraints::Base#with_options)
    def with_options(**options)
      dup.copy_constraint(options: self.options.merge(options))
    end

    protected

    attr_writer :constraint

    def copy_constraint(options: {}, **_)
      self.constraint = constraint.with_options(invert_options(options))

      self
    end

    private

    def invert_options(options) # rubocop:disable Metrics/MethodLength
      return {} if options.empty?

      INVERTED_OPTIONS.each.with_object(options.dup) \
      do |(option, negated), inverted|
        if options.key?(option)
          inverted[negated] = options[option]
        else
          inverted.delete negated
        end

        if options.key?(negated)
          inverted[option] = options[negated]
        else
          inverted.delete option
        end
      end
    end
  end
end
