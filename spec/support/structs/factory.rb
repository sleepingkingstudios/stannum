# frozen_string_literal: true

require 'stannum'

require 'support/structs/gadget'

module Spec
  class Factory
    include Stannum::Struct

    attribute :address, String
    attribute :gadget,  Spec::Gadget
  end
end
