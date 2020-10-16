# frozen_string_literal: true

require 'stannum/contracts/indifferent_hash_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::IndifferentHashContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_block)   { -> {} }
  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_extra_keys: false,
      allow_hash_like:  false,
      key_type:         be_a_constraint(
        Stannum::Constraints::Hashes::IndifferentKey
      )
    }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:allow_extra_keys, :allow_hash_like)
        .and_any_keywords
        .and_a_block
    end

    describe 'with a block' do
      let(:builder) { instance_double(described_class::Builder, key: nil) }

      before(:example) do
        allow(described_class::Builder).to receive(:new).and_return(builder)
      end

      it 'should call the builder with the block', :aggregate_failures do
        described_class.new do
          key :name, option: 'one'
          key :size, option: 'two'
          key :mass, option: 'three'
        end

        expect(builder).to have_received(:key).with(:name, option: 'one')
        expect(builder).to have_received(:key).with(:size, option: 'two')
        expect(builder).to have_received(:key).with(:mass, option: 'three')
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#add_constraint' do
    describe 'with an invalid key' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'invalid property name nil' }

      it 'should raise an error' do
        expect do
          contract.add_constraint(
            constraint,
            property:      nil,
            property_type: :key
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a string key constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint(
            constraint,
            property:      'name',
            property_type: :key
          )
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(
            constraint,
            property:      'name',
            property_type: :key
          )
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_constraint(
          constraint,
          property:      'name',
          property_type: :key
        )

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      'name',
            property_type: :key,
            sanity:        false
          }
        )
      end
    end

    describe 'with a symbol key constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint(
            constraint,
            property:      :name,
            property_type: :key
          )
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(
            constraint,
            property:      :name,
            property_type: :key
          )
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_constraint(
          constraint,
          property:      :name,
          property_type: :key
        )

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      :name,
            property_type: :key,
            sanity:        false
          }
        )
      end
    end
  end

  describe '#map_value' do
    let(:value) { { name: 'Self-sealing Stem Bolt' } }

    it { expect(contract.send :map_value, value).to be value }

    describe 'with property: a String and property_type: :key' do
      let(:key) { 'name' }

      describe 'with a hash with String keys' do
        let(:value) { { 'name' => 'Self-sealing Stem Bolt' } }

        it 'should return the indexed value' do
          expect(
            contract.send(
              :map_value,
              value,
              property:      key,
              property_type: :key
            )
          )
            .to be == value[key]
        end
      end

      describe 'with a hash with Symbol keys' do
        it 'should return the indexed value' do
          expect(
            contract.send(
              :map_value,
              value,
              property:      key,
              property_type: :key
            )
          )
            .to be == value[key.intern]
        end
      end
    end

    describe 'with property: a Symbol and property_type: :key' do
      let(:key) { :name }

      describe 'with a hash with String keys' do
        let(:value) { { 'name' => 'Self-sealing Stem Bolt' } }

        it 'should return the indexed value' do
          expect(
            contract.send(
              :map_value,
              value,
              property:      key,
              property_type: :key
            )
          )
            .to be == value[key.to_s]
        end
      end

      describe 'with a hash with Symbol keys' do
        it 'should return the indexed value' do
          expect(
            contract.send(
              :map_value,
              value,
              property:      key,
              property_type: :key
            )
          )
            .to be == value[key]
        end
      end
    end
  end

  describe '#options' do
    let(:expected) do
      {
        allow_extra_keys: false,
        allow_hash_like:  false,
        key_type:         an_instance_of(
          Stannum::Constraints::Hashes::IndifferentKey
        )
      }
    end

    include_examples 'should have reader', :options, -> { deep_match expected }

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }
      let(:expected)            { super().merge(allow_extra_keys: true) }

      it { expect(contract.options).to deep_match expected }
    end

    context 'when initialized with allow_hash_like: true' do
      let(:constructor_options) { super().merge(allow_hash_like: true) }
      let(:expected)            { super().merge(allow_hash_like: true) }

      it { expect(contract.options).to deep_match expected }
    end
  end
end
