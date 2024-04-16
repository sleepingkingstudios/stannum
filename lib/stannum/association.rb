# frozen_string_literal: true

require 'stannum'

module Stannum
  # Data object representing an association on an entity.
  class Association
    # Exception raised when calling an abstract method.
    class AbstractAssociationError < StandardError; end

    # Builder class for defining association methods on an entity.
    class Builder
      # @param entity_class [Class] the entity class on which to define methods.
      def initialize(entity_class)
        @entity_class = entity_class
      end

      # @return [Class] the entity class on which to define methods.
      attr_reader :entity_class

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

    # Clears the value of the association for the entity.
    #
    # @param entity [Stannum::Entity] the entity to update.
    def clear_association(entity) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
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

    # @param entity [Stannum::Entity] the entity to update.
    #
    # @return [Object] the value of the association.
    def read_association(entity) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
    end

    # @return [Symbol] the name of the reader method for the association.
    def reader_name
      @reader_name ||= name.intern
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

    # @param entity [Stannum::Entity] the entity to update.
    # @param value [Object] the new value for the association.
    def write_association(entity, value) # rubocop:disable Lint/UnusedMethodArgument
      raise AbstractAssociationError,
        "#{self.class} is an abstract class - use an association subclass"
    end

    # @return [Symbol] the name of the writer method for the association.
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
