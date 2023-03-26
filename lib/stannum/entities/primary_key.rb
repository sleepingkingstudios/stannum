# frozen_string_literal: true

require 'stannum/entities'

module Stannum::Entities
  # Methods for defining and accessing an entity's primary key attribute.
  module PrimaryKey
    # Raised when adding a primary key to an entity that already has one.
    class PrimaryKeyAlreadyExists < StandardError; end

    # Raised when accessing a primary key for an entity that does not have one.
    class PrimaryKeyMissing < StandardError; end

    # Class methods to extend the class when including PrimaryKey.
    module ClassMethods
      # Defines a primary key attribute on the entity.
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
      #
      # @see Stannum::Entities::Attributes::ClassMethods#define_primary_key.
      def define_primary_key(attr_name, attr_type, **options)
        if primary_key?
          raise PrimaryKeyAlreadyExists,
            "#{name} already defines primary key #{primary_key_name.inspect}"
        end

        attribute(attr_name, attr_type, **options.merge(primary_key: true))
      end

      # @return [Stannum::Attribute] the primary key attribute.
      #
      # @raise [Stannum::Entities::PrimaryKey::PrimaryKeyMissing] if the entity
      #   does not define a primary key.
      def primary_key
        primary_key =
          attributes
          .find { |_, attribute| attribute.primary_key? }
          &.last

        return primary_key if primary_key

        raise PrimaryKeyMissing, "#{name} does not define a primary key"
      end

      # @return [Boolean] true if the entity class defines a primary key;
      #   otherwise false.
      def primary_key?
        attributes.any? { |_, attribute| attribute.primary_key? }
      end

      # @return [String, nil] the name of the primary key attribute, or nil if
      #   the entity does not define a primary key.
      def primary_key_name
        attributes
          .find { |_, attribute| attribute.primary_key? }
          &.last
          &.name
      end

      private

      def included(other)
        super

        other.include(Stannum::Entities::PrimaryKey)
      end
    end

    class << self
      private

      def included(other)
        super

        other.extend(self::ClassMethods)
      end
    end

    # @return [Boolean] true if the entity class defines a primary key and if
    #   the entity has a non-empty value for that attribute; otherwise false.
    def primary_key?
      return false unless self.class.primary_key?

      value = attributes[self.class.primary_key_name]

      return false if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      true
    end

    # @return [Object] the current value of the primary key attribute.
    #
    # @raise [Stannum::Entities::PrimaryKey::PrimaryKeyMissing] if the entity
    #   does not define a primary key.
    def primary_key_value
      unless self.class.primary_key?
        raise PrimaryKeyMissing, "#{self.class} does not define a primary key"
      end

      attributes[self.class.primary_key_name]
    end
    alias primary_key primary_key_value
  end
end
