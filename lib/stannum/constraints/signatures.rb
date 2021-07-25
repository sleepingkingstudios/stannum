# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for constraints that match objects by methods.
  module Signatures
    autoload :Map,   'stannum/constraints/signatures/map'
    autoload :Tuple, 'stannum/constraints/signatures/tuple'
  end
end
