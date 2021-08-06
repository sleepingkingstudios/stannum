# frozen_string_literal: true

require 'stannum'

module Spec
  class ManufacturerContract < Stannum::Contract
    NEGATED_TYPE = 'spec.contracts.a_manufacturer'

    TYPE = 'spec.contracts.not_a_manufacturer'

    def initialize # rubocop:disable Metrics/MethodLength
      super

      add_constraint(
        Stannum::Constraint.new(
          negated_type: NEGATED_TYPE,
          type:         TYPE
        ) { |actual| actual.is_a?(Spec::Manufacturer) },
        sanity: true
      )

      add_constraint(
        Stannum::Constraints::Presence.new,
        property:      :name,
        property_name: :registered_name
      )

      add_constraint(
        Stannum::Constraints::Presence.new,
        property: %i[factory gadget name]
      )
    end
  end
end
