# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for pre-defined constraints.
  module Constraints
    autoload :Base,     'stannum/constraints/base'
    autoload :Anything, 'stannum/constraints/anything'
    autoload :Nothing,  'stannum/constraints/nothing'
    autoload :Presence, 'stannum/constraints/presence'
    autoload :Type,     'stannum/constraints/type'
  end
end
