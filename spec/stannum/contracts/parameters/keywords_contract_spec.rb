# frozen_string_literal: true

require 'stannum/contracts/parameters/keywords_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::Parameters::KeywordsContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has many keyword constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: 'name' }
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: 'size' }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { property: 'mass' }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { property_type: :key, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end
    let(:expected_keys) do
      Set.new(constraints.map { |hsh| hsh[:options][:property] })
    end
    let(:constructor_block) do
      constraint_definitions = constraints

      lambda do
        constraint_definitions.each do |definition|
          options  = definition.fetch(:options).dup
          property = options.delete(:property)

          key(property, definition[:constraint], **options)
        end
      end
    end
  end

  shared_context 'when the contract has a variadic keywords constraint' do
    let(:receiver) do
      Stannum::Constraints::Types::Hash.new(value_type: String)
    end
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Types::Hash).and(
        satisfy do |constraint|
          constraint.value_type.is_a?(Stannum::Constraints::Type) &&
            constraint.value_type.expected_type == String
        end
      )
    end

    before(:example) { contract.set_variadic_constraint(receiver) }
  end

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_options) { {} }
  let(:constructor_block)   { -> {} }
  let(:expected_options) do
    {
      allow_extra_keys: false,
      allow_hash_like:  false,
      key_type:         an_instance_of(
        Stannum::Constraints::Hashes::IndifferentKey
      )
    }
  end

  describe '::EXTRA_KEYWORDS_TYPE' do
    include_examples 'should define immutable constant',
      :EXTRA_KEYWORDS_TYPE,
      'stannum.constraints.parameters.extra_keywords'
  end

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

  describe '#allow_extra_keys?' do
    include_examples 'should have predicate', :allow_extra_keys?, false

    wrap_context 'when the contract has a variadic keywords constraint' do
      it { expect(contract.allow_extra_keys?).to be true }
    end
  end

  describe '#each_constraint' do
    let(:expected_keys) { Set.new }
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Hashes::ExtraKeys).and(
        satisfy { |constraint| constraint.expected_keys == expected_keys }
      )
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
          constraint: be_a_constraint(Stannum::Constraints::Types::Hash)
                      .with_options(
                        allow_empty:   true,
                        expected_type: Hash,
                        key_type:      nil,
                        required:      true,
                        value_type:    nil
                      ),
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

    wrap_context 'when the contract has many keyword constraints' do
      let(:items_count) { definitions.count }
      let(:expected)    { builtin_definitions + definitions }

      it { expect(contract.each_constraint.count).to be(2 + constraints.size) }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has a variadic keywords constraint' do
        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has a variadic keywords constraint' do
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
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Hashes::ExtraKeys).and(
        satisfy { |constraint| constraint.expected_keys == expected_keys }
      )
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
          constraint: be_a_constraint(Stannum::Constraints::Type)
                      .with_options(
                        allow_empty:   true,
                        expected_type: Hash,
                        key_type:      nil,
                        required:      true,
                        value_type:    nil
                      ),
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

    it { expect(contract.each_pair(actual).count).to be 2 }

    it 'should yield each definition and the mapped property' do
      expect { |block| contract.each_pair(actual, &block) }
        .to yield_successive_args(*expected)
    end

    wrap_context 'when the contract has many keyword constraints' do
      let(:values) do
        definitions.map do |definition|
          contract.send(:map_value, actual, **definition.options)
        end
      end
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(values)
      end

      it { expect(contract.each_pair(actual).count).to be(expected.size) }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has a variadic keywords constraint' do
        it 'should yield each definition' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    wrap_context 'when the contract has a variadic keywords constraint' do
      it 'should yield each definition' do
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
        'receiver must be a Stannum::Constraints::Base'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'receiver must be a Stannum::Constraints::Base'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_constraint Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a class' do
      let(:error_message) do
        'receiver must be a Stannum::Constraints::Base'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_constraint String }
          .to raise_error ArgumentError, error_message
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

    wrap_context 'when the contract has a variadic keywords constraint' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'variadic keywords constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_variadic_constraint constraint }
          .to raise_error RuntimeError, error_message
      end
    end
  end

  describe '#set_variadic_value_constraint' do
    let(:definition) { contract.send(:variadic_definition) }
    let(:receiver)   { contract.send(:variadic_constraint).receiver }

    it 'should define the method' do
      expect(contract)
        .to respond_to(:set_variadic_value_constraint)
        .with(1).argument
        .and_keywords(:as)
    end

    it 'should return the contract' do
      expect(contract.set_variadic_value_constraint Stannum::Constraint.new)
        .to be contract
    end

    describe 'with nil' do
      let(:error_message) do
        'value type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_value_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'value type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_value_constraint Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a class' do
      let(:type) { String }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_value_constraint(type)

        expect(receiver).to be_a Stannum::Constraints::Types::Hash
        expect(receiver.key_type).to be_a Stannum::Constraints::Types::Symbol
        expect(receiver.value_type).to be_a Stannum::Constraints::Type
        expect(receiver.value_type.expected_type).to be type
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_value_constraint(type)

          expect(receiver).to be_a Stannum::Constraints::Types::Hash
          expect(receiver.key_type).to be_a Stannum::Constraints::Types::Symbol
          expect(receiver.value_type).to be_a Stannum::Constraints::Type
          expect(receiver.value_type.expected_type).to be type
        end

        it 'should update the property name' do
          expect { contract.set_variadic_value_constraint(type, as: :kwargs) }
            .to change(definition, :property_name)
            .to be :kwargs
        end
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraint.new(type: 'spec.type') }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_value_constraint(constraint)

        expect(receiver).to be_a Stannum::Constraints::Types::Hash
        expect(receiver.key_type).to be_a Stannum::Constraints::Types::Symbol
        expect(receiver.value_type).to be_a Stannum::Constraint
        expect(receiver.value_type.options).to be == constraint.options
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_value_constraint(constraint, as: :kwargs)

          expect(receiver).to be_a Stannum::Constraints::Types::Hash
          expect(receiver.key_type).to be_a Stannum::Constraints::Types::Symbol
          expect(receiver.value_type).to be_a Stannum::Constraint
          expect(receiver.value_type.options).to be == constraint.options
        end

        it 'should update the property name' do
          expect do
            contract.set_variadic_value_constraint(constraint, as: :kwargs)
          end
            .to change(definition, :property_name)
            .to be :kwargs
        end
      end
    end

    wrap_context 'when the contract has a variadic keywords constraint' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'variadic keywords constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_variadic_value_constraint constraint }
          .to raise_error RuntimeError, error_message
      end
    end
  end
end
