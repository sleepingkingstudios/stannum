# frozen_string_literal: true

require 'stannum/constraints/hashes'
require 'stannum/constraints/hashes/extra_keys'

module Stannum::Constraints::Hashes
  # Constraint for validating the keys of an indifferent hash-like object.
  #
  # When using this constraint, the keys must be strings or symbols, but it does
  # not matter which - a constraint configured with string keys will match a
  # hash with symbol keys, and vice versa.
  #
  # @example
  #   keys       = %i[fuel mass size]
  #   constraint = Stannum::Constraints::Hashes::ExpectedKeys.new(keys)
  #
  #   constraint.matches?({})                                #=> true
  #   constraint.matches?({ fuel: 'Monopropellant' })        #=> true
  #   constraint.matches?({ 'fuel' => 'Monopropellant' })    #=> true
  #   constraint.matches?({ electric: true, fuel: 'Xenon' }) #=> false
  #   constraint.matches?({ fuel: 'LF/O', mass: '1 ton', size: 'Medium' })
  #   #=> true
  #   constraint.matches?(
  #     { fuel: 'LF', mass: '2 tons', nuclear: true, size: 'Medium' }
  #   )
  #   #=> false
  class IndifferentExtraKeys < Stannum::Constraints::Hashes::ExtraKeys
    # @return [Set] the expected keys.
    def expected_keys
      keys = options[:expected_keys]

      return indifferent_keys_for(keys) unless keys.is_a?(Proc)

      indifferent_keys_for(keys.call)
    end

    private

    def indifferent_keys_for(keys)
      Set.new(
        keys.reduce([]) do |ary, key|
          ary << key.to_s << key.intern
        end
      )
    end
  end
end
