# frozen_string_literal: true

require 'stannum/entity'

module Spec
  class Room
    include Stannum::Entity

    attribute :name, String
  end
end
