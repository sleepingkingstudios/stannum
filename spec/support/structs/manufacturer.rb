# frozen_string_literal: true

require 'stannum'

require 'support/structs/factory'

module Spec
  class Manufacturer
    include Stannum::Struct

    attribute :factory, Spec::Factory
    attribute :name,    String
  end
end
