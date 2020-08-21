# frozen_string_literal: true

require 'stannum/contracts/base'

require 'support/contracts/response_contract'

module Spec
  class SignedResponseContract < Stannum::Contracts::HashContract
    def initialize
      super do
        key :signature, Stannum::Constraints::Presence.new
      end

      include ResponseContract.new
    end
  end
end
