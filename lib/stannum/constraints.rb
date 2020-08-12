# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined constraints.
  module Constraints
    autoload :Anything, 'stannum/constraints/anything'
    autoload :Base,     'stannum/constraints/base'
    autoload :Methods,  'stannum/constraints/methods'
    autoload :Nothing,  'stannum/constraints/nothing'
    autoload :Presence, 'stannum/constraints/presence'
    autoload :Tuples,   'stannum/constraints/tuples'
    autoload :Type,     'stannum/constraints/type'
    autoload :Types,    'stannum/constraints/types'
  end
end
