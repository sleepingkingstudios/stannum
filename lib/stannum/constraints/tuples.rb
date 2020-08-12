# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for tuple-specific constraints.
  module Tuples
    autoload :ExtraItems, 'stannum/constraints/tuples/extra_items'
  end
end
