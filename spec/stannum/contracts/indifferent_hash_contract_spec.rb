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
      key_type:         be_a_constraint(
        Stannum::Constraints::Hashes::IndifferentKey
      ),
      value_type:       nil
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

  describe '#key_type' do
    include_examples 'should define reader',
      :key_type,
      -> { be_a_constraint(Stannum::Constraints::Hashes::IndifferentKey) }
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
        key_type:         an_instance_of(
          Stannum::Constraints::Hashes::IndifferentKey
        ),
        value_type:       nil
      }
    end

    include_examples 'should have reader', :options, -> { deep_match expected }

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }
      let(:expected)            { super().merge(allow_extra_keys: true) }

      it { expect(contract.options).to deep_match expected }
    end

    context 'when initialized with value_type: value' do
      let(:constructor_options) { super().merge(value_type: String) }
      let(:expected)            { super().merge(value_type: String) }

      it { expect(contract.options).to deep_match expected }
    end
  end
end
