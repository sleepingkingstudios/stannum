# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/contracts/string_response_contract'

# @note Integration spec for Stannum::Contracts::HashContract with string keys.
RSpec.describe Spec::StringResponseContract do
  include Stannum::RSpec::Matchers

  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1].with_messages }

    describe 'with a non-hash object' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is not a Hash',
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with an empty hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: 'is not a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is not a Hash',
            path:    %w[json],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors.to_a).to deep_match expected_errors.to_a }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing keys' do
      let(:actual) { { 'json' => {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: 'is not a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: 'is not true or false',
            path:    %w[json ok],
            type:    'spec.is_not_boolean'
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra keys' do
      let(:actual) { { 'error' => 'Something went wrong', 'json' => {} } }
      let(:expected_errors) do
        [
          {
            data:    { value: actual['error'] },
            message: 'has extra keys',
            path:    %w[error],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: 'is not a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: 'is not true or false',
            path:    %w[json ok],
            type:    'spec.is_not_boolean'
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with non-matching values' do
      let(:actual) do
        {
          'json'   => { 'ok' => nil },
          'status' => :not_found
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Integer },
            message: 'is not a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    {},
            message: 'is not true or false',
            path:    %w[json ok],
            type:    'spec.is_not_boolean'
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a matching hash' do
      let(:actual) do
        {
          'json'   => { 'data' => { 'id' => 0 }, 'ok' => true },
          'status' => 200
        }
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with a hash with extra keys' do
      let(:actual) do
        {
          'error'  => 'Something went wrong',
          'json'   => { 'ok' => false },
          'status' => 500
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { value: actual['error'] },
            message: 'has extra keys',
            path:    %w[error],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) { Array(contract.negated_match(actual))[1].with_messages }

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
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %w[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra keys' do
      let(:actual) { { 'error' => 'Something went wrong', 'json' => {} } }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with non-matching values' do
      let(:actual) do
        {
          'json'   => { 'ok' => nil },
          'status' => :not_found
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %w[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a matching hash' do
      let(:actual) do
        {
          'json'   => { 'data' => { 'id' => 0 }, 'ok' => true },
          'status' => 200
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %w[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: 'is a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'is true or false',
            path:    %w[json ok],
            type:    'spec.is_boolean'
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with extra keys' do
      let(:actual) do
        {
          'error'  => 'Something went wrong',
          'json'   => { 'ok' => false },
          'status' => 500
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Integer },
            message: 'is a Integer',
            path:    %w[status],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %w[json],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'is true or false',
            path:    %w[json ok],
            type:    'spec.is_boolean'
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end
  end
end
