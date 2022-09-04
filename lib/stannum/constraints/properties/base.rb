# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbelt'

require 'stannum/constraints/properties'

module Stannum::Constraints::Properties
  # Abstract base class for property constraints.
  class Base < Stannum::Constraints::Base
    # Default parameter names to filter out of errors.
    FILTERED_PARAMETERS = %i[
      passw
      secret
      token
      _key
      crypt
      salt
      certificate
      otp
      ssn
    ].freeze

    # @param property_names [Array<String, Symbol>] the name or names of the
    #   properties to match.
    # @param options [Hash<Symbol, Object>] configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @option options allow_empty [true, false] if true, will match against an
    #   object with empty property values, such as an empty string.
    # @option options allow_nil [true, false] if true, will match against an
    #   object with nil property values.
    def initialize(*property_names, **options)
      @property_names = property_names

      validate_property_names

      super(
        allow_empty:    !!options[:allow_empty],
        allow_nil:      !!options[:allow_nil],
        property_names: property_names,
        **options
      )
    end

    # @return [Array<String, Symbol>] the name or names of the properties to
    #   match.
    attr_reader :property_names

    # @return [true, false] if true, will match against an object with empty
    #   property values, such as an empty string.
    def allow_empty?
      options[:allow_empty]
    end

    # @return [true, false] if true, will match against an object with nil
    #   property values.
    def allow_nil?
      options[:allow_nil]
    end

    private

    def can_match_properties?(actual)
      actual.respond_to?(:[])
    end

    def each_property(actual)
      return to_enum(__method__, actual) unless block_given?

      property_names.each do |property_name|
        yield property_name, actual[property_name]
      end
    end

    def empty?(value)
      value.respond_to?(:empty?) && value.empty?
    end

    def filter_parameters?
      return @filter_parameters unless @filter_parameters.nil?

      filters = filtered_parameters.map { |param| Regexp.new(param.to_s) }

      @filter_parameters =
        property_names.any? do |property_name|
          filters.any? { |filter| filter.match?(property_name.to_s) }
        end
    end

    def filtered_parameters
      return Rails.configuration.filter_parameters if defined?(Rails)

      FILTERED_PARAMETERS
    end

    def invalid_object_errors(errors)
      errors.add(
        Stannum::Constraints::Signature::TYPE,
        methods: %i[[]],
        missing: %i[[]]
      )
    end

    def skip_property?(value)
      (allow_empty? && empty?(value)) || (allow_nil? && value.nil?)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def validate_property_names
      if property_names.empty?
        raise ArgumentError, "property names can't be empty"
      end

      property_names.each.with_index do |property_name, index|
        tools
          .assertions
          .validate_name(property_name, as: "property name at #{index}")
      end
    end
  end
end
