# frozen_string_literal: true

require 'stannum'

module Spec
  class Gadget
    include Stannum::Struct

    attribute :name,        String
    attribute :description, String,  optional: true
    attribute :quantity,    Integer, default:  0

    constraint do |struct|
      struct&.description&.match?(/#{struct&.name}/i)
    end

    constraint(:quantity) { |qty| qty.is_a?(Integer) && qty >= 0 }
  end
end
