# frozen_string_literal: true

require 'stannum/contracts/tuple_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::TupleContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when initialized with allow_extra_items: true' do
    let(:constructor_options) { { allow_extra_items: true } }
  end

  shared_context 'when the contract has one item constraint' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new
        }
      ]
    end
    let(:definitions) do
      constraints.map.with_index do |definition, index|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { property: index, property_type: :index, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end
    let(:items_count) { constraints.count }
    let(:constructor_block) do
      constraint_definitions = constraints

      lambda do
        constraint_definitions.each do |definition|
          item(definition[:constraint], **definition.fetch(:options, {}))
        end
      end
    end
  end

  shared_context 'when the contract has many item constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { type: :index, key: 'value' }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { type: :index, ichi: 1, ni: 2, san: 3 }
        }
      ]
    end
    let(:definitions) do
      constraints.map.with_index do |definition, index|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { property: index, property_type: :index, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end
    let(:items_count) { constraints.count }
    let(:constructor_block) do
      constraint_definitions = constraints

      lambda do
        constraint_definitions.each do |definition|
          item(definition[:constraint], **definition.fetch(:options, {}))
        end
      end
    end
  end

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_block)   { -> {} }
  let(:constructor_options) { {} }
  let(:expected_options)    { { allow_extra_items: false } }

  describe '::Builder' do
    include Spec::Support::Examples::ContractBuilderExamples

    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      Stannum::Contracts::TupleContract.new # rubocop:disable RSpec/DescribedClass
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
      let(:custom_options) do
        { property: index, property_type: :index }
      end

      def define_from_block(**options, &block)
        builder.item(**options, &block)
      end

      def define_from_constraint(constraint, **options)
        builder.item(constraint, **options)
      end

      it 'should define the method' do
        expect(builder)
          .to respond_to(:item)
          .with(0..1).arguments
          .and_any_keywords
          .and_a_block
      end

      include_examples 'should delegate to #constraint'

      context 'when the contract has one item constraint' do
        let(:index) { 1 }

        before(:example) { builder.item }

        include_examples 'should delegate to #constraint'
      end

      context 'when the contract has many item constraints' do
        let(:index) { 3 }

        before(:example) { 3.times { builder.item } }

        include_examples 'should delegate to #constraint'
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:allow_extra_items)
        .and_any_keywords
        .and_a_block
    end

    describe 'with a block' do
      let(:builder) { instance_double(described_class::Builder, item: nil) }

      before(:example) do
        allow(described_class::Builder).to receive(:new).and_return(builder)
      end

      it 'should call the builder with the block', :aggregate_failures do
        described_class.new do
          item option: 'one'
          item option: 'two'
          item option: 'three'
        end

        expect(builder).to have_received(:item).with(option: 'one')
        expect(builder).to have_received(:item).with(option: 'two')
        expect(builder).to have_received(:item).with(option: 'three')
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#add_constraint' do
    describe 'with an invalid item index' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { 'foo' }
      let(:error_message) do
        "invalid property name #{property.inspect}"
      end

      it 'should raise an error' do
        expect do
          contract.add_constraint(
            constraint,
            property:      property,
            property_type: :index
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an item constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint(
            constraint,
            property:      0,
            property_type: :index
          )
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(
            constraint,
            property:      0,
            property_type: :index
          )
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_constraint(
          constraint,
          property:      0,
          property_type: :index
        )

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with an item constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint(
            constraint,
            property:      0,
            property_type: :index,
            **options
          )
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(
            constraint,
            property:      0,
            property_type: :index,
            **options
          )
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and options' do # rubocop:disable RSpec/ExampleLength
        contract.add_constraint(
          constraint,
          property:      0,
          property_type: :index,
          **options
        )

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      0,
            property_type: :index,
            sanity:        false,
            **options
          }
        )
      end
    end
  end

  describe '#add_index_constraint' do
    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_index_constraint)
        .with(2).arguments
        .and_keywords(:sanity)
        .and_any_keywords
    end

    describe 'with an invalid item index' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { 'foo' }
      let(:error_message) do
        "invalid property name #{property.inspect}"
      end

      it 'should raise an error' do
        expect { contract.add_index_constraint(property, constraint) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an item constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_index_constraint(0, constraint))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_index_constraint(0, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do
        contract.add_index_constraint(0, constraint)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with an item constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_index_constraint(0, constraint, **options))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_index_constraint(0, constraint, **options) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and options' do # rubocop:disable RSpec/ExampleLength
        contract.add_index_constraint(0, constraint, **options)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      0,
            property_type: :index,
            sanity:        false,
            **options
          }
        )
      end
    end
  end

  describe '#allow_extra_items?' do
    include_examples 'should have predicate', :allow_extra_items?, false

    wrap_context 'when initialized with allow_extra_items: true' do
      it { expect(contract.allow_extra_items?).to be true }
    end
  end

  describe '#each_constraint' do
    let(:items_count) { 0 }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Signatures::Tuple
            expect(definition.sanity?).to be true
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Tuples::ExtraItems
            expect(definition.constraint.expected_count).to be == items_count
            expect(definition.sanity?).to be false
          end
        )
      ]
    end
    let(:expected) { builtin_definitions }

    it { expect(contract).to respond_to(:each_constraint).with(0).arguments }

    it { expect(contract.each_constraint).to be_a Enumerator }

    it { expect(contract.each_constraint.count).to be 2 }

    it 'should yield each definition' do
      expect { |block| contract.each_constraint(&block) }
        .to yield_successive_args(*expected)
    end

    wrap_context 'when initialized with allow_extra_items: true' do
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Tuple
              expect(definition.sanity?).to be true
            end
          )
        ]
      end

      it { expect(contract.each_constraint.count).to be 1 }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the contract has one item constraint' do
      let(:expected) { builtin_definitions + definitions }

      it { expect(contract.each_constraint.count).to be(2 + constraints.size) }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        let(:builtin_definitions) do
          [
            an_instance_of(Stannum::Contracts::Definition).and(
              satisfy do |definition|
                expect(definition.constraint)
                  .to be_a Stannum::Constraints::Signatures::Tuple
                expect(definition.sanity?).to be true
              end
            )
          ]
        end

        it { expect(contract.each_constraint.count).to be 1 + constraints.size }

        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has many item constraints' do
      let(:expected) { builtin_definitions + definitions }

      it { expect(contract.each_constraint.count).to be(2 + constraints.size) }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        let(:builtin_definitions) do
          [
            an_instance_of(Stannum::Contracts::Definition).and(
              satisfy do |definition|
                expect(definition.constraint)
                  .to be_a Stannum::Constraints::Signatures::Tuple
                expect(definition.sanity?).to be true
              end
            )
          ]
        end

        it { expect(contract.each_constraint.count).to be 1 + constraints.size }

        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#each_pair' do
    let(:actual)      { %w[ichi ni san] }
    let(:items_count) { 0 }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Signatures::Tuple
            expect(definition.sanity?).to be true
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Tuples::ExtraItems
            expect(definition.constraint.expected_count).to be == items_count
            expect(definition.sanity?).to be false
          end
        )
      ]
    end
    let(:expected) do
      builtin_definitions.zip(Array.new(builtin_definitions.size, actual))
    end

    it { expect(contract).to respond_to(:each_pair).with(1).argument }

    it { expect(contract.each_pair(actual)).to be_a Enumerator }

    it { expect(contract.each_pair(actual).count).to be 2 + items_count }

    it 'should yield each definition and the mapped property' do
      expect { |block| contract.each_pair(actual, &block) }
        .to yield_successive_args(*expected)
    end

    wrap_context 'when initialized with allow_extra_items: true' do
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Tuple
              expect(definition.sanity?).to be true
            end
          )
        ]
      end

      it { expect(contract.each_pair(actual).count).to be 1 + items_count }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the contract has one item constraint' do
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(actual)
      end

      it 'should have the expected size' do
        expect(contract.each_pair(actual).count).to be(2 + constraints.size)
      end

      it 'should yield each definition' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        let(:builtin_definitions) do
          [
            an_instance_of(Stannum::Contracts::Definition).and(
              satisfy do |definition|
                expect(definition.constraint)
                  .to be_a Stannum::Constraints::Signatures::Tuple
                expect(definition.sanity?).to be true
              end
            )
          ]
        end

        it { expect(contract.each_pair(actual).count).to be 1 + items_count }

        it 'should yield each definition and the mapped property' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has many item constraints' do
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(actual)
      end

      it 'should have the expected size' do
        expect(contract.each_pair(actual).count).to be(2 + constraints.size)
      end

      it 'should yield each definition' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when initialized with allow_extra_items: true' do
        let(:builtin_definitions) do
          [
            an_instance_of(Stannum::Contracts::Definition).and(
              satisfy do |definition|
                expect(definition.constraint)
                  .to be_a Stannum::Constraints::Signatures::Tuple
                expect(definition.sanity?).to be true
              end
            )
          ]
        end

        it { expect(contract.each_pair(actual).count).to be 1 + items_count }

        it 'should yield each definition and the mapped property' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#map_errors' do
    let(:errors) { Stannum::Errors.new }

    it { expect(contract.send :map_errors, errors).to be errors }

    describe 'with property_type: :index' do
      let(:index) { 1 }

      before(:example) do
        errors[index].add('spec.indexed_error')
      end

      it 'should return the errors for the index' do
        expect(
          contract.send(
            :map_errors,
            errors,
            property:      index,
            property_type: :index
          )
        )
          .to be == errors[index]
      end
    end
  end

  describe '#map_value' do
    let(:value) { %w[ichi ni san] }

    it { expect(contract.send :map_value, value).to be value }

    describe 'with property_type: :index' do
      let(:index) { 1 }

      it 'should return the indexed value' do
        expect(
          contract.send(
            :map_value,
            value,
            property:      index,
            property_type: :index
          )
        )
          .to be == value[index]
      end
    end
  end

  describe '#options' do
    include_examples 'should have reader',
      :options,
      -> { be == { allow_extra_items: false } }

    wrap_context 'when initialized with allow_extra_items: true' do
      it { expect(contract.options).to be == { allow_extra_items: true } }
    end
  end

  describe '#valid_property?' do
    it 'should define the private method' do
      expect(contract)
        .to respond_to(:valid_property?, true)
        .with(0).arguments
        .and_any_keywords
    end

    describe 'with no keywords' do
      it { expect(contract.send :valid_property?).to be false }
    end

    describe 'with property: nil' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: nil).to be false
      end
    end

    describe 'with property: an Object' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: Object.new.freeze)
          .to be false
      end
    end

    describe 'with property: an Integer' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: 0)
          .to be false
      end
    end

    describe 'with property: an empty String' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: '').to be false
      end
    end

    describe 'with property: a String' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: 'foo').to be true
      end
    end

    describe 'with property: an empty Symbol' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: :'').to be false
      end
    end

    describe 'with property: a Symbol' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: :foo).to be true
      end
    end

    describe 'with property: an empty Array' do
      it 'should return false' do
        expect(contract.send :valid_property?, property: []).to be false
      end
    end

    describe 'with property: an Array with an invalid object' do
      it 'should return false' do
        expect(contract.send :valid_property?, property: [nil]).to be false
      end
    end

    describe 'with property: an Array with an invalid String' do
      it 'should return false' do
        expect(contract.send :valid_property?, property: ['']).to be false
      end
    end

    describe 'with property: an Array with an valid Strings' do
      it 'should return true' do
        expect(contract.send :valid_property?, property: %w[foo bar baz])
          .to be true
      end
    end

    describe 'with property: an Array with an invalid Symbol' do
      it 'should return false' do
        expect(contract.send :valid_property?, property: [:'']).to be false
      end
    end

    describe 'with property_type: :index and property: nil' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      nil,
            property_type: :index
          )
        ).to be false
      end
    end

    describe 'with property_type: :index and property: an Object' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      Object.new.freeze,
            property_type: :index
          )
        ).to be false
      end
    end

    describe 'with property_type: :index and property: an Array' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      %w[foo bar baz],
            property_type: :index
          )
        ).to be false
      end
    end

    describe 'with property_type: :index and property: an Integer' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      -1,
            property_type: :index
          )
        ).to be true
      end
    end

    describe 'with property_type: :index and property: a String' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      'foo',
            property_type: :index
          )
        ).to be false
      end
    end

    describe 'with property_type: :index and property: a Symbol' do
      it 'should return false' do
        expect(
          contract.send(
            :valid_property?,
            property:      :foo,
            property_type: :index
          )
        ).to be false
      end
    end
  end

  describe '#validate_property?' do
    it 'should define the private method' do
      expect(contract)
        .to respond_to(:validate_property?, true)
        .with(0).arguments
        .and_any_keywords
    end

    describe 'with no keywords' do
      it { expect(contract.send :validate_property?).to be false }
    end

    describe 'with property: nil' do
      it 'should return true' do
        expect(contract.send :validate_property?, property: nil).to be false
      end
    end

    describe 'with property: an Object' do
      it 'should return true' do
        expect(contract.send :validate_property?, property: Object.new.freeze)
          .to be true
      end
    end

    describe 'with property: nil and property_type: :index' do
      it 'should return true' do
        expect(
          contract.send(
            :validate_property?,
            property:      nil,
            property_type: :index
          )
        ).to be true
      end
    end
  end

  describe '#with_options' do
    describe 'with allow_extra_items: value' do
      let(:error_message) { "can't change option :allow_extra_items" }

      it 'should raise an exception' do
        expect { contract.with_options(allow_extra_items: true) }
          .to raise_error ArgumentError, error_message
      end
    end
  end
end
