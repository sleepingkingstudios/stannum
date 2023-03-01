# frozen_string_literal: true

require 'stannum'

require 'support/entities/gadget'

module Spec
  class Gizmo < Spec::Gadget
    attribute :size, String

    constraint(:size) do |size|
      %w[Tiny Small Medium Large Huge Gargantuan Colossal].include?(size)
    end
  end
end
