# frozen_string_literal: true

require 'stannum'
require 'stannum/support/optional'

module Stannum
  # Data object representing an attribute on an entity.
  class Attribute
    include Stannum::Support::Optional

    # Builder class for defining attribute methods on an entity.
    class Builder
      # @param entity_class [Class] the entity class on which to define methods.
      def initialize(entity_class)
        @entity_class = entity_class
      end

      # @return [Class] the entity class on which to define methods.
      attr_reader :entity_class

      # Defines the reader and writer methods for the attribute.
      #
      # @param attribute [Stannum::Attribute]
      def call(attribute)
        define_reader(attribute)
        define_writer(attribute)
      end

      private

      def define_reader(attribute)
        entity_class.define_method(attribute.reader_name) do
          read_attribute(attribute.name, safe: false)
        end
      end

      def define_writer(attribute)
        entity_class.define_method(attribute.writer_name) do |value|
          write_attribute(
            attribute.name,
            value.nil? ? attribute.default_value_for(self) : value,
            safe: false
          )
        end
      end
    end

    # @param name [String, Symbol] The name of the attribute. Converted to a
    #   String.
    # @param options [Hash, nil] Options for the attribute. Converted to a Hash
    #   with Symbol keys. Defaults to an empty Hash.
    # @param type [Class, Module, String] The type of the attribute. Can be a
    #   Class, a Module, or the name of a class or module.
    #
    # @option options [Object] :default The default value for the attribute.
    #   Defaults to nil.
    # @option options [Boolean] :primary_key true if the attribute represents
    #   the primary key for the entity; otherwise false. Defaults to false.
    def initialize(name:, options:, type:)
      validate_name(name)
      validate_options(options)
      validate_type(type)

      @name    = name.to_s
      @options = tools.hash_tools.convert_keys_to_symbols(options || {})
      @options = resolve_required_option(**@options)

      @type, @resolved_type = resolve_type(type)
    end

    # @return [String] the name of the attribute.
    attr_reader :name

    # @return [Hash] the attribute options.
    attr_reader :options

    # @return [String] the name of the attribute type Class or Module.
    attr_reader :type

    # @return [Object] the default value for the attribute, if any.
    def default
      @options[:default]
    end

    # @return [Boolean] true if the attribute has a default value; otherwise
    #   false.
    def default?
      !@options[:default].nil?
    end

    # @param context [Object] the context object used to determinet the default
    #   value.
    #
    # @return [Object] the value of the default attribute for the given context
    #   object, if any.
    def default_value_for(context)
      return default unless default.is_a?(Proc)

      default.arity.zero? ? default.call : default.call(context)
    end

    # @return [Boolean] true if the attribute represents the primary key for the
    #   entity; otherwise false.
    def primary_key?
      !!@options[:primary_key]
    end

    # @return [Symbol] the name of the reader method for the attribute.
    def reader_name
      @reader_name ||= name.intern
    end

    # @return [Module] the type of the attribute.
    def resolved_type
      return @resolved_type if @resolved_type

      @resolved_type = Object.const_get(type)

      unless @resolved_type.is_a?(Module)
        raise NameError, "constant #{type} is not a Class or Module"
      end

      @resolved_type
    end

    # @return [Symbol] the name of the writer method for the attribute.
    def writer_name
      @writer_name ||= :"#{name}="
    end

    private

    def resolve_type(type)
      return [type, nil] if type.is_a?(String)

      [type.to_s, type]
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def validate_name(name)
      tools.assertions.validate_name(name, as: 'name')
    end

    def validate_options(options)
      return if options.nil? || options.is_a?(Hash)

      raise ArgumentError, 'options must be a Hash or nil'
    end

    def validate_type(type)
      raise ArgumentError, "type can't be blank" if type.nil?

      return if type.is_a?(Module)

      if type.is_a?(String)
        return unless type.empty?

        raise ArgumentError, "type can't be blank"
      end

      raise ArgumentError,
        'type must be a Class, a Module, or the name of a class or module'
    end
  end
end
