# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # A UUID constraint asserts the value is a string in UUID format.
  #
  # @example Using a UUID constraint with a String format.
  #   constraint = Stannum::Constraints::Uuid.new
  #
  #   constraint.matches?(nil)                                    #=> false
  #   constraint.matches?('Hello, world')                         #=> false
  #   constraint.matches?('01234567-89ab-cdef-0123-456789abcdef') #=> true
  class Uuid < Stannum::Constraints::Format
    # The :type of the error generated for a matching object.
    NEGATED_TYPE = 'stannum.constraints.is_a_uuid'

    # The :type of the error generated for a non-matching object.
    TYPE = 'stannum.constraints.is_not_a_uuid'

    # Regular expression describing a valid upper- or lower-case UUID.
    UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    def initialize(**options)
      super(UUID_FORMAT, **options)
    end
  end
end
