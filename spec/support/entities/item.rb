# frozen_string_literal: true

require 'stannum'

module Spec
  class Item
    include Stannum::Entity

    define_primary_key :uuid, String

    define_attribute :name,  String
    define_attribute :price, Integer, optional: true

    constraint :uuid, Stannum::Constraints::Uuid.new
  end
end
