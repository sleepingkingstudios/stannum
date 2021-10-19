# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/contracts/authorization_parameters'

# @note Integration spec for Stannum::Contracts::ParametersContract.
RSpec.describe Spec::AuthorizationParameters do
  include Stannum::RSpec::Matchers

  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1].with_messages }
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

    describe 'with an empty Hash' do
      let(:actual) { {} }
      let(:expected_errors) do
        [
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is not a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is not a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with empty parameters' do
      let(:actual) { { arguments: [], keywords: {} } }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: 'is not a Symbol',
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Spec::User },
            message: 'is not a Spec::User',
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with missing arguments' do
      let(:actual) { super().merge(arguments: []) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: 'is not a Symbol',
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with invalid arguments' do
      let(:actual) { super().merge(arguments: %w[access anything]) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Symbol },
            message: 'is not a Symbol',
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Class },
            message: 'is not a Class',
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with minimal arguments' do
      let(:actual) { super().merge(arguments: %i[process]) }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with explicit nil arguments' do
      let(:actual) { super().merge(arguments: [:process, nil]) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Class },
            message: 'is not a Class',
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
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
            message: 'has extra arguments',
            path:    [:arguments, 2],
            type:    error_type
          },
          {
            data:    { value: 'verbose' },
            message: 'has extra arguments',
            path:    [:arguments, 3],
            type:    error_type
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with missing keywords' do
      let(:actual) { super().merge(keywords: {}) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Spec::User },
            message: 'is not a Spec::User',
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with invalid keywords' do
      let(:actual) do
        super().merge(keywords: { role: :hacker, user: 'Alan Bradley' })
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::TYPE
          },
          {
            data:    { required: true, type: Spec::User },
            message: 'is not a Spec::User',
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with minimal keywords' do
      let(:actual) do
        super().merge(keywords: { user: Spec::User.new(name: 'Kevin Flynn') })
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with explicit nil keywords' do
      let(:actual) do
        super().merge(
          keywords: {
            role: nil,
            user: Spec::User.new(name: 'Kevin Flynn')
          }
        )
      end
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
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
        [
          {
            data:    { value: '12345' },
            message: 'has extra keywords',
            path:    %i[keywords secret],
            type:    Stannum::Constraints::Parameters::ExtraKeywords::TYPE
          },
          {
            data:    { value: 'bGV0bWVpbg==' },
            message: 'has extra keywords',
            path:    %i[keywords token],
            type:    Stannum::Constraints::Parameters::ExtraKeywords::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with valid parameters' do
      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) { Array(contract.negated_match(actual))[1].with_messages }
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
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc or nil',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with empty parameters' do
      let(:actual) { { arguments: [], keywords: {} } }
      let(:expected_errors) do
        extra_keywords_type =
          Stannum::Constraints::Parameters::ExtraKeywords::NEGATED_TYPE

        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each each_index], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra items',
            path:    %i[arguments],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Class },
            message: 'is a Class',
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keywords',
            path:    %i[keywords],
            type:    extra_keywords_type
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc or nil',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with valid parameters' do
      let(:expected_errors) do
        extra_keywords_type =
          Stannum::Constraints::Parameters::ExtraKeywords::NEGATED_TYPE

        [
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keys',
            path:    [],
            type:    Stannum::Constraints::Hashes::ExtraKeys::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each each_index], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra items',
            path:    %i[arguments],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Symbol },
            message: 'is a Symbol',
            path:    %i[arguments action],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Class },
            message: 'is a Class',
            path:    %i[arguments record_class],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'does not have extra keywords',
            path:    %i[keywords],
            type:    extra_keywords_type
          },
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    %i[keywords role],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Spec::User },
            message: 'is a Spec::User',
            path:    %i[keywords user],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc or nil',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end
  end
end
