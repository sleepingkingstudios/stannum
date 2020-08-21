# frozen_string_literal: true

require 'stannum'

module Spec
  class FormatConstraint < Stannum::Constraint
    NEGATED_TYPE = 'spec.constraints.right_format'

    TYPE = 'spec.constraints.wrong_format'

    def initialize(expected)
      super(
        negated_type: NEGATED_TYPE,
        type:         TYPE
      ) { |actual| actual.respond_to?(:match?) && actual.match?(expected) }

      @expected = expected
    end

    attr_reader :expected
  end
end
