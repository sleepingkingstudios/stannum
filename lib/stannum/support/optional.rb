# frozen_string_literal: true

require 'stannum/support'

module Stannum::Support
  # Methods for handling optional/required options.
  #
  # @api private
  module Optional
    class << self
      def resolve(
        optional:            nil,
        required:            nil,
        required_by_default: true,
        **options
      )
        default =
          validate_option(required_by_default, as: :required_by_default)

        options.merge(
          required: required?(
            default:  default,
            optional: validate_option(optional, as: :optional),
            required: validate_option(required, as: :required)
          )
        )
      end

      private

      def required?(default:, optional:, required:)
        return default if optional.nil? && required.nil?

        return !optional if required.nil?

        return required if optional.nil?

        return required unless required == optional

        raise ArgumentError, 'required and optional must match', caller(1..-1)
      end

      def validate_option(option, as:)
        return option if option.nil? || option == true || option == false

        raise ArgumentError, "#{as} must be true or false", caller(1..-1)
      end
    end

    # @return [true, false] false if the property accepts nil values, otherwise
    #   true.
    def optional?
      !options[:required]
    end

    # @return [true, false] true if the property accepts nil values, otherwise
    #   false.
    def required?
      options[:required]
    end

    private

    def resolve_required_option(**options)
      Stannum::Support::Optional.resolve(**options)
    end
  end
end
