# frozen_string_literal: true

require 'stannum'
require 'stannum/entities/associations'
require 'stannum/entities/attributes'
require 'stannum/entities/constraints'
require 'stannum/entities/primary_key'
require 'stannum/entities/properties'

module Stannum
  # Abstract module for defining objects with structured attributes.
  #
  # @example Defining Attributes
  #   class Widget
  #     include Stannum::Entity
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
  module Entity
    include Stannum::Entities::Properties
    include Stannum::Entities::Attributes
    include Stannum::Entities::Associations
    include Stannum::Entities::PrimaryKey
    include Stannum::Entities::Constraints
  end
end
