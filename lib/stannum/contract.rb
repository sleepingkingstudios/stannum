# frozen_string_literal: true

require 'stannum'

module Stannum
  # Contract class for defining a custom or one-off contract instance.
  #
  # @example Defining A Custom Contract
  #   user_contract = Stannum::Contract.new do
  #     # Sanity constraints are evaluated first, and if a sanity constraint
  #     # fails, the contract will immediately halt.
  #     constraint Stannum::Constraints::Type.new(User), sanity: true
  #
  #     # You can also define a constraint using a block.
  #     constraint(type: 'example.is_not_user') do |user|
  #       user.role == 'user'
  #     end
  #
  #     # You can define a constraint on a property of the object.
  #     property :name, Stannum::Constraints::Presence.new
  #   end
  #
  # @see Stannum::Contracts::Base.
  class Contract < Stannum::Contracts::PropertyContract
  end
end
