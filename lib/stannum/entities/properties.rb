# frozen_string_literal: true

require 'stannum/entities'

module Stannum::Entities
  # Abstract module for handling heterogenous entity properties.
  #
  # This module provides a base for accessing and mutating entity properties
  # such as attributes and associations.
  module Properties
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
    # @param key [String, Symbol] The property key.
    #
    # @return [Object] the value of the property.
    #
    # @raise ArgumentError if the key is not a valid property.
    def [](key)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      get_property(key)
    end

    # Sets the given property to the given value.
    #
    # @param key [String, Symbol] The property key.
    # @param value [Object] The value for the property.
    #
    # @raise ArgumentError if the key is not a valid property.
    def []=(key, value)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      set_property(key, value)
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
      mapped = inspectable_properties.reduce('') do |memo, (key, value)|
        memo + " #{key}: #{value.inspect}"
      end

      "#<#{self.class.name}#{mapped}>"
    end

    # Collects the entity properties.
    #
    # @param properties [Hash<String, Object>] the entity properties.
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
    # @see #assign_attributes
    def properties=(properties)
      unless properties.is_a?(Hash)
        raise ArgumentError, 'properties must be a Hash'
      end

      set_properties(properties, force: true)
    end

    private

    def bisect_properties(properties, expected)
      matching     = {}
      non_matching = {}

      properties.each do |key, value|
        if expected.key?(key.to_s)
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

    def inspectable_properties
      {}
    end

    def invalid_properties_message(properties, as: 'property')
      "unknown #{tools.int.pluralize(properties.size, as)} " +
        properties.keys.map(&:inspect).join(', ')
    end

    def set_property(key, _)
      raise ArgumentError, "unknown property #{key.inspect}"
    end

    def set_properties(properties, **_)
      return if properties.empty?

      raise ArgumentError, invalid_properties_message(properties)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
