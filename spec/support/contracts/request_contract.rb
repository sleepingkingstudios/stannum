# frozen_string_literal: true

require 'stannum/contracts/indifferent_hash_contract'

module Spec
  class RequestContract < Stannum::Contracts::IndifferentHashContract
    def initialize
      super do
        key :password, Stannum::Constraints::Type.new(String)

        key :username, Stannum::Constraints::Type.new(String)
      end
    end
  end
end
