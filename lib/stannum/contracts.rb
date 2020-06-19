# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined contracts.
  module Contracts
    autoload :Builder,      'stannum/contracts/builder'
    autoload :HashContract, 'stannum/contracts/hash_contract'
    autoload :MapContract,  'stannum/contracts/map_contract'
  end
end
