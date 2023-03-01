# frozen_string_literal: true

require 'stannum'

require 'support/entities/gadget'

module Spec
  class ActivateGadget
    include Stannum::ParameterValidation

    def call(gadget)
      gadget.activate!
    end
    validate_parameters :call do
      argument :gadget, Spec::Gadget
    end
  end
end
