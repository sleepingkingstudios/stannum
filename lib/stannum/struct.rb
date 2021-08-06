# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'stannum/schema'

module Stannum
  # Abstract class for defining objects with structured attributes.
  #
  # @example Defining Attributes
  #   class Widget
  #     include Stannum::Struct
  #
  #     attribute :name,        String
  #     attribute :description, String,  optional: true
  #     attribute :quantity,    Integer, default:  0
  #   end
  #
  #   widget = Widget.new(name: 'Self-sealing Stem Bolt')
  #   widget.name        #=> 'Self-sealing Stem Bolt'
  #   widget.description #=> nil
  #   widget.quantity    #=> 0
  #   widget.attributes  #=>
  #   # {
  #   #   name:        'Self-sealing Stem Bolt',
  #   #   description: nil,
  #   #   quantity:    0
  #   # }
  #
  # @example Setting Attributes
  #   widget.description = 'A stem bolt, but self sealing.'
  #   widget.attributes #=>
  #   # {
  #   #   name:        'Self-sealing Stem Bolt',
  #   #   description: 'A stem bolt, but self sealing.',
  #   #   quantity:    0
  #   # }
  #
  #   widget.assign_attributes(quantity: 50)
  #   widget.attributes #=>
  #   # {
  #   #   name:        'Self-sealing Stem Bolt',
  #   #   description: 'A stem bolt, but self sealing.',
  #   #   quantity:    50
  #   # }
  #
  #   widget.attributes = (name: 'Inverse Chronoton Emitter')
  #   # {
  #   #   name:        'Inverse Chronoton Emitter',
  #   #   description: nil,
  #   #   quantity:    0
  #   # }
  #
  # @example Defining Attribute Constraints
  #   Widget::Contract.matches?(quantity: -5)                    #=> false
  #   Widget::Contract.matches?(name: 'Capacitor', quantity: -5) #=> true
  #
  #   class Widget
  #     constraint(:quantity) { |qty| qty >= 0 }
  #   end
  #
  #   Widget::Contract.matches?(name: 'Capacitor', quantity: -5) #=> false
  #   Widget::Contract.matches?(name: 'Capacitor', quantity: 10) #=> true
  #
  # @example Defining Struct Constraints
  #   Widget::Contract.matches?(name: 'Diode') #=> true
  #
  #   class Widget
  #     constraint { |struct| struct.description&.include?(struct.name) }
  #   end
  #
  #   Widget::Contract.matches?(name: 'Diode') #=> false
  #   Widget::Contract.matches?(
  #     name:        'Diode',
  #     description: 'A low budget Diode',
  #   ) #=> true
  module Struct # rubocop:disable Metrics/ModuleLength
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Class methods to extend the class when including Stannum::Struct.
    module ClassMethods
      # rubocop:disable Metrics/MethodLength

      # Defines an attribute on the struct.
      #
      # When an attribute is defined, each of the following steps is executed:
      #
      # - Adds the attribute to ::Attributes and the .attributes class method.
      # - Adds the attribute to #attributes and the associated methods, such as
      #   #assign_attributes, #[] and #[]=.
      # - Defines reader and writer methods.
      # - Adds a type constraint to ::Attributes::Contract, and indirectly to
      #   ::Contract.
      #
      # @param attr_name [String, Symbol] The name of the attribute. Must be a
      #   non-empty String or Symbol.
      # @param attr_type [Class, String] The type of the attribute. Must be a
      #   Class or Module, or the name of a class or module.
      # @param options [Hash] Additional options for the attribute.
      #
      # @option options [Object] :default The default value for the attribute.
      #   Defaults to nil.
      #
      # @return [Symbol] The attribute name as a symbol.
      def attribute(attr_name, attr_type, **options)
        attribute  = attributes.define_attribute(
          name:    attr_name,
          type:    attr_type,
          options: options
        )
        constraint = Stannum::Constraints::Type.new(
          attribute.type,
          required: attribute.required?
        )

        self::Contract.add_constraint(
          constraint,
          property: attribute.reader_name
        )

        attr_name.intern
      end
      # rubocop:enable Metrics/MethodLength

      # @return [Stannum::Schema] The Schema object for the Struct.
      def attributes
        self::Attributes
      end

      # Defines a constraint on the struct or one of its properties.
      #
      # @overload constraint()
      #   Defines a constraint on the struct.
      #
      #   A new Stannum::Constraint instance will be generated, passing the
      #   block from .constraint to the new constraint. This constraint will be
      #   added to the contract.
      #
      #   @yieldparam struct [Stannum::Struct] The struct at the time the
      #     constraint is evaluated.
      #
      # @overload constraint(constraint)
      #   Defines a constraint on the struct.
      #
      #   The given constraint is added to the contract. When the contract is
      #   evaluated, this constraint will be matched against the struct.
      #
      #   @param constraint [Stannum::Constraints::Base] The constraint to add.
      #
      # @overload constraint(attr_name)
      #   Defines a constraint on the given attribute or property.
      #
      #   A new Stannum::Constraint instance will be generated, passing the
      #   block from .constraint to the new constraint. This constraint will be
      #   added to the contract.
      #
      #   @param attr_name [String, Symbol] The name of the attribute or
      #     property to constrain.
      #
      #   @yieldparam value [Object] The value of the attribute or property of
      #     the struct at the time the constraint is evaluated.
      #
      # @overload constraint(attr_name, constraint)
      #   Defines a constraint on the given attribute or property.
      #
      #   The given constraint is added to the contract. When the contract is
      #   evaluated, this constraint will be matched against the value of the
      #   attribute or property.
      #
      #   @param attr_name [String, Symbol] The name of the attribute or
      #     property to constrain.
      #   @param constraint [Stannum::Constraints::Base] The constraint to add.
      def constraint(attr_name = nil, constraint = nil, &block)
        attr_name, constraint = resolve_constraint(attr_name, constraint)

        if block_given?
          constraint = Stannum::Constraint.new(&block)
        else
          validate_constraint(constraint)
        end

        contract.add_constraint(constraint, property: attr_name)
      end

      # @return [Stannum::Contract] The Contract object for the Struct.
      def contract
        self::Contract
      end

      private

      # @api private
      #
      # Hook to execute when a struct class is subclassed.
      def inherited(other)
        super

        Struct.build(other) if other.is_a?(Class)
      end

      def resolve_constraint(attr_name, constraint)
        return [nil, attr_name] if attr_name.is_a?(Stannum::Constraints::Base)

        validate_attribute_name(attr_name)

        [attr_name.nil? ? attr_name : attr_name.intern, constraint]
      end

      def validate_attribute_name(name)
        return if name.nil?

        unless name.is_a?(String) || name.is_a?(Symbol)
          raise ArgumentError, 'attribute must be a String or Symbol'
        end

        raise ArgumentError, "attribute can't be blank" if name.empty?
      end

      def validate_constraint(constraint)
        raise ArgumentError, "constraint can't be blank" if constraint.nil?

        return if constraint.is_a?(Stannum::Constraints::Base)

        raise ArgumentError, 'constraint must be a Stannum::Constraints::Base'
      end
    end

    class << self
      # @private
      def build(struct_class)
        return if struct_class?(struct_class)

        initialize_attributes(struct_class)
        initialize_contract(struct_class)
      end

      private

      def included(other)
        super

        Struct.build(other) if other.is_a?(Class)
      end

      def initialize_attributes(struct_class)
        attributes = Stannum::Schema.new

        struct_class.const_set(:Attributes, attributes)

        if struct_class?(struct_class.superclass)
          attributes.include(struct_class.superclass::Attributes)
        end

        struct_class.include(attributes)
      end

      def initialize_contract(struct_class)
        contract = Stannum::Contracts::PropertyContract.new

        struct_class.const_set(:Contract, contract)

        return unless struct_class?(struct_class.superclass)

        contract.include(struct_class.superclass::Contract)
      end

      def struct_class?(struct_class)
        struct_class.const_defined?(:Attributes, false)
      end
    end

    # Initializes the struct with the given attributes.
    #
    # For each key in the attributes hash, the corresponding writer method will
    # be called with the attribute value. If the hash does not include the key
    # for an attribute, or if the value is nil, the attribute will be set to
    # its default value.
    #
    # If the attributes hash includes any keys that do not correspond to an
    # attribute, the struct will raise an error.
    #
    # @param attributes [Hash] The initial attributes for the struct.
    #
    # @see #attributes=
    #
    # @raise ArgumentError if given an invalid attributes hash.
    def initialize(attributes = {})
      @attributes = {}

      self.attributes = attributes
    end

    # Compares the struct with the other object.
    #
    # The other object must be an instance of the current class. In addition,
    # the attributes hashes of the two objects must be equal.
    #
    # @return true if the object is a matching struct.
    def ==(other)
      return false unless other.class == self.class

      raw_attributes == other.raw_attributes
    end

    # Retrieves the attribute with the given key.
    #
    # @param key [String, Symbol] The attribute key.
    #
    # @return [Object] the value of the attribute.
    #
    # @raise ArgumentError if the key is not a valid attribute.
    def [](key)
      validate_attribute_key(key)

      send(self.class::Attributes[key].reader_name)
    end

    # Sets the given attribute to the given value.
    #
    # @param key [String, Symbol] The attribute key.
    # @param value [Object] The value for the attribute.
    #
    # @raise ArgumentError if the key is not a valid attribute.
    def []=(key, value)
      validate_attribute_key(key)

      send(self.class::Attributes[key].writer_name, value)
    end

    # Updates the struct's attributes with the given values.
    #
    # This method is used to update some (but not all) of the attributes of the
    # struct. For each key in the hash, it calls the corresponding writer method
    # with the value for that attribute. If the value is nil, this will set the
    # attribute value to the default for that attribute.
    #
    # Any attributes that are not in the given hash are unchanged.
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

      attributes.each do |attr_name, value|
        validate_attribute_key(attr_name)

        attribute = self.class.attributes[attr_name]

        send(attribute.writer_name, value)
      end
    end
    alias assign assign_attributes

    # @return [Hash] the current attributes of the struct.
    def attributes
      tools.hash_tools.deep_dup(@attributes)
    end
    alias to_h attributes

    # Replaces the struct's attributes with the given values.
    #
    # This method is used to update all of the attributes of the struct. For
    # each attribute, the writer method is called with the value from the hash,
    # or nil if the corresponding key is not present in the hash. Any nil or
    # missing keys set the attribute value to the attribute's default value.
    #
    # If the attributes hash includes any keys that do not correspond to an
    # attribute, the struct will raise an error.
    #
    # @param attributes [Hash] The initial attributes for the struct.
    #
    # @raise ArgumentError if the key is not a valid attribute.
    #
    # @see #assign_attributes
    def attributes=(attributes) # rubocop:disable Metrics/MethodLength
      unless attributes.is_a?(Hash)
        raise ArgumentError, 'attributes must be a Hash'
      end

      attributes.each_key { |attr_name| validate_attribute_key(attr_name) }

      self.class::Attributes.each_value do |attribute|
        send(
          attribute.writer_name,
          attributes.fetch(
            attribute.name,
            attributes.fetch(attribute.name.intern, attribute.default)
          )
        )
      end
    end

    # @return [String] a string representation of the struct and its attributes.
    def inspect # rubocop:disable Metrics/AbcSize
      if self.class.attributes.each_key.size.zero?
        return "#<#{self.class.name}>"
      end

      buffer = +"#<#{self.class.name}"

      self.class.attributes.each_key.with_index \
      do |attribute, index|
        buffer << ',' unless index.zero?
        buffer << " #{attribute}: #{@attributes[attribute].inspect}"
      end

      buffer << '>'
    end

    protected

    def raw_attributes
      @attributes
    end

    private

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    def validate_attribute_key(key)
      raise ArgumentError, "attribute can't be blank" if key.nil?

      unless key.is_a?(String) || key.is_a?(Symbol)
        raise ArgumentError, 'attribute must be a String or Symbol'
      end

      raise ArgumentError, "attribute can't be blank" if key.empty?

      return if self.class::Attributes.key?(key.to_s)

      raise ArgumentError, "unknown attribute #{key.inspect}"
    end
  end
end
