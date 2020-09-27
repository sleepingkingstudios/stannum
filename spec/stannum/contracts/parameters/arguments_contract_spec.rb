# frozen_string_literal: true

require 'stannum/contracts/parameters/arguments_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::Parameters::ArgumentsContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has many argument constraints' do
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
        be_a_constraint_definition(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { property: index, property_type: :index, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end

    before(:example) do
      constraints.each.with_index do |definition, index|
        contract.add_index_constraint(
          index,
          definition[:constraint],
          **definition.fetch(:options, {})
        )
      end
    end
  end

  shared_context 'when the contract has a variadic arguments constraint' do
    let(:receiver) do
      Stannum::Constraints::Types::Array.new(item_type: String)
    end
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Types::Array).and(
        satisfy do |constraint|
          constraint.item_type.is_a?(Stannum::Constraints::Type) &&
            constraint.item_type.expected_type == String
        end
      )
    end

    before(:example) { contract.set_variadic_constraint(receiver) }
  end

  subject(:contract) do
    described_class.new(**constructor_options)
  end

  let(:constructor_options) { {} }
  let(:expected_options)    { { allow_extra_items: false } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#allow_extra_items?' do
    include_examples 'should have predicate', :allow_extra_items?, false

    wrap_context 'when the contract has a variadic arguments constraint' do
      it { expect(contract.allow_extra_items?).to be true }
    end
  end

  describe '#each_constraint' do
    let(:items_count) { 0 }
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Tuples::ExtraItems)
        .and(satisfy { |constraint| constraint.expected_count == items_count })
    end
    let(:delegator_definition) do
      be_a_constraint(Stannum::Constraints::Delegator).and(
        satisfy do |constraint|
          receiver_definition.matches?(constraint.receiver)
        end
      )
    end
    let(:builtin_definitions) do
      [
        be_a_constraint_definition(
          constraint: be_a_constraint(Stannum::Constraints::Types::Tuple),
          contract:   contract,
          options:    { property: nil, sanity: true }
        ),
        be_a_constraint_definition(
          constraint: delegator_definition,
          contract:   contract,
          options:    { property: nil, sanity: false }
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

    wrap_context 'when the contract has many argument constraints' do
      let(:items_count) { definitions.count }
      let(:expected)    { builtin_definitions + definitions }

      it { expect(contract.each_constraint.count).to be(2 + constraints.size) }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has a variadic arguments constraint' do
        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#each_pair' do
    let(:actual)      { %w[ichi ni san] }
    let(:items_count) { 0 }
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Tuples::ExtraItems)
        .and(satisfy { |constraint| constraint.expected_count == items_count })
    end
    let(:delegator_definition) do
      be_a_constraint(Stannum::Constraints::Delegator).and(
        satisfy do |constraint|
          receiver_definition.matches?(constraint.receiver)
        end
      )
    end
    let(:builtin_definitions) do
      [
        be_a_constraint_definition(
          constraint: be_a_constraint(Stannum::Constraints::Types::Tuple),
          contract:   contract,
          options:    { property: nil, sanity: true }
        ),
        be_a_constraint_definition(
          constraint: delegator_definition,
          contract:   contract,
          options:    { property: nil, sanity: false }
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

    wrap_context 'when the contract has many argument constraints' do
      let(:items_count) { definitions.count }
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(actual)
      end

      it { expect(contract.each_pair(actual).count).to be(expected.size) }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has a variadic arguments constraint' do
        it 'should yield each definition and the mapped property' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#set_variadic_constraint' do
    let(:definition) { contract.each_constraint.to_a.last }
    let(:receiver)   { contract.send(:variadic_constraint).receiver }

    it 'should define the method' do
      expect(contract).to respond_to(:set_variadic_constraint).with(1).argument
    end

    it 'should return the contract' do
      expect(contract.set_variadic_constraint Stannum::Constraint.new)
        .to be contract
    end

    describe 'with nil' do
      let(:error_message) do
        'item type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'item type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_constraint Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a class' do
      let(:type) { String }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_constraint(type)

        expect(receiver).to be_a Stannum::Constraints::Types::Array
        expect(receiver.item_type).to be_a Stannum::Constraints::Type
        expect(receiver.item_type.expected_type).to be type
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraint.new(type: 'spec.type') }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_constraint(constraint)

        expect(receiver).to be_a Stannum::Constraint
        expect(receiver.options).to be == constraint.options
      end
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'variadic arguments constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_variadic_constraint constraint }
          .to raise_error RuntimeError, error_message
      end
    end
  end
end
