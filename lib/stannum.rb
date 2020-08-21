# frozen_string_literal: true

# A library for specifying and validating data structures.
module Stannum
  autoload :Constraint,  'stannum/constraint'
  autoload :Constraints, 'stannum/constraints'
  autoload :Contracts,   'stannum/contracts'
  autoload :Errors,      'stannum/errors'
  autoload :Struct,      'stannum/struct'
end
