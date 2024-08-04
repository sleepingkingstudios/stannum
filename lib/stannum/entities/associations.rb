# frozen_string_literal: true

require 'stannum/entities'
require 'stannum/schema'

module Stannum::Entities
  # Methods for defining and accessing entity associations.
  module Associations # rubocop:disable Metrics/ModuleLength
    # Class methods to extend the class when including Associations.
    module ClassMethods # rubocop:disable Metrics/ModuleLength
      # Defines an association on the entity.
      #
      # When an association is defined, each of the following steps is executed:
      #
      # - Adds the association to ::Associations and the .associations class
      #   method.
      # - Adds the association to #association and the associated methods, such
      #   as #assign_associations, #[] and #[]=.
      # - Defines reader and writer methods.
      #
      # @overload association(arity, assoc_name, **options)
      #   Defines an association with the given name. The class of the
      #   associated object is determined automatically based on the association
      #   name, or can be specified with the :class_name keyword.
      #
      #   @param arity [:one, :many] :one if the association has one item, or
      #     :many if the association can have multiple items.
      #   @param assoc_name [String, Symbol] the name of the association.
      #   @param options [Hash] additional options for the association.
      #
      #   @option options [String] :class_name the name of the associated class.
      #   @option options [true, Hash] :foreign_key the foreign key options for
      #     the association. Can be true, or a Hash containing :name and/or
      #     :type keys.
      #
      #   @return [Symbol] the association name as a symbol.
      #
      # @overload association(arity, assoc_type, **options)
      #   Defines an association with the given class. The name of the
      #   association is determined automatically based on the association
      #   class.
      #
      #   @param arity [:one, :many] :one if the association has one item, or
      #     :many if the association can have multiple items.
      #   @param assoc_type [String, Symbol, Class] the type of the associated
      #   @param options [Hash] additional options for the association.
      #
      #   @option options [true, Hash] :foreign_key the foreign key options for
      #     the association. Can be true, or a Hash containing :name and/or
      #     :type keys.
      #
      #   @return [Symbol] the association name as a symbol.
      def association(arity, class_or_name, **options) # rubocop:disable Metrics/MethodLength
        assoc_class                     =
          resolve_association_class(arity)
        assoc_name, assoc_type, options =
          resolve_parameters(arity, class_or_name, options)

        association = associations.define(
          definition_class: assoc_class,
          name:             assoc_name,
          type:             assoc_type,
          options:          parse_options(assoc_name, **options)
        )
        define_foreign_key(association) if association.foreign_key?

        association.name.intern
      end
      alias define_association association

      # @return [Stannum::Schema] The associations Schema object for the Entity.
      def associations
        self::Associations
      end

      # @return [Class] the default type for foreign key attributes.
      def default_foreign_key_type
        (defined?(primary_key_type) && primary_key_type) || Integer
      end

      private

      def association_name_for(arity, class_or_name, configured)
        if configured
          raise ArgumentError,
            %(ambiguous class name "#{class_or_name}" or "#{configured}" ) \
            '- do not provide both a class and a :class_name keyword'
        end

        assoc_name = tools.string_tools.underscore(
          class_or_name.to_s.split('::').last
        )
        assoc_name = tools.string_tools.singularize(assoc_name) if arity == :one

        assoc_name
      end

      def define_foreign_key(association)
        define_attribute(
          association.foreign_key_name,
          association.foreign_key_type,
          association_name: association.name,
          foreign_key:      true,
          required:         false
        )
      end

      def included(other)
        super

        other.include(Stannum::Entities::Associations)

        Stannum::Entities::Associations.apply(other) if other.is_a?(Class)
      end

      def inherited(other)
        super

        Stannum::Entities::Associations.apply(other)
      end

      def parse_foreign_key_options(assoc_name, foreign_key) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        return {} if foreign_key == false

        foreign_key = {} if foreign_key == true

        if foreign_key.is_a?(String) || foreign_key.is_a?(Symbol)
          foreign_key = { name: foreign_key.to_s }
        end

        unless foreign_key.is_a?(Hash)
          raise InvalidOptionError, "invalid foreign key #{foreign_key.inspect}"
        end

        name = foreign_key.fetch(:name) { "#{assoc_name}_id" }
        type = foreign_key.fetch(:type) { default_foreign_key_type }

        {
          foreign_key_name: name,
          foreign_key_type: type
        }
      end

      def parse_inverse_options(inverse)
        hsh = {
          entity_class_name: name,
          inverse:           true
        }

        if inverse.is_a?(String) || inverse.is_a?(Symbol)
          hsh[:inverse_name] = inverse.to_s
        end

        hsh
      end

      def parse_options(assoc_name, **options) # rubocop:disable Metrics/MethodLength
        if options.key?(:foreign_key)
          options = options.merge(
            parse_foreign_key_options(assoc_name, options.delete(:foreign_key))
          )
        end

        if options[:inverse] != false
          options = options.merge(
            parse_inverse_options(options.delete(:inverse))
          )
        end

        options
      end

      def resolve_association_class(arity)
        return Stannum::Associations::One if arity == :one

        raise ArgumentError, 'association arity must be :one'
      end

      def resolve_parameters(arity, class_or_name, options)
        class_name = options.delete(:class_name)

        if class_or_name.is_a?(Module) || class_or_name =~ /::/
          assoc_name = association_name_for(arity, class_or_name, class_name)
          assoc_type = class_or_name

          return [assoc_name, assoc_type, options]
        end

        assoc_name = tools.string_tools.underscore(class_or_name.to_s)
        assoc_type = class_name || tools.string_tools.camelize(assoc_name)

        [assoc_name, assoc_type, options]
      end

      def tools
        SleepingKingStudios::Tools::Toolbelt.instance
      end
    end

    # Exception class raised when an invalid option value is set.
    class InvalidOptionError < StandardError; end

    class << self
      # Generates Associations schema for the class.
      #
      # Creates a new Stannum::Schema and sets it as the class's :Associations
      # constant. If the superclass is an entity class (and already defines its
      # own Associations, includes the superclass Associations in the class
      # Associations). Finally, includes the class Associations in the class.
      #
      # @param other [Class] the class to which attributes are added.
      def apply(other)
        return unless other.is_a?(Class)

        return if entity_class?(other)

        other.const_set(:Associations, build_schema)

        if entity_class?(other.superclass)
          other::Associations.include(other.superclass::Associations)
        end

        other.include(other::Associations)
      end

      private

      def build_schema
        Stannum::Schema.new(
          property_class: Stannum::Association,
          property_name:  'associations'
        )
      end

      def entity_class?(other)
        other.const_defined?(:Associations, false)
      end

      def included(other)
        super

        other.extend(self::ClassMethods)

        apply(other) if other.is_a?(Class)
      end
    end

    # @param properties [Hash] the properties used to initialize the entity.
    def initialize(**properties)
      @associations = {}

      super
    end

    # Updates the struct's associations with the given values.
    #
    # This method is used to update some (but not all) of the associations of
    # the struct. For each key in the hash, it calls the corresponding writer
    # method with the value for that association.
    #
    # Any associations that are not in the given hash are unchanged, as are any
    # properties that are not associations.
    #
    # If the associations hash includes any keys that do not correspond to an
    # association, the struct will raise an error.
    #
    # @param associations [Hash] The associations for the struct.
    #
    # @raise ArgumentError if any key is not a valid association.
    #
    # @see #associations=
    def assign_associations(associations)
      unless associations.is_a?(Hash)
        raise ArgumentError, 'associations must be a Hash'
      end

      set_associations(associations, force: false)
    end

    # Collects the entity associations.
    #
    # @return [Hash<String, Object>] the entity associations.
    def associations
      @associations.dup
    end

    # Replaces the entity's associations with the given values.
    #
    # This method is used to update all of the associations of the entity. For
    # each association, the writer method is called with the value from the
    # hash. Non-association properties are unchanged.
    #
    # If the associations hash includes any keys that do not correspond to a
    # valid association, the entity will raise an error.
    #
    # @param associations [Hash] the associations to assign to the entity.
    #
    # @raise ArgumentError if any key is not a valid association.
    #
    # @see #assign_attributes
    def associations=(associations)
      unless associations.is_a?(Hash)
        raise ArgumentError, 'associations must be a Hash'
      end

      set_associations(associations, force: true)
    end

    # (see Stannum::Entities::Properties#properties)
    def properties
      super.merge(associations)
    end

    # Retrieves the association value for the requested key.
    #
    # If the :safe flag is set, will verify that the association name is valid
    # (a non-empty String or Symbol) and that there is a defined association by
    # that name. By default, :safe is set to true.
    #
    # @param key [String, Symbol] the key of the association to retrieve.
    # @param safe [Boolean] if true, validates the association key.
    #
    # @return [Object] the value of the requested association.
    #
    # @api private
    def read_association(key, safe: true)
      if safe
        tools.assertions.validate_name(key, as: 'association')

        unless self.class.associations.key?(key.to_s)
          raise ArgumentError, "unknown association #{key.inspect}"
        end
      end

      @associations[key.to_s]
    end

    # Assigns the association value for the requested key.
    #
    # If the :safe flag is set, will verify that the association name is valid
    # (a non-empty String or Symbol) and that there is a defined association by
    # that name. By default, :safe is set to true.
    #
    # @param key [String, Symbol] the key of the association to assign.
    # @oaram value [Object] the value to assign.
    # @param safe [Boolean] if true, validates the association key.
    #
    # @return [Object] the assigned value.
    #
    # @api private
    def write_association(key, value, safe: true)
      if safe
        tools.assertions.validate_name(key, as: 'association')

        unless self.class.associations.key?(key.to_s)
          raise ArgumentError, "unknown association #{key.inspect}"
        end
      end

      @associations[key.to_s] = value
    end

    private

    def get_property(key)
      return @associations[key.to_s] if associations.key?(key.to_s)

      super
    end

    def inspect_association(value, **options) # rubocop:disable Metrics/MethodLength
      if value.nil?
        'nil'
      elsif value.is_a?(Array)
        value
          .map { |item| inspect_association(item, **options) }
          .join(', ')
          .then { |str| "[#{str}]" }
      elsif value.respond_to?(:inspect_with_options)
        value.inspect_with_options(**options)
      else
        value.inspect
      end
    end

    def inspect_properties(**options)
      return super unless options.fetch(:associations, true)

      @associations.reduce(super) do |memo, (key, value)|
        mapped = inspect_association(value, **options, associations: false)

        "#{memo} #{key}: #{mapped}"
      end
    end

    def set_associations(associations, force:)
      associations, non_matching =
        bisect_properties(associations, self.class.associations)

      unless non_matching.empty?
        handle_invalid_properties(non_matching, as: 'association')
      end

      write_associations(associations, force:)
    end

    def set_properties(properties, force:)
      associations, non_matching =
        bisect_properties(properties, self.class.associations)

      super(non_matching, force:)

      write_associations(associations, force:)
    end

    def set_property(key, value)
      return super unless associations.key?(key.to_s)

      send(self.class.associations[key.to_s].writer_name, value)
    end

    def write_associations(associations, force:)
      self.class.associations.each do |assoc_name, association|
        next unless associations.key?(assoc_name) || force

        send(association.writer_name, associations[assoc_name])
      end
    end
  end
end
