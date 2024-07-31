# frozen_string_literal: true

require 'stannum/entities'

module Stannum::Entities
  # Abstract module for handling heterogenous entity properties.
  #
  # This module provides a base for accessing and mutating entity properties
  # such as attributes and associations.
  module Properties
    MEMORY_ADDRESS_PATTERN = /0x([0-9a-f]+)/
    private_constant :MEMORY_ADDRESS_PATTERN

    # @param properties [Hash] the properties used to initialize the entity.
    def initialize(**properties)
      set_properties(properties, force: true)
    end

    # Compares the entity with the other object.
    #
    # The other object must be an instance of the current class. In addition,
    # the properties hashes of the two objects must be equal.
    #
    # @return true if the object is a matching entity.
    def ==(other)
      return false unless other.class == self.class

      properties == other.properties
    end

    # Retrieves the property with the given key.
    #
    # @param property [String, Symbol] The property key.
    #
    # @return [Object] the value of the property.
    #
    # @raise ArgumentError if the key is not a valid property.
    def [](property)
      tools.assertions.validate_name(property, as: 'property')

      get_property(property)
    end

    # Sets the given property to the given value.
    #
    # @param property [String, Symbol] The property key.
    # @param value [Object] The value for the property.
    #
    # @raise ArgumentError if the key is not a valid property.
    def []=(property, value)
      tools.assertions.validate_name(property, as: 'property')

      set_property(property, value)
    end

    # Updates the struct's properties with the given values.
    #
    # This method is used to update some (but not all) of the properties of the
    # struct. For each key in the hash, it calls the corresponding writer method
    # with the value for that property. If the value is nil, this will set the
    # property value to the default for that property.
    #
    # Any properties that are not in the given hash are unchanged.
    #
    # If the properties hash includes any keys that do not correspond to an
    # property, the struct will raise an error.
    #
    # @param properties [Hash] The initial properties for the struct.
    #
    # @raise ArgumentError if the key is not a valid property.
    #
    # @see #properties=
    def assign_properties(properties)
      unless properties.is_a?(Hash)
        raise ArgumentError, 'properties must be a Hash'
      end

      set_properties(properties, force: false)
    end
    alias assign assign_properties

    # @return [String] a string representation of the entity and its properties.
    def inspect
      inspect_with_options
    end

    # @param options [Hash] options for inspecting the entity.
    #
    # @option options memory_address [Boolean] if true, displays the memory
    #   address of the object (as per Object#inspect). Defaults to false.
    # @option options properties [Boolean] if true, displays the entity
    #   properties. Defaults to true.
    #
    # @return [String] a string representation of the entity and its properties.
    def inspect_with_options(**options)
      address = options[:memory_address] ? ":#{memory_address}" : ''
      mapped  = inspect_properties(**options)

      "#<#{self.class.name}#{address}#{mapped}>"
    end

    # Collects the entity properties.
    #
    # @return [Hash<String, Object>] the entity properties.
    def properties
      {}
    end

    # Replaces the entity's properties with the given values.
    #
    # This method is used to update all of the properties of the entity. For
    # each property, the writer method is called with the value from the hash,
    # or nil if the corresponding key is not present in the hash. Any nil or
    # missing values set the property value to that property's default value, if
    # any.
    #
    # If the properties hash includes any keys that do not correspond to a valid
    # property, the entity will raise an error.
    #
    # @param properties [Hash] the properties to assign to the entity.
    #
    # @raise ArgumentError if any key is not a valid property.
    #
    # @see #assign_properties
    def properties=(properties)
      unless properties.is_a?(Hash)
        raise ArgumentError, 'properties must be a Hash'
      end

      set_properties(properties, force: true)
    end

    # Returns a Hash representation of the entity.
    #
    # @return [Hash<String, Object>] the entity properties.
    #
    # @see #properties
    def to_h
      properties
    end

    private

    def bisect_properties(properties, expected)
      matching     = {}
      non_matching = {}

      properties.each do |key, value|
        if valid_property_key?(key) && expected.key?(key.to_s)
          matching[key.to_s] = value
        else
          non_matching[key] = value
        end
      end

      [matching, non_matching]
    end

    def get_property(key)
      raise ArgumentError, "unknown property #{key.inspect}"
    end

    def handle_invalid_properties(properties, as: 'property')
      properties.each_key do |key|
        tools.assertions.assert_name(key, as:, error_class: ArgumentError)
      end

      raise ArgumentError, invalid_properties_message(properties, as:)
    end

    def inspect_properties(**)
      ''
    end

    def invalid_properties_message(properties, as: 'property')
      "unknown #{tools.int.pluralize(properties.size, as)} " +
        properties.keys.map(&:inspect).join(', ')
    end

    def memory_address
      Object
        .instance_method(:inspect)
        .bind(self)
        .call
        .match(MEMORY_ADDRESS_PATTERN)[1]
    end

    def set_property(key, _)
      raise ArgumentError, "unknown property #{key.inspect}"
    end

    def set_properties(properties, **_)
      return if properties.empty?

      handle_invalid_properties(properties)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def valid_property_key?(key)
      return false unless key.is_a?(String) || key.is_a?(Symbol)

      !key.empty?
    end
  end
end
