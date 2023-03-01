# frozen_string_literal: true

require 'forwardable'

require 'stannum/attribute'

module Stannum
  # Abstract class for defining attribute methods for a struct.
  #
  # @see Stannum::Attribute.
  class Schema < Module
    extend  Forwardable
    include Enumerable

    def initialize
      super

      @attributes = {}
    end

    # Retrieves the named attribute object.
    #
    # @param key [String, Symbol] The name of the requested attribute.
    #
    # @return [Stannum::Attribute] The attribute object.
    #
    # @raise ArgumentError if the key is invalid.
    # @raise KeyError if the attribute is not defined.
    def [](key)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      str = -key.to_s

      each_ancestor do |ancestor|
        next unless ancestor.own_attributes.key?(str)

        return ancestor.own_attributes[str]
      end

      {}.fetch(str)
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
      attribute = Stannum::Attribute.new(
        name:    name,
        options: options,
        type:    type
      )

      if @attributes.key?(attribute.name)
        raise ArgumentError, "attribute #{name.inspect} already exists"
      end

      define_reader(attribute.name, attribute.reader_name)
      define_writer(attribute.name, attribute.writer_name, attribute.default)

      @attributes[attribute.name] = attribute
    end
    # rubocop:enable Metrics/MethodLength

    # Iterates through the the attributes by name and attribute object.
    #
    # @yieldparam name [String] The name of the attribute.
    # @yieldparam attribute [Stannum::Attribute] The attribute object.
    def each(&block)
      return enum_for(:each) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_attributes.each(&block)
      end
    end

    # Iterates through the the attributes by name.
    #
    # @yieldparam name [String] The name of the attribute.
    def each_key(&block)
      return enum_for(:each_key) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_attributes.each_key(&block)
      end
    end

    # Iterates through the the attributes by attribute object.
    #
    # @yieldparam attribute [Stannum::Attribute] The attribute object.
    def each_value(&block)
      return enum_for(:each_value) { size } unless block_given?

      each_ancestor do |ancestor|
        ancestor.own_attributes.each_value(&block)
      end
    end

    # Checks if the given attribute is defined.
    #
    # @param key [String, Symbol] the name of the attribute to check.
    #
    # @return [Boolean] true if the attribute is defined; otherwise false.
    def key?(key)
      tools.assertions.assert_name(key, as: 'key', error_class: ArgumentError)

      each_ancestor.any? do |ancestor|
        ancestor.own_attributes.key?(key.to_s)
      end
    end
    alias has_key? key?

    # Returns the defined attribute keys.
    #
    # @return [Array<String>] the attribute keys.
    def keys
      each_key.to_a
    end

    # @private
    def own_attributes
      @attributes
    end

    # @return [Integer] the number of defined attributes.
    def size
      each_ancestor.reduce(0) do |memo, ancestor|
        memo + ancestor.own_attributes.size
      end
    end
    alias count size

    # Returns the defined attribute value.
    #
    # @return [Array<Stannum::Attribute>] the attribute values.
    def values
      each_value.to_a
    end

    private

    def define_reader(attr_name, reader_name)
      define_method(reader_name) { @attributes[attr_name] }
    end

    def define_writer(attr_name, writer_name, default_value)
      define_method(writer_name) do |value|
        @attributes[attr_name] = value.nil? ? default_value : value
      end
    end

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
