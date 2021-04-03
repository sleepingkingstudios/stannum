# frozen_string_literal: true

require 'stannum'

require 'support/structs/factory'
require 'support/structs/gadget'

module Spec
  class BuildGadget
    extend  Stannum::ParameterValidation
    include Stannum::ParameterValidation

    class << self
      validate_parameters :new do
        keyword :factory, Spec::Factory
      end
    end

    def initialize(factory:)
      @factory = factory
    end

    attr_reader :factory

    def call(attributes:, gadget_class: Gadget)
      [true, gadget_class.new(**attributes)]
    end
    validate_parameters :call do
      keyword :attributes,   Hash
      keyword :gadget_class, Class, default: true
    end

    private

    def handle_invalid_parameters(errors:, **_)
      [false, errors]
    end
  end
end
