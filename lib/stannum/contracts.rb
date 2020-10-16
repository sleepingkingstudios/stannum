# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined contracts.
  module Contracts
    autoload :Base,               'stannum/contracts/base'
    autoload :Builder,            'stannum/contracts/builder'
    autoload :Definition,         'stannum/contracts/definition'
    autoload :HashContract,       'stannum/contracts/hash_contract'
    autoload :IndifferentHashContract,
      'stannum/contracts/indifferent_hash_contract'
    autoload :Parameters,         'stannum/contracts/parameters'
    autoload :ParametersContract, 'stannum/contracts/parameters_contract'
    autoload :PropertyContract,   'stannum/contracts/property_contract'
    autoload :TupleContract,      'stannum/contracts/tuple_contract'
  end
end
