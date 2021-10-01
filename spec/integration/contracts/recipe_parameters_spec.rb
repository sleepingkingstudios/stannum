# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/contracts/recipe_parameters'

# @note Integration spec for Stannum::Contracts::ParametersContract.
RSpec.describe Spec::RecipeParameters do
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
            data:    { type: String, required: true },
            message: 'is not a String',
            path:    [:arguments, :tools, 1],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors expected_errors }

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
            data:    { methods: %i[[] each size], missing: %i[[] each size] },
            message: 'does not respond to the methods',
            path:    %i[keywords ingredients poison],
            type:    Stannum::Constraints::Signature::TYPE
          },
          {
            data:    { value: 'shards' },
            message: 'has extra items',
            path:    [:keywords, :ingredients, :glass, 2],
            type:    Stannum::Constraints::Tuples::ExtraItems::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors expected_errors }

      it { expect(status).to be false }
    end

    describe 'with no block' do
      let(:actual) { super().merge(block: nil) }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: Proc },
            message: 'is not a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::TYPE
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
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with no arguments' do
      let(:actual) { super().merge(arguments: []) }
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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with invalid arguments' do
      let(:actual) do
        super().merge(arguments: ['Rolling Pin', { 'flour' => '500 grams' }])
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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with no keywords' do
      let(:actual) { super().merge(keywords: {}) }
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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with no block' do
      let(:actual) { super().merge(block: nil) }
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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
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
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { methods: %i[[] each size], missing: [] },
            message: 'responds to the methods',
            path:    %i[arguments],
            type:    Stannum::Constraints::Signature::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Array },
            message: 'is a Array',
            path:    %i[arguments tools],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { allow_empty: true, required: true, type: Hash },
            message: 'is a Hash',
            path:    %i[keywords ingredients],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: false, type: Proc },
            message: 'is a Proc',
            path:    %i[block],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    { required: true, type: Proc },
            message: 'is a Proc',
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
