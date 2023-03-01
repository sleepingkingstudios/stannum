# frozen_string_literal: true

require 'stannum'

require 'support/entities/gadget'

module Spec
  class Factory
    include Stannum::Entity

    attribute :address, String
    attribute :gadget,  Spec::Gadget
  end
end
