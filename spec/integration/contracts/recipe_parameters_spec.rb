# frozen_string_literal: true

require 'support/contracts/recipe_parameters'

# @note Integration spec for Stannum::Contracts::ParametersContract.
RSpec.describe Spec::RecipeParameters do
  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1] }
    let(:actual) do
      {
        arguments: ['Cutting Board', 'Spatula', 'Stand Mixer'],
        keywords:  {
          water: %w[100 milliliters],
          flour: %w[200 grams],
          salt:  ['a pinch']
        },
        block:     -> {}
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
            data:    { allow_empty: true, required: true, type: Array },
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

    describe 'with no arguments' do
      let(:actual) { super().merge(arguments: []) }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with invalid arguments' do
      let(:actual) do
        super().merge(arguments: ['Rolling Pin', { 'flour' => '500 grams' }])
      end
      let(:expected_errors) do
        [
          {
            data:    { value: { 'flour' => '500 grams' } },
            message: nil,
            path:    [:arguments, :tools, 1],
            type:    Stannum::Constraints::Types::Array::INVALID_ITEM_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with no keywords' do
      let(:actual) { super().merge(keywords: {}) }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with invalid keywords' do
      let(:actual) do
        super().merge(
          keywords: {
            water:  %w[100 milliliters],
            flour:  %w[200 grams],
            salt:   ['a pinch'],
            poison: true,
            glass:  %w[many tiny shards]
          }
        )
      end
      let(:expected_errors) do
        [
          {
            data:    { value: true },
            message: nil,
            path:    %i[keywords ingredients poison],
            type:    Stannum::Constraints::Types::Hash::INVALID_VALUE_TYPE
          },
          {
            data:    { value: %w[many tiny shards] },
            message: nil,
            path:    %i[keywords ingredients glass],
            type:    Stannum::Constraints::Types::Hash::INVALID_VALUE_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with no block' do
      let(:actual) { super().merge(block: nil) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::TYPE
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
        arguments: ['Cutting Board', 'Spatula', 'Stand Mixer'],
        keywords:  {
          water: %w[100 milliliters],
          flour: %w[200 grams],
          salt:  ['a pinch']
        },
        block:     -> {}
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

    describe 'with no arguments' do
      let(:actual) { super().merge(arguments: []) }
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with invalid arguments' do
      let(:actual) do
        super().merge(arguments: ['Rolling Pin', { 'flour' => '500 grams' }])
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with no keywords' do
      let(:actual) { super().merge(keywords: {}) }
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with invalid keywords' do
      let(:actual) do
        super().merge(
          keywords: {
            water:  %w[100 milliliters],
            flour:  %w[200 grams],
            salt:   ['a pinch'],
            poison: true,
            glass:  %w[many tiny shards]
          }
        )
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with no block' do
      let(:actual) { super().merge(block: nil) }
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
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
            data:    { allow_empty: true, required: true, type: Array },
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
            data:    { allow_empty: true, required: true, type: Array },
            message: nil,
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Hash },
            message: nil,
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: nil,
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
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
