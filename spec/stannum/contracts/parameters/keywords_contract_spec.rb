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
          options:    { property: :name }
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: :size }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { property: :mass }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        options = definition.fetch(:options, {})

        be_a_constraint_definition(
          constraint: definition[:constraint],
          contract:   contract,
          options:    {
            default:       false,
            property_type: :key,
            sanity:        false
          }
            .merge(options)
        )
      end
    end
    let(:expected_keys) do
      Set.new(constraints.map { |hsh| hsh[:options][:property].intern })
    end

    before(:example) do
      constraints.each do |definition|
        options  = definition.fetch(:options).dup
        property = options.delete(:property)

        contract.add_keyword_constraint(
          property.intern,
          definition[:constraint],
          **options
        )
      end
    end
  end

  shared_context 'when the contract has keyword constraints with defaults' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: :name }
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: :size, default: true }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { property: :mass, default: true }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        options = definition.fetch(:options, {})

        be_a_constraint_definition(
          constraint: definition[:constraint],
          contract:   contract,
          options:    {
            default:       false,
            property_type: :key,
            sanity:        false
          }
            .merge(options)
        )
      end
    end
    let(:expected_keys) do
      Set.new(constraints.map { |hsh| hsh[:options][:property].intern })
    end

    before(:example) do
      constraints.each do |definition|
        options  = definition.fetch(:options).dup
        property = options.delete(:property)

        contract.add_keyword_constraint(
          property.intern,
          definition[:constraint],
          **options
        )
      end
    end
  end

  shared_context 'when the contract has a variadic keywords constraint' do
    let(:receiver) do
      Stannum::Constraints::Types::HashType.new(value_type: String)
    end
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Types::HashType).and(
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
      key_type:         an_instance_of(
        Stannum::Constraints::Hashes::IndifferentKey
      ),
      value_type:       nil
    }
  end

  describe '::EXTRA_KEYWORDS_TYPE' do
    include_examples 'should define immutable constant',
      :EXTRA_KEYWORDS_TYPE,
      'stannum.constraints.parameters.extra_keywords'
  end

  describe '::UNDEFINED' do
    include_examples 'should define immutable constant', :UNDEFINED
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

  describe '#add_errors_for' do
    describe 'with value: UNDEFINED' do
      let(:value)      { described_class::UNDEFINED }
      let(:errors)     { Stannum::Errors.new }
      let(:options)    { {} }
      let(:constraint) { Stannum::Constraints::Presence.new }
      let(:definition) do
        Stannum::Contracts::Definition.new(
          constraint: constraint,
          contract:   contract,
          options:    options
        )
      end

      it 'should add the errors from the constraint' do
        expect(contract.send(:add_errors_for, definition, value, errors))
          .to be == constraint.errors_for(nil)
      end

      it 'should delegate to the constraint with value: nil' do
        allow(constraint).to receive(:update_errors_for)

        contract.send(:add_errors_for, definition, value, errors)

        expect(constraint)
          .to have_received(:update_errors_for)
          .with(actual: nil, errors: errors)
      end
    end
  end

  describe '#add_negated_errors_for' do
    describe 'with value: UNDEFINED' do
      let(:value)      { described_class::UNDEFINED }
      let(:errors)     { Stannum::Errors.new }
      let(:options)    { {} }
      let(:constraint) { Stannum::Constraints::Presence.new }
      let(:definition) do
        Stannum::Contracts::Definition.new(
          constraint: constraint,
          contract:   contract,
          options:    options
        )
      end

      it 'should add the errors from the constraint' do
        expect(
          contract.send(:add_negated_errors_for, definition, value, errors)
        )
          .to be == constraint.negated_errors_for(nil)
      end

      it 'should delegate to the constraint with value: nil' do
        allow(constraint).to receive(:update_negated_errors_for)

        contract.send(:add_negated_errors_for, definition, value, errors)

        expect(constraint)
          .to have_received(:update_negated_errors_for)
          .with(actual: nil, errors: errors)
      end
    end
  end

  describe '#add_keyword_constraint' do
    let(:keyword)    { :option }
    let(:definition) { contract.each_constraint.to_a.last }

    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_keyword_constraint)
        .with(2).arguments
        .and_keywords(:default, :sanity)
        .and_any_keywords
    end

    it 'should return the contract' do
      expect(contract.add_keyword_constraint(keyword, String)).to be contract
    end

    describe 'with default: false' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: String)
        )
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_keyword_constraint(keyword, String, default: false)
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_keyword_constraint(keyword, String, default: false)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      keyword,
            property_type: :key,
            sanity:        false
          }
        )
      end
    end

    describe 'with default: true' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: String)
        )
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_keyword_constraint(keyword, String, default: true)
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_keyword_constraint(keyword, String, default: true)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       true,
            property:      keyword,
            property_type: :key,
            sanity:        false
          }
        )
      end
    end

    describe 'with keyword: nil' do
      let(:error_message) { 'keyword must be a symbol' }

      it 'should raise an error' do
        expect do
          contract.add_keyword_constraint(nil, String)
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with keyword: an object' do
      let(:error_message) { 'keyword must be a symbol' }

      it 'should raise an error' do
        expect do
          contract.add_keyword_constraint(Object.new.freeze, String)
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with type: nil' do
      let(:error_message) do
        'type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { contract.add_keyword_constraint(keyword, nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with type: an object' do
      let(:error_message) do
        'type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { contract.add_keyword_constraint(keyword, Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with type: a class' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: Symbol)
        )
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_keyword_constraint(keyword, Symbol) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_keyword_constraint(keyword, Symbol)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      keyword,
            property_type: :key,
            sanity:        false
          }
        )
      end
    end

    describe 'with type: a constraint' do
      let(:constraint) { Stannum::Constraints::Type.new(String) }

      it 'should add the constraint to the contract' do
        expect { contract.add_keyword_constraint(keyword, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_keyword_constraint(keyword, constraint)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      keyword,
            property_type: :key,
            sanity:        false
          }
        )
      end
    end
  end

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
          constraint: be_a_constraint(Stannum::Constraints::Types::HashType)
                      .with_options(
                        allow_empty:   true,
                        expected_type: Hash,
                        key_type:      be_a_constraint(
                          Stannum::Constraints::Hashes::IndifferentKey
                        ),
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

    # rubocop:disable RSpec/RepeatedExampleGroupBody
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

    wrap_context 'when the contract has keyword constraints with defaults' do
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
    # rubocop:enable RSpec/RepeatedExampleGroupBody

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
        name: 'Self-sealing Stem Bolt',
        mass: 10,
        size: 'Tiny'
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
                        key_type:      be_a_constraint(
                          Stannum::Constraints::Hashes::IndifferentKey
                        ),
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
        constraints.map do |definition|
          options = definition.fetch(:options, {}).merge(property_type: :key)

          contract.send(:map_value, actual, **options)
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

    wrap_context 'when the contract has keyword constraints with defaults' do
      let(:values) do
        constraints.map do |definition|
          options  = definition.fetch(:options, {}).merge(property_type: :key)
          property = options[:property]

          next described_class::UNDEFINED unless actual.key?(property)

          contract.send(:map_value, actual, **options)
        end
      end
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(values)
      end

      describe 'with an empty hash' do
        let(:actual) { {} }

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

      describe 'with a hash with required values' do
        let(:actual) { { name: 'Self-sealing Stem Bolt' } }

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

      describe 'with a hash with required and optional values' do
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
    end

    wrap_context 'when the contract has a variadic keywords constraint' do
      it 'should yield each definition' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#map_value' do
    let(:actual) { Struct.new(:name).new('Alan Bradley') }

    it { expect(contract.send(:map_value, actual)).to be actual }

    it 'should return the property' do
      expect(contract.send(:map_value, actual, property: :name))
        .to be == actual.name
    end

    describe 'with property type: :key' do
      let(:actual)  { { name: 'Self-sealing Stem Bolt' } }
      let(:options) { { property: property, property_type: :key } }

      context 'when the hash does not have the specified key' do
        let(:property) { :mass }

        it 'should return the indexed value' do
          expect(contract.send(:map_value, actual, **options))
            .to be == described_class::UNDEFINED
        end
      end

      context 'when the hash has the specified key' do
        let(:property) { :name }

        it 'should return the indexed value' do
          expect(contract.send(:map_value, actual, **options))
            .to be == actual[property]
        end
      end
    end
  end

  describe '#match' do
    wrap_context 'when the contract has keyword constraints with defaults' do
      let(:result) { contract.match(actual).first }
      let(:errors) { contract.match(actual).last }

      describe 'with an empty keywords hash' do
        let(:actual) { {} }

        it { expect(result).to be false }

        it { expect(errors[:mass]).to be_empty }

        it { expect(errors[:name]).not_to be_empty }

        it { expect(errors[:size]).to be_empty }
      end

      describe 'with a keywords hash with required values' do
        let(:actual) { { name: 'Self-sealing Stem Bolt' } }

        it { expect(result).to be true }
      end

      describe 'with a keywords hash with required and optional values' do
        let(:actual) do
          {
            name: 'Self-sealing Stem Bolt',
            mass: 10,
            size: 'Tiny'
          }
        end

        it { expect(result).to be true }
      end

      describe 'with a keywords hash with explicit nils' do
        let(:actual) do
          {
            name: 'Self-sealing Stem Bolt',
            mass: nil,
            size: nil
          }
        end

        it { expect(result).to be false }

        it { expect(errors[:mass]).not_to be_empty }

        it { expect(errors[:name]).to be_empty }

        it { expect(errors[:size]).not_to be_empty }
      end
    end
  end

  describe '#match_constraint' do
    describe 'with value: UNDEFINED' do
      let(:value)      { described_class::UNDEFINED }
      let(:options)    { {} }
      let(:constraint) { Stannum::Constraints::Presence.new }
      let(:definition) do
        Stannum::Contracts::Definition.new(
          constraint: constraint,
          options:    options
        )
      end

      context 'when the constraint has default: false' do
        it 'should match nil to the constraint' do
          expect(contract.send(:match_constraint, definition, value))
            .to be == constraint.matches?(nil)
        end

        it 'should delegate to the constraint' do
          allow(constraint).to receive(:matches?)

          contract.send(:match_constraint, definition, value)

          expect(constraint).to have_received(:matches?).with(nil)
        end
      end

      context 'when the constraint has default: true' do
        let(:options) { { default: true } }

        it 'should return true' do
          expect(contract.send(:match_constraint, definition, value))
            .to be true
        end

        it 'should not delegate to the constraint' do
          allow(constraint).to receive(:matches?)

          contract.send(:match_constraint, definition, value)

          expect(constraint).not_to have_received(:matches?)
        end
      end
    end
  end

  describe '#match_negated_constraint' do
    describe 'with value: UNDEFINED' do
      let(:value)      { described_class::UNDEFINED }
      let(:options)    { {} }
      let(:constraint) { Stannum::Constraints::Presence.new }
      let(:definition) do
        Stannum::Contracts::Definition.new(
          constraint: constraint,
          options:    options
        )
      end

      context 'when the constraint has default: false' do
        it 'should match nil to the constraint' do
          expect(contract.send(:match_negated_constraint, definition, value))
            .to be == constraint.does_not_match?(nil)
        end

        it 'should delegate to the constraint' do
          allow(constraint).to receive(:does_not_match?)

          contract.send(:match_negated_constraint, definition, value)

          expect(constraint).to have_received(:does_not_match?).with(nil)
        end
      end

      context 'when the constraint has default: true' do
        let(:options) { { default: true } }

        it 'should return false' do
          expect(contract.send(:match_negated_constraint, definition, value))
            .to be false
        end

        it 'should not delegate to the constraint' do
          allow(constraint).to receive(:does_not_match?)

          contract.send(:match_negated_constraint, definition, value)

          expect(constraint).not_to have_received(:does_not_match?)
        end
      end
    end
  end

  describe '#negated_match' do
    wrap_context 'when the contract has keyword constraints with defaults' do
      let(:result) { contract.negated_match(actual).first }
      let(:errors) { contract.negated_match(actual).last }

      describe 'with an empty keywords hash' do
        let(:actual) { {} }

        it { expect(result).to be false }
      end

      describe 'with a keywords hash with required values' do
        let(:actual) { { name: 'Self-sealing Stem Bolt' } }

        it { expect(result).to be false }

        it { expect(errors[:mass]).not_to be_empty }

        it { expect(errors[:name]).not_to be_empty }

        it { expect(errors[:size]).not_to be_empty }
      end

      describe 'with a keywords hash with required and optional values' do
        let(:actual) do
          {
            name: 'Self-sealing Stem Bolt',
            mass: 10,
            size: 'Tiny'
          }
        end

        it { expect(result).to be false }

        it { expect(errors[:mass]).not_to be_empty }

        it { expect(errors[:name]).not_to be_empty }

        it { expect(errors[:size]).not_to be_empty }
      end

      describe 'with a keywords hash with explicit nils' do
        let(:actual) do
          {
            name: 'Self-sealing Stem Bolt',
            mass: nil,
            size: nil
          }
        end

        it { expect(result).to be false }

        it { expect(errors[:mass]).to be_empty }

        it { expect(errors[:name]).not_to be_empty }

        it { expect(errors[:size]).to be_empty }
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

        expect(receiver).to be_a Stannum::Constraints::Types::HashType
        expect(receiver.key_type)
          .to be_a Stannum::Constraints::Types::SymbolType
        expect(receiver.value_type).to be_a Stannum::Constraints::Type
        expect(receiver.value_type.expected_type).to be type
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_value_constraint(type)

          expect(receiver).to be_a Stannum::Constraints::Types::HashType
          expect(receiver.key_type)
            .to be_a Stannum::Constraints::Types::SymbolType
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

        expect(receiver).to be_a Stannum::Constraints::Types::HashType
        expect(receiver.key_type)
          .to be_a Stannum::Constraints::Types::SymbolType
        expect(receiver.value_type).to be_a Stannum::Constraint
        expect(receiver.value_type.options).to be == constraint.options
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_value_constraint(constraint, as: :kwargs)

          expect(receiver).to be_a Stannum::Constraints::Types::HashType
          expect(receiver.key_type)
            .to be_a Stannum::Constraints::Types::SymbolType
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
