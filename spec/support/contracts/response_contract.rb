# frozen_string_literal: true

require 'stannum/contracts/hash_contract'

module Spec
  class ResponseContract < Stannum::Contracts::HashContract
    def initialize # rubocop:disable Metrics/MethodLength
      super do
        key :status, Stannum::Constraints::Type.new(Integer)

        key(
          :json,
          Stannum::Contracts::HashContract.new(allow_extra_keys: true) do
            options = {
              message:         'is not true or false',
              negated_message: 'is true or false',
              negated_type:    'spec.is_boolean',
              type:            'spec.is_not_boolean'
            }

            key(:ok, **options) do |actual|
              actual == true || actual == false # rubocop:disable Style/MultipleComparison
            end
          end
        )
      end
    end
  end
end
