# frozen_string_literal: true

require 'stannum/support'

module Stannum::Support
  # Shared functionality for coercing values to and from constraints.
  module Coercion
    class << self
      # Coerce a Class or Module to a Type constraint.
      #
      # @param value [Class, Module, Stannum::Constraints::Base, nil] The value
      #   to coerce.
      # @param allow_nil [true, false] If true, a nil value will be returned
      #   instead of raising an exception.
      # @param as [String] A short name for the coerced value, used in
      #   generating an error message. Defaults to "type".
      # @param options [Hash<Symbol, Object>] Configuration options for the
      #   constraint. Defaults to an empty Hash.
      #
      # @yield Builds a constraint from a Class or Module. If no block is given,
      #   creates a Stannum::Constraints::Type constraint.
      # @yieldparam value [Class, Module] The Class or Module used to build the
      #   constraint.
      # @yieldparam options [Hash<Symbol, Object>] Configuration options for the
      #   constraint. Defaults to an empty Hash.
      # @yieldreturn [Stannum::Constraints::Base] the generated constraint.
      def type_constraint(
        value,
        allow_nil: false,
        as:        'type',
        **options,
        &block
      )
        return nil if allow_nil && value.nil?

        if value.is_a?(Stannum::Constraints::Base)
          return value.with_options(**options)
        end

        if value.is_a?(Module)
          return build_type_constraint(value, **options, &block)
        end

        raise ArgumentError,
          "#{as} must be a Class or Module or a constraint",
          caller(1..-1)
      end

      private

      def build_type_constraint(value, **options)
        return yield(value, **options) if block_given?

        Stannum::Constraints::Type.new(value, **options)
      end
    end
  end
end
