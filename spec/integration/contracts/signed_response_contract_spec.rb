# frozen_string_literal: true

require 'support/contracts/signed_response_contract'

# @note Integration spec for Stannum::Contracts::HashContract.
RSpec.describe Spec::SignedResponseContract do
  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1] }

    describe 'with a non-hash object' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an empty hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing keys' do
      let(:actual) { { json: {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[json ok],
            type:    'spec.is_not_boolean'
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra keys' do
      let(:actual) { { error: 'Something went wrong', json: {}, status: 500 } }
      let(:expected_errors) do
        [
          {
            data:    { value: actual[:error] },
            message: nil,
            path:    %i[error],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[json ok],
            type:    'spec.is_not_boolean'
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with non-matching values' do
      let(:actual) do
        {
          json:      { ok: nil },
          signature: '',
          status:    :not_found
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[json ok],
            type:    'spec.is_not_boolean'
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a matching hash' do
      let(:actual) do
        {
          json:      { data: { id: 0 }, ok: true },
          signature: 'eyJkYXRhIjp7ImlkIjowfSwib2siOnRydWV9',
          status:    200
        }
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with a hash with extra keys' do
      let(:actual) do
        {
          error:     'Something went wrong',
          json:      { ok: false },
          signature: 'eyJkYXRhIjp7ImlkIjowfSwib2siOnRydWV9',
          status:    500
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { value: actual[:error] },
            message: nil,
            path:    %i[error],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) { Array(contract.negated_match(actual))[1] }

    describe 'with a non-hash object' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with an empty hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing keys' do
      let(:actual) { { json: {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra keys' do
      let(:actual) { { error: 'Something went wrong', json: {}, status: 500 } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with non-matching values' do
      let(:actual) do
        {
          json:      { ok: nil },
          signature: '',
          status:    :not_found
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a matching hash' do
      let(:actual) do
        {
          json:      { data: { id: 0 }, ok: true },
          signature: 'eyJkYXRhIjp7ImlkIjowfSwib2siOnRydWV9',
          status:    200
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[json ok],
            type:    'spec.is_boolean'
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a hash with extra keys' do
      let(:actual) do
        {
          error:     'Something went wrong',
          json:      { ok: false },
          signature: 'eyJkYXRhIjp7ImlkIjowfSwib2siOnRydWV9',
          status:    500
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: nil,
            path:    %i[status],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[json ok],
            type:    'spec.is_boolean'
          },
          {
            data:    {},
            message: nil,
            path:    %i[signature],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end
end
