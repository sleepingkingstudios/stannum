# frozen_string_literal: true

require 'stannum'

module Spec
  class Gadget
    include Stannum::Entity

    attribute :name,        String
    attribute :description, String,  optional: true
    attribute :quantity,    Integer, default:  0

    constraint do |struct|
      struct&.description&.match?(/#{struct&.name}/i)
    end

    constraint(:quantity) { |qty| qty.is_a?(Integer) && qty >= 0 }

    def active?
      !!@active
    end

    def activate!
      @active = true
    end
  end
end
