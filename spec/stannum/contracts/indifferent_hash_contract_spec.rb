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

  describe '#each_constraint' do
    let(:expected_keys) { Set.new }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Type
            expect(definition.constraint.expected_type).to be Hash
            expect(definition.constraint.key_type)
              .to be_a Stannum::Constraints::Hashes::IndifferentKey
            expect(definition.constraint.value_type).to be nil
            expect(definition.sanity?).to be true
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Hashes::IndifferentExtraKeys
            expect(definition.constraint.expected_keys).to be == expected_keys
            expect(definition.concatenatable?).to be false
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

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.expected_type).to be Hash
              expect(definition.constraint.key_type)
                .to be_a Stannum::Constraints::Hashes::IndifferentKey
              expect(definition.constraint.value_type).to be nil
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

    context 'when initialized with key_type: value' do
      let(:constructor_options) { super().merge(key_type: String) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.expected_type).to be Hash
              expect(definition.constraint.key_type)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.key_type.expected_type)
                .to be String
              expect(definition.constraint.value_type).to be nil
              expect(definition.sanity?).to be true
            end
          ),
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Hashes::ExtraKeys
              expect(definition.constraint.expected_keys).to be == expected_keys
              expect(definition.sanity?).to be false
            end
          )
        ]
      end

      it { expect(contract.each_constraint.count).to be 2 }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#each_pair' do
    let(:actual) do
      {
        'name' => 'Self-sealing Stem Bolt',
        'mass' => 10,
        'size' => 'Tiny'
      }
    end
    let(:expected_keys) { Set.new }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Type
            expect(definition.constraint.expected_type).to be Hash
            expect(definition.constraint.key_type)
              .to be_a Stannum::Constraints::Hashes::IndifferentKey
            expect(definition.constraint.value_type).to be nil
            expect(definition.sanity?).to be true
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Hashes::IndifferentExtraKeys
            expect(definition.constraint.expected_keys).to be == expected_keys
            expect(definition.concatenatable?).to be false
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

    it { expect(contract.each_pair(actual).count).to be 2 }

    it 'should yield each definition and the mapped property' do
      expect { |block| contract.each_pair(actual, &block) }
        .to yield_successive_args(*expected)
    end

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.expected_type).to be Hash
              expect(definition.sanity?).to be true
            end
          )
        ]
      end

      it { expect(contract.each_pair(actual).count).to be 1 }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end

    context 'when initialized with key_type: value' do
      let(:constructor_options) { super().merge(key_type: String) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.expected_type).to be Hash
              expect(definition.constraint.key_type)
                .to be_a Stannum::Constraints::Type
              expect(definition.constraint.key_type.expected_type)
                .to be String
              expect(definition.constraint.value_type).to be nil
              expect(definition.sanity?).to be true
            end
          ),
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Hashes::IndifferentExtraKeys
              expect(definition.constraint.expected_keys).to be == expected_keys
              expect(definition.sanity?).to be false
            end
          )
        ]
      end

      it { expect(contract.each_pair(actual).count).to be 2 }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
  end

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
