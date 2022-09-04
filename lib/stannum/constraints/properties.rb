# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for Object property-specific constraints.
  module Properties
    autoload :Base,
      'stannum/constraints/properties/base'
    autoload :DoNotMatchProperty,
      'stannum/constraints/properties/do_not_match_property'
    autoload :MatchProperty,
      'stannum/constraints/properties/match_property'
    autoload :Matching,
      'stannum/constraints/properties/matching'
  end
end
