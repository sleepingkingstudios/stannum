# frozen_string_literal: true

require 'stannum'

require 'support/commands/activate_gadget'
require 'support/entities/gizmo'

module Spec
  class ActivateGizmo < Spec::ActivateGadget
    validate_parameters :call do
      argument :gadget, Spec::Gizmo
    end
  end
end
