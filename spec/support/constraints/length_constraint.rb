# frozen_string_literal: true

require 'stannum'

module Spec
  class LengthConstraint < Stannum::Constraints::Base
    NEGATED_TYPE = 'spec.constraints.right_length'

    TYPE = 'spec.constraints.wrong_length'

    def initialize(expected)
      super()

      @expected = expected
    end

    attr_reader :expected

    def matches?(actual)
      actual.respond_to?(:length) && actual.length == expected
    end

    def negated_type
      NEGATED_TYPE
    end

    def type
      TYPE
    end
  end
end
