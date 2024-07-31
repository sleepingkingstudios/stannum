# frozen_string_literal: true

require 'forwardable'

module Stannum
  # Abstract class for defining property methods for an entity.
  #
  # @see Stannum::Attribute.
  class Schema < Module
    extend  Forwardable
    include Enumerable

    # @param property_class [Class] the class representing the elements of the
    #   schema.
    # @param property_name [String, Symbol] the name of the schema elements.
    def initialize(property_class:, property_name:)
      super()

      tools.assertions.validate_class(property_class, as: 'property class')
      tools.assertions.validate_name(property_name, as: 'property name')

      @properties     = {}
      @property_class = property_class
      @property_name  = property_name.to_s
    end

    # @return [Class] the class representing the elements of the schema.
    attr_reader :property_class

    # @return [String] the name of the schema elements.
    attr_reader :property_name

    # Retrieves the named property object.
    #
    # @param key [String, Symbol] The name of the requested property.
    #
    # @return [Stannum::Attribute] The property object.
    #
    # @raise ArgumentError if the key is invalid.
    # @raise KeyError if the property is not defined.
    def [](key)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      str = -key.to_s

      each_ancestor do |ancestor|
        next unless ancestor.own_properties.key?(str)

        return ancestor.own_properties[str]
      end

      {}.fetch(str)
    end

    # @api private
    #
    # Defines an property and adds the property to the contract.
    #
    # This method should not be called directly. Instead, define properties via
    # the Struct.property class method.
    #
    # @see Stannum::Struct
    def define(name:, options:, type:, definition_class: nil)
      definition_class ||= property_class

      property = definition_class.new(name:, options:, type:)

      if @properties.key?(property.name)
        message =
          "#{tools.str.singularize(property_name)} #{name.inspect} " \
          'already exists'

        raise ArgumentError, message
      end

      definition_class::Builder.new(self).call(property)

      @properties[property.name] = property
    end

    # Iterates through the the properties by name and property object.
    #
    # @yieldparam name [String] The name of the property.
    # @yieldparam property [Stannum::Attribute] The property object.
    def each(&block)
      return enum_for(:each) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_properties.each(&block)
      end
    end

    # Iterates through the the properties by name.
    #
    # @yieldparam name [String] The name of the property.
    def each_key(&block)
      return enum_for(:each_key) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_properties.each_key(&block)
      end
    end

    # Iterates through the the properties by property object.
    #
    # @yieldparam property [Stannum::Attribute] The property object.
    def each_value(&block)
      return enum_for(:each_value) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_properties.each_value(&block)
      end
    end

    # Checks if the given property is defined.
    #
    # @param key [String, Symbol] the name of the property to check.
    #
    # @return [Boolean] true if the property is defined; otherwise false.
    def key?(key)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      each_ancestor.any? do |ancestor|
        ancestor.own_properties.key?(key.to_s)
      end
    end
    alias has_key? key?

    # Returns the defined property keys.
    #
    # @return [Array<String>] the property keys.
    def keys
      each_key.to_a
    end

    # @private
    def own_properties
      @properties
    end

    # @return [Integer] the number of defined properties.
    def size
      each_ancestor.reduce(0) do |memo, ancestor|
        memo + ancestor.own_properties.size
      end
    end
    alias count size

    # Returns the defined property value.
    #
    # @return [Array<Stannum::Attribute>] the property values.
    def values
      each_value.to_a
    end

    private

    def each_ancestor
      return enum_for(:each_ancestor) unless block_given?

      ancestors.reverse_each do |ancestor|
        break unless ancestor.is_a?(Stannum::Schema)

        yield ancestor
      end
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
