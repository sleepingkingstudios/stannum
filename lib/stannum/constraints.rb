# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined constraints.
  module Constraints
    autoload :Absence,    'stannum/constraints/absence'
    autoload :Anything,   'stannum/constraints/anything'
    autoload :Base,       'stannum/constraints/base'
    autoload :Boolean,    'stannum/constraints/boolean'
    autoload :Delegator,  'stannum/constraints/delegator'
    autoload :Enum,       'stannum/constraints/enum'
    autoload :Equality,   'stannum/constraints/equality'
    autoload :Hashes,     'stannum/constraints/hashes'
    autoload :Identity,   'stannum/constraints/identity'
    autoload :Nothing,    'stannum/constraints/nothing'
    autoload :Parameters, 'stannum/constraints/parameters'
    autoload :Presence,   'stannum/constraints/presence'
    autoload :Properties, 'stannum/constraints/properties'
    autoload :Signature,  'stannum/constraints/signature'
    autoload :Signatures, 'stannum/constraints/signatures'
    autoload :Tuples,     'stannum/constraints/tuples'
    autoload :Type,       'stannum/constraints/type'
    autoload :Types,      'stannum/constraints/types'
    autoload :Union,      'stannum/constraints/union'
  end
end
