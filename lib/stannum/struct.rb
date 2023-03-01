# frozen_string_literal: true

require 'stannum/entities/attributes'
require 'stannum/entities/constraints'
require 'stannum/entities/properties'

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
  module Struct
    include Stannum::Entities::Properties
    include Stannum::Entities::Attributes
    include Stannum::Entities::Constraints

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
      unless attributes.is_a?(Hash)
        raise ArgumentError, 'attributes must be a Hash'
      end

      super(**attributes)

      SleepingKingStudios::Tools::CoreTools.deprecate(
        'Stannum::Struct',
        'use Stannum::Entity instead'
      )
    end
  end
end
