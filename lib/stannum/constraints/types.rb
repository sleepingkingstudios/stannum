# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for type constraints.
  module Types
    autoload :Array,  'stannum/constraints/types/array'
    autoload :Hash,   'stannum/constraints/types/hash'
    autoload :HashWithIndifferentKeys,
      'stannum/constraints/types/hash_with_indifferent_keys'
    autoload :HashWithStringKeys,
      'stannum/constraints/types/hash_with_string_keys'
    autoload :Map,    'stannum/constraints/types/map'
    autoload :Nil,    'stannum/constraints/types/nil'
    autoload :Proc,   'stannum/constraints/types/proc'
    autoload :String, 'stannum/constraints/types/string'
    autoload :Symbol, 'stannum/constraints/types/symbol'
    autoload :Tuple,  'stannum/constraints/types/tuple'
  end
end
