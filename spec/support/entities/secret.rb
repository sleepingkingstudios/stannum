# frozen_string_literal: true

require 'stannum/entity'

require 'support/entities/room'

module Spec
  class Secret
    include Stannum::Entity

    association :one, :room, class_name: 'Spec::Room'

    attribute :difficulty, 'Integer'
  end
end
