# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for type constraints.
  module Types
    autoload :Map,    'stannum/constraints/types/map'
    autoload :Symbol, 'stannum/constraints/types/symbol'
    autoload :Tuple,  'stannum/constraints/types/tuple'
  end
end
