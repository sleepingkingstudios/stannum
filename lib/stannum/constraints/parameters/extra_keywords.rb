# frozen_string_literal: true

require 'stannum/constraints/hashes/extra_keys'
require 'stannum/constraints/parameters'

module Stannum::Constraints::Parameters
  # Validates that the keywords passed to a method have no extra keys.
  #
  # @example
  #   keys       = %[fuel mass size]
  #   constraint = Stannum::Constraints::Parameters::ExpectedKeywords.new(keys)
  #
  #   constraint.matches?({})                                #=> true
  #   constraint.matches?({ fuel: 'Monopropellant' })        #=> true
  #   constraint.matches?({ electric: true, fuel: 'Xenon' }) #=> false
  #   constraint.matches?({ fuel: 'LF/O', mass: '1 ton', size: 'Medium' })
  #   #=> true
  #   constraint.matches?(
  #     { fuel: 'LF', mass: '2 tons', nuclear: true, size: 'Medium' }
  #   )
  #   #=> false
  class ExtraKeywords < Stannum::Constraints::Hashes::ExtraKeys
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.parameters.no_extra_keywords'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.parameters.extra_keywords'
  end
end
