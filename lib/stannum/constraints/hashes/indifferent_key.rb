# frozen_string_literal: true

require 'stannum/constraints/hashes'

module Stannum::Constraints::Hashes
  # Constraint for validating an indifferent hash key.
  #
  # To be a valid indifferent Hash key, an object must be a String or a Symbol
  # and cannot be empty.
  #
  # @example With nil
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?(nil) #=> false
  #   constraint.errors_for(nil)
  #   #=> [{ type: 'absent', data: {}, path: [], message: nil }]
  #
  # @example With an Object
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?(Object.new.freeze) #=> false
  #   constraint.errors_for(Object.new.freeze)
  #   #=> [{ type: 'is_not_string_or_symbol', data: {}, path: [], message: nil }]
  #
  # @example With an empty String
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?('') #=> false
  #   constraint.errors_for('')
  #   #=> [{ type: 'absent', data: {}, path: [], message: nil }]
  #
  # @example With a String
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?('a string') #=> true
  #
  # @example With an empty Symbol
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?(:'') #=> false
  #   constraint.errors_for(:'')
  #   #=> [{ type: 'absent', data: {}, path: [], message: nil }]
  #
  # @example With a Symbol
  #   constraint = Stannum::Constraints::Hashes::IndifferentKey.new
  #   constraint.matches?(:a_symbol) #=> true
  class IndifferentKey < Stannum::Constraints::Base
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.hashes.is_string_or_symbol'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.hashes.is_not_string_or_symbol'

    # (see Stannum::Constraints::Base#errors_for)
    def errors_for(actual, errors: nil)
      errors ||= Stannum::Errors.new

      return errors.add(Stannum::Constraints::Presence::TYPE) if actual.nil?

      return super unless indifferent_key_type?(actual)

      return errors unless actual.empty?

      errors.add(Stannum::Constraints::Presence::TYPE)
    end

    # @return [true, false] true if the object is a non-empty String or Symbol.
    def matches?(actual)
      indifferent_key_type?(actual) && !actual.empty?
    end
    alias match? matches?

    private

    def indifferent_key_type?(actual)
      actual.is_a?(String) || actual.is_a?(Symbol)
    end
  end
end
