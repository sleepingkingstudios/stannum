# frozen_string_literal: true

require 'stannum/contracts/hash_contract'

module Spec
  class StringResponseContract < Stannum::Contracts::HashContract
    def initialize # rubocop:disable Metrics/MethodLength
      super do
        key 'status', Stannum::Constraints::Type.new(Integer)

        key(
          'json',
          Stannum::Contracts::HashContract.new(allow_extra_keys: true) do
            type         = 'spec.is_not_boolean'
            negated_type = 'spec.is_boolean'

            key('ok', negated_type: negated_type, type: type) do |actual|
              actual == true || actual == false # rubocop:disable Style/MultipleComparison
            end
          end
        )
      end
    end
  end
end
