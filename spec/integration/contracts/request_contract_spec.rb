# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/contracts/request_contract'

# @note Integration spec for Stannum::Contracts::IndifferentHashContract.
RSpec.describe Spec::RequestContract do
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
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing string keys' do
      let(:actual) { { 'username' => 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing symbol keys' do
      let(:actual) { { username: 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra string keys' do
      let(:actual) { { 'role' => 'admin', 'username' => 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { value: actual['role'] },
            message: 'has extra keys',
            path:    %w[role],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra symbol keys' do
      let(:actual) { { role: 'admin', username: 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { value: actual[:role] },
            message: 'has extra keys',
            path:    %i[role],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with string keys and non-matching values' do
      let(:actual) do
        {
          'password' => 12_345,
          'username' => 67_890
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with symbol keys and non-matching values' do
      let(:actual) do
        {
          password: 12_345,
          username: 67_890
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a matching hash with string keys' do
      let(:actual) do
        {
          'username' => 'Alan Bradley',
          'password' => 'tronlives'
        }
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with a matching hash with symbol keys' do
      let(:actual) do
        {
          username: 'Alan Bradley',
          password: 'tronlives'
        }
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with a hash with extra string keys' do
      let(:actual) do
        {
          'username' => 'Alan Bradley',
          'password' => 'tronlives',
          'role'     => 'admin'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { value: actual['role'] },
            message: 'has extra keys',
            path:    %w[role],
            type:    Stannum::Constraints::Hashes::ExtraKeys::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with extra symbol keys' do
      let(:actual) do
        {
          username: 'Alan Bradley',
          password: 'tronlives',
          role:     'admin'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { value: actual[:role] },
            message: 'has extra keys',
            path:    %i[role],
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
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing string keys' do
      let(:actual) { { 'username' => 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing symbol keys' do
      let(:actual) { { username: 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra string keys' do
      let(:actual) { { 'role' => 'admin', 'username' => 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with missing and extra symbol keys' do
      let(:actual) { { role: 'admin', username: 'Alan Bradley' } }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with string keys and non-matching values' do
      let(:actual) do
        {
          'password' => 12_345,
          'username' => 67_890
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with symbol keys and non-matching values' do
      let(:actual) do
        {
          password: 12_345,
          username: 67_890
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a matching hash with string keys' do
      let(:actual) do
        {
          'username' => 'Alan Bradley',
          'password' => 'tronlives'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a matching hash with symbol keys' do
      let(:actual) do
        {
          username: 'Alan Bradley',
          password: 'tronlives'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    %i[],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with extra string keys' do
      let(:actual) do
        {
          'username' => 'Alan Bradley',
          'password' => 'tronlives',
          'role'     => 'admin'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with a hash with extra symbol keys' do
      let(:actual) do
        {
          username: 'Alan Bradley',
          password: 'tronlives',
          role:     'admin'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[password],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[username],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end
  end
end
