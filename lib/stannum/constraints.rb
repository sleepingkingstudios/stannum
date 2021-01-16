# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined constraints.
  module Constraints
    autoload :Absence,   'stannum/constraints/absence'
    autoload :Anything,  'stannum/constraints/anything'
    autoload :Base,      'stannum/constraints/base'
    autoload :Delegator, 'stannum/constraints/delegator'
    autoload :Enum,      'stannum/constraints/enum'
    autoload :Hashes,    'stannum/constraints/hashes'
    autoload :Identity,  'stannum/constraints/identity'
    autoload :Methods,   'stannum/constraints/methods'
    autoload :Nothing,   'stannum/constraints/nothing'
    autoload :Presence,  'stannum/constraints/presence'
    autoload :Tuples,    'stannum/constraints/tuples'
    autoload :Type,      'stannum/constraints/type'
    autoload :Types,     'stannum/constraints/types'
    autoload :Union,     'stannum/constraints/union'
  end
end
