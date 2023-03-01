# frozen_string_literal: true

require 'stannum'

require 'support/entities/factory'

module Spec
  class Manufacturer
    include Stannum::Entity

    attribute :factory, Spec::Factory
    attribute :name,    String
  end
end
