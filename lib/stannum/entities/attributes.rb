# frozen_string_literal: true

require 'stannum/entities'
require 'stannum/schema'

module Stannum::Entities
  # Methods for defining and accessing entity attributes.
  module Attributes # rubocop:disable Metrics/ModuleLength
    # Class methods to extend the class when including Attributes.
    module ClassMethods
      # Defines an attribute on the entity.
      #
      # When an attribute is defined, each of the following steps is executed:
      #
      # - Adds the attribute to ::Attributes and the .attributes class method.
      # - Adds the attribute to #attributes and the associated methods, such as
      #   #assign_attributes, #[] and #[]=.
      # - Defines reader and writer methods.
      #
      # @param attr_name [String, Symbol] The name of the attribute. Must be a
      #   non-empty String or Symbol.
      # @param attr_type [Class, String] The type of the attribute. Must be a
      #   Class or Module, or the name of a class or module.
      # @param options [Hash] Additional options for the attribute.
      #
      # @option options [Object] :default The default value for the attribute.
      #   Defaults to nil.
      # @option options [Boolean] :primary_key true if the attribute represents
      #   the primary key for the entity; otherwise false. Defaults to false.
      #
      # @return [Symbol] The attribute name as a symbol.
      def attribute(attr_name, attr_type, **options)
        attributes.define_attribute(
          name:    attr_name,
          type:    attr_type,
          options: options
        )

        attr_name.intern
      end
      alias define_attribute attribute

      # @return [Stannum::Schema] The attributes Schema object for the Entity.
      def attributes
        self::Attributes
      end

      private

      def included(other)
        super

        other.include(Stannum::Entities::Attributes)

        Stannum::Entities::Attributes.apply(other) if other.is_a?(Class)
      end

      def inherited(other)
        super

        Stannum::Entities::Attributes.apply(other)
      end
    end

    class << self
      # Generates Attributes schema for the class.
      #
      # Creates a new Stannum::Schema and sets it as the class's :Attributes
      # constant. If the superclass is an entity class (and already defines its
      # own Attributes, includes the superclass Attributes in the class
      # Attributes). Finally, includes the class Attributes in the class.
      #
      # @param other [Class] the class to which attributes are added.
      def apply(other)
        return unless other.is_a?(Class)

        return if entity_class?(other)

        other.const_set(:Attributes, Stannum::Schema.new)

        if entity_class?(other.superclass)
          other::Attributes.include(other.superclass::Attributes)
        end

        other.include(other::Attributes)
      end

      private

      def entity_class?(other)
        other.const_defined?(:Attributes, false)
      end

      def included(other)
        super

        other.extend(self::ClassMethods)

        apply(other) if other.is_a?(Class)
      end
    end

    # @param properties [Hash] the properties used to initialize the entity.
    def initialize(**properties)
      @attributes = {}

      super
    end

    # Updates the struct's attributes with the given values.
    #
    # This method is used to update some (but not all) of the attributes of the
    # struct. For each key in the hash, it calls the corresponding writer method
    # with the value for that attribute. If the value is nil, this will set the
    # attribute value to the default for that attribute.
    #
    # Any attributes that are not in the given hash are unchanged, as are any
    # properties that are not attributes.
    #
    # If the attributes hash includes any keys that do not correspond to an
    # attribute, the struct will raise an error.
    #
    # @param attributes [Hash] The initial attributes for the struct.
    #
    # @raise ArgumentError if the key is not a valid attribute.
    #
    # @see #attributes=
    def assign_attributes(attributes)
      unless attributes.is_a?(Hash)
        raise ArgumentError, 'attributes must be a Hash'
      end

      set_attributes(attributes, force: false)
    end

    # Collects the entity attributes.
    #
    # @return [Hash<String, Object>] the entity attributes.
    def attributes
      @attributes.dup
    end

    # Replaces the entity's attributes with the given values.
    #
    # This method is used to update all of the attributes of the entity. For
    # each attribute, the writer method is called with the value from the hash,
    # or nil if the corresponding key is not present in the hash. Any nil or
    # missing values set the attribute value to that attribute's default value,
    # if any. Non-attribute properties are unchanged.
    #
    # If the attributes hash includes any keys that do not correspond to a valid
    # attribute, the entity will raise an error.
    #
    # @param attributes [Hash] the attributes to assign to the entity.
    #
    # @raise ArgumentError if any key is not a valid attribute.
    #
    # @see #assign_attributes
    def attributes=(attributes)
      unless attributes.is_a?(Hash)
        raise ArgumentError, 'attributes must be a Hash'
      end

      set_attributes(attributes, force: true)
    end

    # (see Stannum::Entities::Properties#properties)
    def properties
      super.merge(attributes)
    end

    private

    def apply_defaults_for(attributes) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      with_value, with_proc = bisect_attributes_by_default_type

      with_value.each do |attribute|
        next unless @attributes[attribute.name].nil?
        next unless attributes.key?(attribute.name)

        send(attribute.writer_name, attribute.default)
      end

      with_proc.each do |attribute|
        next unless @attributes[attribute.name].nil?
        next unless attributes.key?(attribute.name)

        send(attribute.writer_name, attribute.default_value_for(self))
      end
    end

    def bisect_attributes_by_default_type
      with_value = []
      with_proc  = []

      self.class.attributes.each_value do |attribute|
        next unless attribute.default?

        (attribute.default.is_a?(Proc) ? with_proc : with_value) << attribute
      end

      [with_value, with_proc]
    end

    def get_property(key)
      return @attributes[key.to_s] if attributes.key?(key.to_s)

      super
    end

    def inspectable_properties
      super().merge(attributes)
    end

    def set_attributes(attributes, force:)
      attributes, non_matching =
        bisect_properties(attributes, self.class.attributes)

      unless non_matching.empty?
        handle_invalid_properties(non_matching, as: 'attribute')
      end

      write_attributes(attributes, force: force)
    end

    def set_properties(properties, force:)
      attributes, non_matching =
        bisect_properties(properties, self.class.attributes)

      super(non_matching, force: force)

      write_attributes(attributes, force: force)
    end

    def set_property(key, value)
      return super unless attributes.key?(key.to_s)

      send(self.class.attributes[key.to_s].writer_name, value)
    end

    def write_attributes(attributes, force:)
      self.class.attributes.each do |attr_name, attribute|
        next unless attributes.key?(attr_name) || force

        if attributes[attr_name].nil? && attribute.default?
          @attributes[attr_name] = nil
        else
          send(attribute.writer_name, attributes[attr_name])
        end
      end

      apply_defaults_for(force ? @attributes : attributes)
    end
  end
end
