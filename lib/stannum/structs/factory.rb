# frozen_string_literal: true

require 'stannum/structs/attributes'

module Stannum::Structs
  # Decorator that adds ::Attributes and ::Contract constants to a struct class.
  class Factory
    # @return [Stannum::Structs::Factory] a shared factory instance.
    def self.instance
      @instance ||= new
    end

    # Decorates a class with a struct's ::Attributes and ::Contract constants.
    #
    # @param struct_class [Class] The class to decorate as a struct.
    def call(struct_class)
      validate_struct_class(struct_class)

      return if struct_class?(struct_class)

      initialize_attributes(struct_class)
      initialize_contract(struct_class)
    end

    private

    def initialize_attributes(struct_class)
      attributes = Stannum::Structs::Attributes.new

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

    def validate_struct_class(struct_class)
      return if struct_class.is_a?(Class)

      raise ArgumentError,
        'struct class must be a Class',
        caller(1..-1)
    end
  end
end
