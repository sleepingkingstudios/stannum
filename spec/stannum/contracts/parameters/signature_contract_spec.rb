# frozen_string_literal: true

require 'stannum/contracts/parameters/signature_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::Parameters::SignatureContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  subject(:contract) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Contract methods'

  describe '#each_constraint' do
    let(:expected_keys) { Set.new(%i[arguments keywords block]) }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Type
            expect(definition.constraint.expected_type).to be Hash
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
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Array
            expect(definition.constraint.optional?).to be false
            expect(definition.property).to be :arguments
            expect(definition.sanity?).to be false
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Hash
            expect(definition.constraint.key_type)
              .to be_a Stannum::Constraints::Types::Symbol
            expect(definition.constraint.optional?).to be false
            expect(definition.property).to be :keywords
            expect(definition.sanity?).to be false
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Proc
            expect(definition.constraint.optional?).to be true
            expect(definition.property).to be :block
            expect(definition.sanity?).to be false
          end
        )
      ]
    end
    let(:expected) { builtin_definitions }

    it { expect(contract).to respond_to(:each_constraint).with(0).arguments }

    it { expect(contract.each_constraint).to be_a Enumerator }

    it { expect(contract.each_constraint.count).to be 5 }

    it 'should yield each definition' do
      expect { |block| contract.each_constraint(&block) }
        .to yield_successive_args(*expected)
    end
  end

  describe '#each_pair' do
    let(:actual) do
      {
        arguments: %i[ichi ni san],
        keywords:  { key: 'value' },
        block:     -> {}
      }
    end
    let(:expected_keys) { Set.new(%i[arguments keywords block]) }
    let(:builtin_definitions) do
      [
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Type
            expect(definition.constraint.expected_type).to be Hash
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
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Array
            expect(definition.constraint.optional?).to be false
            expect(definition.property).to be :arguments
            expect(definition.sanity?).to be false
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Hash
            expect(definition.constraint.key_type)
              .to be_a Stannum::Constraints::Types::Symbol
            expect(definition.constraint.optional?).to be false
            expect(definition.property).to be :keywords
            expect(definition.sanity?).to be false
          end
        ),
        an_instance_of(Stannum::Contracts::Definition).and(
          satisfy do |definition|
            expect(definition.constraint)
              .to be_a Stannum::Constraints::Types::Proc
            expect(definition.constraint.optional?).to be true
            expect(definition.property).to be :block
            expect(definition.sanity?).to be false
          end
        )
      ]
    end
    let(:mapped_values) do
      [
        actual,
        actual,
        actual[:arguments],
        actual[:keywords],
        actual[:block]
      ]
    end
    let(:expected) { builtin_definitions.zip(mapped_values) }

    it { expect(contract).to respond_to(:each_pair).with(1).argument }

    it { expect(contract.each_pair(actual)).to be_a Enumerator }

    it { expect(contract.each_pair(actual).count).to be 5 }

    it 'should yield each definition and the mapped property' do
      expect { |block| contract.each_pair(actual, &block) }
        .to yield_successive_args(*expected)
    end
  end

  describe '#options' do
    let(:expected) do
      {
        allow_extra_keys: false,
        allow_hash_like:  false
      }
    end

    it 'should return the options' do
      expect(contract.options).to match expected.merge(
        key_type: an_instance_of(Stannum::Constraints::Type)
      )
    end

    it 'should return the key type' do
      expect(contract.options[:key_type].expected_type).to be Symbol
    end
  end
end
