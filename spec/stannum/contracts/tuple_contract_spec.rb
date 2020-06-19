# frozen_string_literal: true

require 'stannum/contracts/tuple_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'

RSpec.describe Stannum::Contracts::TupleContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractBuilderExamples

  shared_context 'when initialized with allow_extra_items: true' do
    before(:example) do
      options.update(allow_extra_items: true)
    end
  end

  shared_context 'with a block with many item constraints' do
    let(:block) do
      lambda do
        item { |value| value.is_a?(Integer) }
        item { |value| value.is_a?(String) }

        item do |value|
          value.is_a?(Spec::Manufacturer)
        end
      end
    end

    example_class 'Spec::Manufacturer'
  end

  subject(:constraint) { described_class.new(**options, &block) }

  let(:options) { {} }
  let(:block)   { -> {} }

  describe '::EXTRA_ITEM_TYPE' do
    include_examples 'should define frozen constant',
      :EXTRA_ITEM_TYPE,
      'stannum.constraints.tuple_extra_item'
  end

  describe '::MISSING_ITEM_TYPE' do
    include_examples 'should define frozen constant',
      :MISSING_ITEM_TYPE,
      'stannum.constraints.tuple_missing_item'
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_tuple'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_tuple'
  end

  describe '::Builder' do
    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      # rubocop:disable RSpec/DescribedClass
      Stannum::Contracts::TupleContract.new
      # rubocop:enable RSpec/DescribedClass
    end

    def resolve_constraint(constraint = nil, &block)
      builder.item(constraint, &block)

      contract
        .send(:constraints)
        .find { |hsh| hsh[:property] == index }
        .fetch(:constraint)
    end

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#contract' do
      include_examples 'should define reader',
        :contract,
        -> { contract }
    end

    describe '#item' do
      let(:index) { 0 }

      it 'should define the method' do
        expect(builder)
          .to respond_to(:item)
          .with(0..1).arguments
          .and_a_block
      end

      include_examples 'should resolve the constraint'

      context 'when the contract has many items' do
        let(:index) { 3 }

        before(:example) do
          builder.item { |value| value.is_a?(String) }
          builder.item { |value| value.is_a?(Integer) }
          builder.item { |value| value.is_a?(Array) }
        end

        include_examples 'should resolve the constraint'
      end
    end
  end

  describe '.new' do
    let(:builder) { instance_double(described_class::Builder, item: nil) }

    before(:example) do
      allow(described_class::Builder).to receive(:new).and_return(builder)
    end

    it { expect(described_class).to be_constructible.with(0).arguments }

    describe 'without a block' do
      it 'should not create an item constraint' do
        described_class.new

        expect(builder).not_to have_received(:item)
      end
    end

    describe 'with an empty block' do
      let(:block) { -> {} }

      it 'should not create an item constraint' do
        described_class.new {}

        expect(builder).not_to have_received(:item)
      end
    end

    wrap_context 'with a block with many item constraints' do
      it 'should create each item constraint' do
        described_class.new(&block)

        expect(builder).to have_received(:item).exactly(3).times
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#allow_extra_items?' do
    include_examples 'should have predicate', :allow_extra_items?, false

    wrap_context 'when initialized with allow_extra_items: true' do
      it { expect(constraint.allow_extra_items?).to be true }
    end
  end

  describe '#extra_item_type' do
    include_examples 'should have reader',
      :extra_item_type,
      'stannum.constraints.tuple_extra_item'
  end

  describe '#match' do
    let(:match_method) { :match }

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        { type: described_class::TYPE }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        { type: described_class::TYPE }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an empty Array' do
      let(:actual) { [] }

      include_examples 'should match the constraint'
    end

    describe 'with an Array with extra items' do
      let(:actual) { %i[ichi ni] }
      let(:expected_errors) do
        [
          {
            data: { value: actual[0] },
            path: [0],
            type: described_class::EXTRA_ITEM_TYPE
          },
          {
            data: { value: actual[1] },
            path: [1],
            type: described_class::EXTRA_ITEM_TYPE
          }
        ]
      end

      include_examples 'should not match the constraint'
    end

    wrap_context 'when initialized with allow_extra_items: true' do
      describe 'with an Array with extra items' do
        let(:actual) { %i[ichi ni] }

        include_examples 'should match the constraint'
      end
    end

    wrap_context 'with a block with many item constraints' do
      describe 'with an empty Array' do
        let(:actual) { [] }
        let(:expected_errors) do
          [
            {
              path: [0],
              type: described_class::MISSING_ITEM_TYPE
            },
            {
              path: [1],
              type: described_class::MISSING_ITEM_TYPE
            },
            {
              path: [2],
              type: described_class::MISSING_ITEM_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with missing items' do
        let(:actual) { [0] }
        let(:expected_errors) do
          [
            {
              path: [1],
              type: described_class::MISSING_ITEM_TYPE
            },
            {
              path: [2],
              type: described_class::MISSING_ITEM_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with non-matching items' do
        let(:actual) { ['invalid', 0, nil] }
        let(:expected_errors) do
          [
            {
              path: [0],
              type: Stannum::Constraints::Base::TYPE
            },
            {
              path: [1],
              type: Stannum::Constraints::Base::TYPE
            },
            {
              path: [2],
              type: Stannum::Constraints::Base::TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with partially matching items' do
        let(:actual) { [nil, 'valid', nil] }
        let(:expected_errors) do
          [
            {
              path: [0],
              type: Stannum::Constraints::Base::TYPE
            },
            {
              path: [2],
              type: Stannum::Constraints::Base::TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with matching items' do
        let(:actual) { [0, 'valid', Spec::Manufacturer.new] }

        include_examples 'should match the constraint'
      end

      describe 'with an Array with extra items' do
        let(:actual) { [0, 'valid', Spec::Manufacturer.new, :foo, :bar] }
        let(:expected_errors) do
          [
            {
              data: { value: :foo },
              path: [3],
              type: described_class::EXTRA_ITEM_TYPE
            },
            {
              data: { value: :bar },
              path: [4],
              type: described_class::EXTRA_ITEM_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        describe 'with an Array with extra items' do
          let(:actual) { [0, 'valid', Spec::Manufacturer.new, :foo, :bar] }

          include_examples 'should match the constraint'
        end
      end
    end
  end

  describe '#missing_item_type' do
    include_examples 'should have reader',
      :missing_item_type,
      'stannum.constraints.tuple_missing_item'
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an empty Array' do
      let(:actual) { [] }
      let(:expected_errors) do
        { type: described_class::NEGATED_TYPE }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Array with extra items' do
      let(:actual) { %i[ichi ni] }

      include_examples 'should match the constraint'
    end

    wrap_context 'when initialized with allow_extra_items: true' do
      describe 'with an Array with extra items' do
        let(:actual) { %i[ichi ni] }
        let(:expected_errors) do
          { type: described_class::NEGATED_TYPE }
        end

        include_examples 'should not match the constraint'
      end
    end

    wrap_context 'with a block with many item constraints' do
      describe 'with an empty Array' do
        let(:actual) { [] }

        include_examples 'should match the constraint'
      end

      describe 'with an Array with missing items' do
        let(:actual) { [0] }

        include_examples 'should match the constraint'
      end

      describe 'with an Array with non-matching items' do
        let(:actual) { ['invalid', 0, nil] }

        include_examples 'should match the constraint'
      end

      describe 'with an Array with partially matching items' do
        let(:actual) { [nil, 'valid', nil] }
        let(:expected_errors) do
          [
            {
              path: [1],
              type: Stannum::Constraints::Base::NEGATED_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with matching items' do
        let(:actual) { [0, 'valid', Spec::Manufacturer.new] }
        let(:expected_errors) do
          [
            {
              path: [0],
              type: Stannum::Constraints::Base::NEGATED_TYPE
            },
            {
              path: [1],
              type: Stannum::Constraints::Base::NEGATED_TYPE
            },
            {
              path: [2],
              type: Stannum::Constraints::Base::NEGATED_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an Array with extra items' do
        let(:actual) { [0, 'valid', Spec::Manufacturer.new, :foo, :bar] }

        include_examples 'should match the constraint'
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        describe 'with an Array with extra items' do
          let(:actual) { [0, 'valid', Spec::Manufacturer.new, :foo, :bar] }
          let(:expected_errors) do
            [
              {
                path: [0],
                type: Stannum::Constraints::Base::NEGATED_TYPE
              },
              {
                path: [1],
                type: Stannum::Constraints::Base::NEGATED_TYPE
              },
              {
                path: [2],
                type: Stannum::Constraints::Base::NEGATED_TYPE
              }
            ]
          end

          include_examples 'should not match the constraint'
        end
      end
    end
  end

  describe '#negated_type' do
    include_examples 'should have reader',
      :negated_type,
      'stannum.constraints.is_tuple'
  end

  describe '#options' do
    let(:expected) do
      { allow_extra_items: false }.merge(options)
    end

    include_examples 'should have reader', :options, -> { be == expected }

    wrap_context 'when initialized with allow_extra_items: true' do
      it { expect(constraint.allow_extra_items?).to be true }
    end
  end

  describe '#type' do
    include_examples 'should have reader',
      :type,
      'stannum.constraints.is_not_tuple'
  end
end
