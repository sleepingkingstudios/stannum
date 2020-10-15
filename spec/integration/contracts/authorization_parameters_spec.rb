# frozen_string_literal: true

require 'support/contracts/authorization_parameters'

# @note Integration spec for Stannum::Contracts::ParametersContract.
RSpec.describe Spec::AuthorizationParameters do
  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1] }
    let(:actual) do
      {
        arguments: %i[access],
        keywords:  { user: Spec::User.new(name: 'Alan Bradley') }
      }
    end

    describe 'with a non-Hash object' do
      let(:actual) { Object.new.freeze }
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

    describe 'with an empty Hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Array },
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with empty parameters' do
      let(:actual) { { arguments: [], keywords: {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: nil,
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Spec::User },
            message: nil,
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with missing arguments' do
      let(:actual) { super().merge(arguments: []) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: nil,
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with invalid arguments' do
      let(:actual) { super().merge(arguments: %w[access anything]) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: nil,
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: false, type: Class },
            message: nil,
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with minimal arguments' do
      let(:actual) { super().merge(arguments: %i[process]) }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with all arguments' do
      let(:actual) { super().merge(arguments: [:process, String]) }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with extra arguments' do
      let(:actual) do
        super().merge(
          arguments: [:process, String, 'dry-run', 'verbose']
        )
      end
      let(:expected_errors) do
        contract   = Stannum::Contracts::Parameters::ArgumentsContract
        error_type = contract::EXTRA_ARGUMENTS_TYPE

        [
          {
            data:    { value: 'dry-run' },
            message: nil,
            path:    [:arguments, 2],
            type:    error_type
          },
          {
            data:    { value: 'verbose' },
            message: nil,
            path:    [:arguments, 3],
            type:    error_type
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with missing keywords' do
      let(:actual) { super().merge(keywords: {}) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Spec::User },
            message: nil,
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with invalid keywords' do
      let(:actual) do
        super().merge(keywords: { role: :hacker, user: 'Alan Bradley' })
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Spec::User },
            message: nil,
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: false, type: String },
            message: nil,
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with minimal keywords' do
      let(:actual) do
        super().merge(keywords: { user: Spec::User.new(name: 'Kevin Flynn') })
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with all keywords' do
      let(:actual) do
        super().merge(
          keywords: {
            role: 'Administrator',
            user: Spec::User.new(name: 'Kevin Flynn')
          }
        )
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with extra keywords' do
      let(:actual) do
        super().merge(
          keywords: {
            role:   'Administrator',
            secret: '12345',
            token:  'bGV0bWVpbg==',
            user:   Spec::User.new(name: 'Kevin Flynn')
          }
        )
      end
      let(:expected_errors) do
        contract   = Stannum::Contracts::Parameters::KeywordsContract
        error_type = contract::EXTRA_KEYWORDS_TYPE

        [
          {
            data:    { value: '12345' },
            message: nil,
            path:    %i[keywords secret],
            type:    error_type
          },
          {
            data:    { value: 'bGV0bWVpbg==' },
            message: nil,
            path:    %i[keywords token],
            type:    error_type
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with valid parameters' do
      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) { Array(contract.negated_match(actual))[1] }
    let(:actual) do
      {
        arguments: %i[access],
        keywords:  { user: Spec::User.new(name: 'Alan Bradley') }
      }
    end

    describe 'with a non-Hash object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with an empty Hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with empty parameters' do
      let(:actual) { { arguments: [], keywords: {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Array },
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Methods::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Class },
            message: nil,
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: false, type: String },
            message: nil,
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with valid parameters' do
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Array },
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Methods::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[arguments],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Symbol },
            message: nil,
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Class },
            message: nil,
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: false, type: String },
            message: nil,
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Spec::User },
            message: nil,
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end
end
