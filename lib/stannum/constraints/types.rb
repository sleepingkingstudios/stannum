# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for type constraints.
  module Types
    autoload :ArrayType,      'stannum/constraints/types/array_type'
    autoload :BigDecimalType, 'stannum/constraints/types/big_decimal_type'
    autoload :FloatType,      'stannum/constraints/types/float_type'
    autoload :HashType,       'stannum/constraints/types/hash_type'
    autoload :HashWithIndifferentKeys,
      'stannum/constraints/types/hash_with_indifferent_keys'
    autoload :HashWithStringKeys,
      'stannum/constraints/types/hash_with_string_keys'
    autoload :NilType,        'stannum/constraints/types/nil_type'
    autoload :ProcType,       'stannum/constraints/types/proc_type'
    autoload :StringType,     'stannum/constraints/types/string_type'
    autoload :SymbolType,     'stannum/constraints/types/symbol_type'
  end
end
