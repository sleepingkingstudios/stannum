# frozen_string_literal: true

require 'stannum'

module Stannum
  # Data object representing an association on an entity.
  class Association # rubocop:disable Metrics/ClassLength
    # Exception raised when calling an abstract method.
    class AbstractAssociationError < StandardError; end

    # Exception raised when referencing an invalid inverse association..
    class InverseAssociationError < StandardError; end

    # Builder class for defining association methods on an entity.
    class Builder
      # @param schema [Stannum::Schema] the associations schema on which to
      #   define methods.
      def initialize(schema)
        @schema = schema
      end

      # @return schema [Stannum::Schema] the associations schema on which to
      #   define methods.
      attr_reader :schema

      # Defines the reader and writer methods for the association.
      #
      # @param association [Stannum::Association]
      def call(association)
        define_reader(association)
        define_writer(association)
      end

      private

      # :nocov:
      def define_reader(_)
        raise AbstractAssociationError,
          "#{self} is an abstract class - use an association subclass"
      end

      def define_writer(_)
        raise AbstractAssociationError,
          "#{self} is an abstract class - use an association subclass"
      end
      # :nocov:
    end

    # @param name [String, Symbol] The name of the association. Converted to a
    #   String.
    # @param options [Hash, nil] Options for the association. Converted to a
    #   Hash with Symbol keys. Defaults to an empty Hash.
    # @param type [Class, Module, String] The type of the association. Can be a
    #   Class, a Module, or the name of a class or module.
    def initialize(name:, options:, type:)
      validate_name(name)
      validate_options(options)
      validate_type(type)

      @name    = name.to_s
      @options = tools.hash_tools.convert_keys_to_symbols(options || {})

      @type, @resolved_type = resolve_type(type)
    end

    # @return [String] the name of the association.
    attr_reader :name

    # @return [Hash] the association options.
    attr_reader :options

    # @return [String] the name of the association type Class or Module.
    attr_reader :type

    # Adds the given value to the association for the entity.
    #
    # @param entity [Stannum::Entity] the entity to update.
    # @param value [Object] the new value for the association.
    def add_value(entity, value, update_inverse: true) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
    end

    # @return [String, nil] the name of the original entity class.
    def entity_class_name
      @options[:entity_class_name]
    end

    # @return [Boolean] true if the association has an inverse association;
    #   otherwise false.
    def inverse?
      !!@options[:inverse]
    end

    # @return [String] the name of the inverse association, if any.
    def inverse_name
      @inverse_name ||= resolve_inverse_name
    end

    # @return [false] true if the association is a plural association;
    #   otherwise false.
    def many?
      false
    end

    # @return [false] true if the association is a singular association;
    #   otherwise false.
    def one?
      false
    end

    # @return [Symbol] the name of the reader method for the association.
    def reader_name
      @reader_name ||= name.intern
    end

    # Removes the given value from the association for the entity.
    #
    # @param entity [Stannum::Entity] the entity to update.
    # @param value [Stannum::Entity] the association value to remove.
    def remove_value(entity, value, update_inverse: true) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
    end

    # @return [Stannum::Association] the inverse association, if any.
    def resolved_inverse
      return @resolved_inverse if @resolved_inverse

      return unless inverse?

      @resolved_inverse = resolved_type.associations[inverse_name]
    rescue KeyError => exception
      raise InverseAssociationError,
        "unable to resolve inverse association #{exception.key.inspect}"
    end

    # @return [Module] the type of the association.
    def resolved_type
      return @resolved_type if @resolved_type

      @resolved_type = Object.const_get(type)

      unless @resolved_type.is_a?(Module)
        raise NameError, "constant #{type} is not a Class or Module"
      end

      @resolved_type
    end

    # Retrieves the value of the association for the entity.
    #
    # @param entity [Stannum::Entity] the entity to update.
    #
    # @return [Object] the value of the association.
    def value(entity) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
    end

    # @return [Symbol] the name of the writer method for the association.
    def writer_name
      @writer_name ||= :"#{name}="
    end

    private

    def plural_class_name
      @plural_class_name ||= tools.string_tools.pluralize(singular_class_name)
    end

    def resolve_inverse_name # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return unless inverse?

      return options[:inverse_name].to_s if options[:inverse_name]

      if resolved_type.associations.key?(singular_class_name)
        return singular_class_name
      end

      if resolved_type.associations.key?(plural_class_name)
        return plural_class_name
      end

      raise InverseAssociationError,
        'unable to resolve inverse association ' \
        "#{singular_class_name.inspect} or #{plural_class_name.inspect}"
    end

    def resolve_type(type)
      return [type, nil] if type.is_a?(String)

      [type.to_s, type]
    end

    def singular_class_name
      @singular_class_name ||=
        entity_class_name
        .split('::')
        .last
        .then { |str| tools.string_tools.underscore(str) }
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
