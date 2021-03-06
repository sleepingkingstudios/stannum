# frozen_string_literal: true

require 'support/contracts/baseball_contract'

# @note Integration spec for Stannum::Contracts::TupleContract.
RSpec.describe Spec::BaseballContract do
  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1] }

    describe 'with a non-tuple object' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    {
              missing: %i[[] each size],
              methods: %i[[] each size]
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an empty tuple' do
      let(:actual) { [] }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with missing items' do
      let(:actual) { %w[Who] }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with invalid items' do
      let(:actual) { %w[ichi ni san] }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with mixed invalid and valid items' do
      let(:actual) { ['Who', 'ni', 'I Don\'t Know'] }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with valid items' do
      let(:actual) { ['Who', 'What', 'I Don\'t Know'] }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with a tuple with extra items' do
      let(:actual) { ['Who', 'What', 'I Don\'t Know', 'Tomorrow', 'Today'] }
      let(:expected_errors) do
        [
          {
            data:    { value: 'Tomorrow' },
            message: nil,
            path:    [3],
            type:    Stannum::Constraints::Tuples::ExtraItems::TYPE
          },
          {
            data:    { value: 'Today' },
            message: nil,
            path:    [4],
            type:    Stannum::Constraints::Tuples::ExtraItems::TYPE
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

    describe 'with a non-tuple object' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with an empty tuple' do
      let(:actual) { [] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with missing items' do
      let(:actual) { %w[Who] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with invalid items' do
      let(:actual) { %w[ichi ni san] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with mixed invalid and valid items' do
      let(:actual) { ['Who', 'ni', 'I Don\'t Know'] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with valid items' do
      let(:actual) { ['Who', 'What', 'I Don\'t Know'] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Tuples::ExtraItems::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a tuple with extra items' do
      let(:actual) { ['Who', 'What', 'I Don\'t Know', 'Tomorrow', 'Today'] }
      let(:expected_errors) do
        [
          {
            data:    {
              methods: %i[[] each size],
              missing: []
            },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Types::Tuple::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [0],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [1],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    [2],
            type:    Stannum::Constraints::Base::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end
end
