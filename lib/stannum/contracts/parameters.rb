# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # Namespace for contracts that constrain method parameters.
  module Parameters
    autoload :SignatureContract,
      'stannum/contracts/parameters/signature_contract'
  end
end
