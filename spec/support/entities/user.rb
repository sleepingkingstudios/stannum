# frozen_string_literal: true

require 'stannum'

module Spec
  class User
    include Stannum::Entity

    attribute :name, String
  end
end
