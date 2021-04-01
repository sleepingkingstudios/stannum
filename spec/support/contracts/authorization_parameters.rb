# frozen_string_literal: true

require 'stannum/contracts/parameters_contract'

require 'support/structs/user'

module Spec
  class AuthorizationParameters < Stannum::Contracts::ParametersContract
    def initialize
      super do
        argument :action, Symbol

        argument :record_class, Class, default: true

        keyword :role, String, optional: true

        keyword :user, Stannum::Constraints::Type.new(Spec::User)
      end
    end
  end
end
