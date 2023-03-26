# frozen_string_literal: true

require 'stannum'

module Spec
  class Item
    include Stannum::Entity

    UUID_FORMAT = /\A[A-Fa-f0-9-]+\z/.freeze
    private_constant :UUID_FORMAT

    define_primary_key :uuid, String

    define_attribute :name,  String
    define_attribute :price, Integer, optional: true

    constraint(:uuid) { |uuid| uuid.is_a?(String) && uuid.match?(UUID_FORMAT) }
  end
end
