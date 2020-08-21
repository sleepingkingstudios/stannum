# frozen_string_literal: true

require 'forwardable'

require 'stannum/structs/attribute'

module Stannum::Structs
  # Abstract class for defining attribute methods for a struct.
  #
  # @see Stannum::Structs::Attribute.
  class Attributes < Module
    extend  Forwardable
    include Enumerable

    def initialize
      @attributes = {}
      contract    = Stannum::Contracts::IndifferentHashContract.new

      const_set(:Contract, contract)
    end

    # @!method each
    #   Iterates through the the attributes by name and attribute object.
    #
    #   @yieldparam name [String] The name of the attribute.
    #   @yieldparam attribute [Stannum::Structs::Attribute] The attribute object.

    # @!method each_key
    #   Iterates through the the attributes by name.
    #
    #   @yieldparam name [String] The name of the attribute.

    # @!method each_value
    #   Iterates through the the attributes by attribute object.
    #
    #   @yieldparam attribute [Stannum::Structs::Attribute] The attribute
    #     object.

    def_delegators :attributes,
      :each,
      :each_key,
      :each_value

    # Retrieves the named attribute object.
    #
    # @param key [String, Symbol] The name of the requested attribute.
    #
    # @return [Stannum::Structs::Attribute] The attribute object.
    #
    # @raise ArgumentError if the key is invalid.
    # @raise KeyError if the attribute is not defined.
    def [](key)
      validate_key(key)

      attributes.fetch(key.to_s)
    end

    # Contract for validating a data hash against the attributes.
    #
    # @return [Stannum::Contract]
    def contract
      self::Contract
    end

    # rubocop:disable Metrics/MethodLength

    # @api private
    #
    # Defines an attribute and adds the attribute to the contract.
    #
    # This method should not be called directly. Instead, define attributes via
    # the Struct.attribute class method.
    #
    # @see Stannum::Struct
    def define_attribute(name:, options:, type:)
      attribute = Stannum::Structs::Attribute.new(
        name:    name,
        options: options,
        type:    type
      )

      if @attributes.key?(attribute.name)
        raise ArgumentError, "attribute #{name.inspect} already exists"
      end

      define_constraint(attribute)
      define_reader(attribute.name, attribute.reader_name)
      define_writer(attribute.name, attribute.writer_name, attribute.default)

      @attributes[attribute.name] = attribute
    end
    # rubocop:enable Metrics/MethodLength

    # Checks if the given attribute is defined.
    #
    # @param key [String, Symbol] the name of the attribute to check.
    #
    # @return [Boolean] true if the attribute is defined; otherwise false.
    def key?(key)
      validate_key(key)

      attributes.key?(key.to_s)
    end
    alias has_key? key?

    # @private
    def own_attributes
      @attributes
    end

    private

    def attributes
      ancestors
        .reverse_each
        .select { |mod| mod.is_a?(Stannum::Structs::Attributes) }
        .map(&:own_attributes)
        .reduce(&:merge)
    end

    def define_constraint(attribute)
      constraint = Stannum::Constraints::Type.new(attribute.type)

      self::Contract.add_constraint(
        constraint,
        property:      attribute.reader_name,
        property_type: :key
      )
    end

    def define_reader(attr_name, reader_name)
      define_method(reader_name) { @attributes[attr_name] }
    end

    def define_writer(attr_name, writer_name, default_value)
      define_method(writer_name) do |value|
        @attributes[attr_name] = value.nil? ? default_value : value
      end
    end

    def included(other)
      super

      return unless other.is_a?(Stannum::Structs::Attributes)

      other::Contract.include(self::Contract)
    end

    def validate_key(key)
      raise ArgumentError, "key can't be blank" if key.nil?

      unless key.is_a?(String) || key.is_a?(Symbol)
        raise ArgumentError, 'key must be a String or Symbol'
      end

      raise ArgumentError, "key can't be blank" if key.to_s.empty?
    end
  end
end
