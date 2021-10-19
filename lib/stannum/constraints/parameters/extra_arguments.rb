# frozen_string_literal: true

require 'stannum/constraints/parameters'
require 'stannum/constraints/tuples/extra_items'

module Stannum::Constraints::Parameters
  # Validates that the arguments passed to a method have no extra items.
  #
  # @example
  #   constraint = Stannum::Constraints::Parameters::ExtraArguments.new(3)
  #
  #   constraint.matches?([])           #=> true
  #   constraint.matches?([1])          #=> true
  #   constraint.matches?([1, 2, 3])    #=> true
  #   constraint.matches?([1, 2, 3, 4]) #=> false
  class ExtraArguments < Stannum::Constraints::Tuples::ExtraItems
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.parameters.no_extra_arguments'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.parameters.extra_arguments'
  end
end
