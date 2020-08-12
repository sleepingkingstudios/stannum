# frozen_string_literal: true

require 'stannum'

module Spec
  class ManufacturerContract < Stannum::Contracts::PropertyContract
    NEGATED_TYPE = 'spec.contracts.a_manufacturer'

    TYPE = 'spec.contracts.not_a_manufacturer'

    def initialize # rubocop:disable Metrics/MethodLength
      super

      add_constraint(
        Stannum::Constraint.new(
          negated_type: NEGATED_TYPE,
          type:         TYPE
        ) { |actual| actual.is_a?(Spec::Manufacturer) }
      )

      add_constraint(
        Stannum::Constraints::Presence.new,
        property: :name
      )

      add_constraint(
        Stannum::Constraints::Presence.new,
        property: %i[factory gadget name]
      )
    end
  end
end
