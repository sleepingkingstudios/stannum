# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for Object property-specific constraints.
  module Properties
    autoload :Base,          'stannum/constraints/properties/base'
    autoload :MatchProperty, 'stannum/constraints/properties/match_property'
  end
end
