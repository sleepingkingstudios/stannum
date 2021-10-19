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
        options = definition.fetch(:options, {})

        be_a_constraint_definition(
          constraint: definition[:constraint].with_options(**options),
          contract:   contract,
          options:    {
            default:       false,
            property:      index,
            property_type: :index,
            sanity:        false
          }
            .merge(options)
        )
      end
    end

    before(:example) do
      constraints.each.with_index do |definition, index|
        contract.add_argument_constraint(
          index,
          definition[:constraint],
          **definition.fetch(:options, {})
        )
      end
    end
  end

  shared_context 'when the contract has argument constraints with defaults' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new
        },
        {
          constraint: Stannum::Constraints::Type.new(String),
          options:    { default: true, type: :index, key: 'value' }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { default: true, type: :index, ichi: 1, ni: 2, san: 3 }
        }
      ]
    end
    let(:definitions) do
      constraints.map.with_index do |definition, index|
        options            = definition.fetch(:options, {})
        constraint_options = options.dup.tap { |hsh| hsh.delete(:default) }
        constraint         =
          definition[:constraint].with_options(**constraint_options)

        be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      index,
            property_type: :index,
            sanity:        false
          }
            .merge(options)
        )
      end
    end

    before(:example) do
      constraints.each.with_index do |definition, index|
        contract.add_argument_constraint(
          index,
          definition[:constraint],
          **definition.fetch(:options, {})
        )
      end
    end
  end

  shared_context 'when the contract has a variadic arguments constraint' do
    let(:receiver) do
      Stannum::Constraints::Types::ArrayType.new(item_type: String)
    end
    let(:receiver_definition) do
      be_a_constraint(Stannum::Constraints::Types::ArrayType).and(
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

  describe '#add_argument_constraint' do
    let(:definition) { contract.each_constraint.to_a.last }

    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_argument_constraint)
        .with(2).arguments
        .and_keywords(:default, :sanity)
        .and_any_keywords
    end

    it { expect(contract.add_argument_constraint(0, String)).to be contract }

    describe 'with default: false' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: String)
        )
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_argument_constraint(nil, String, default: false) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, String, default: false)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      0,
            property_type: :index,
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
        expect { contract.add_argument_constraint(nil, String, default: true) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, String, default: true)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       true,
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with index: nil' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: String)
        )
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_argument_constraint(nil, String) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, String)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end

      wrap_context 'when the contract has many argument constraints' do
        it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
          contract.add_argument_constraint(nil, String)

          expect(definition).to be_a_constraint_definition(
            constraint: expected_constraint,
            contract:   contract,
            options:    {
              default:       false,
              property:      constraints.size,
              property_type: :index,
              sanity:        false
            }
          )
        end
      end
    end

    describe 'with index: an object' do
      let(:index)         { Object.new.freeze }
      let(:error_message) { "invalid property name #{index.inspect}" }

      it 'should raise an error' do
        expect do
          contract.add_argument_constraint(index, String)
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with index: an integer' do
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: String)
        )
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_argument_constraint(3, String) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(3, String)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      3,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with type: nil' do
      let(:error_message) do
        'type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { contract.add_argument_constraint(nil, nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with type: an object' do
      let(:error_message) do
        'type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { contract.add_argument_constraint(nil, Object.new.freeze) }
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
        expect { contract.add_argument_constraint(nil, Symbol) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, Symbol)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with type: a constraint' do
      let(:constraint) { Stannum::Constraints::Type.new(String) }

      it 'should add the constraint to the contract' do
        expect { contract.add_argument_constraint(nil, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, constraint)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      0,
            property_type: :index,
            sanity:        false
          }
        )
      end
    end

    describe 'with options' do
      let(:options) { { key: 'value' } }
      let(:expected_constraint) do
        be_a(Stannum::Constraints::Type).and(
          have_attributes(expected_type: Symbol)
        )
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_argument_constraint(nil, Symbol, **options) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_argument_constraint(nil, Symbol, **options)

        expect(definition).to be_a_constraint_definition(
          constraint: expected_constraint,
          contract:   contract,
          options:    {
            default:       false,
            property:      0,
            property_type: :index,
            sanity:        false,
            **options
          }
        )
      end
    end
  end

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
        allow(constraint).to receive(:errors_for)

        contract.send(:add_errors_for, definition, value, errors)

        expect(constraint)
          .to have_received(:errors_for)
          .with(nil, errors: errors)
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
        allow(constraint).to receive(:negated_errors_for)

        contract.send(:add_negated_errors_for, definition, value, errors)

        expect(constraint)
          .to have_received(:negated_errors_for)
          .with(nil, errors: errors)
      end
    end
  end

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
          constraint: be_a_constraint(Stannum::Constraints::Signatures::Tuple),
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

    wrap_context 'when the contract has argument constraints with defaults' do
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
    # rubocop:enable RSpec/RepeatedExampleGroupBody

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
          constraint: be_a_constraint(Stannum::Constraints::Signatures::Tuple),
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

    wrap_context 'when the contract has argument constraints with defaults' do
      let(:items_count) { definitions.count }

      describe 'with an empty array' do
        let(:actual) { [] }
        let(:expected) do
          builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
            definitions.zip(Array.new(3, described_class::UNDEFINED))
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

      describe 'with an array with required values' do
        let(:actual) { %w[ichi] }
        let(:expected) do
          builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
            definitions.zip(
              [*actual, described_class::UNDEFINED, described_class::UNDEFINED]
            )
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

      describe 'with an array with required and optional values' do
        let(:actual) { %w[ichi ni san] }
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
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      it 'should yield each definition and the mapped property' do
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

    describe 'with property type: :index' do
      let(:actual)  { %w[ichi ni san] }
      let(:index)   { 1 }
      let(:options) { { property: index, property_type: :index } }

      context 'when the index is less than the array size' do
        let(:index) { 2 }

        it 'should return the indexed value' do
          expect(contract.send(:map_value, actual, **options))
            .to be == actual[index]
        end
      end

      context 'when the index is equal to the array size' do
        let(:index) { 3 }

        it 'should return the indexed value' do
          expect(contract.send(:map_value, actual, **options))
            .to be == described_class::UNDEFINED
        end
      end

      context 'when the index is greater than the array size' do
        let(:index) { 4 }

        it 'should return the indexed value' do
          expect(contract.send(:map_value, actual, **options))
            .to be == described_class::UNDEFINED
        end
      end
    end
  end

  describe '#match' do
    wrap_context 'when the contract has argument constraints with defaults' do
      let(:result) { contract.match(actual).first }
      let(:errors) { contract.match(actual).last }

      describe 'with an empty arguments array' do
        let(:actual) { [] }

        it { expect(result).to be false }

        it { expect(errors[0]).not_to be_empty }
      end

      describe 'with an arguments array with required values' do
        let(:actual) { [Object.new.freeze] }

        it { expect(result).to be true }
      end

      describe 'with an arguments array with required and optional values' do
        let(:actual) { [Object.new.freeze, '', 0] }

        it { expect(result).to be true }
      end

      describe 'with an arguments array with explicit nil values' do
        let(:actual) { [Object.new.freeze, nil, nil] }

        it { expect(result).to be false }

        it { expect(errors[1]).not_to be_empty }

        it { expect(errors[2]).not_to be_empty }
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

        it 'should return true' do
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
    wrap_context 'when the contract has argument constraints with defaults' do
      let(:result) { contract.negated_match(actual).first }
      let(:errors) { contract.negated_match(actual).last }

      describe 'with an empty arguments array' do
        let(:actual) { [] }

        it { expect(result).to be false }

        it { expect(errors[0]).to be_empty }

        it { expect(errors[1]).not_to be_empty }

        it { expect(errors[2]).not_to be_empty }
      end

      describe 'with an arguments array with required values' do
        let(:actual) { [Object.new.freeze] }

        it { expect(result).to be false }

        it { expect(errors[0]).not_to be_empty }

        it { expect(errors[1]).not_to be_empty }

        it { expect(errors[2]).not_to be_empty }
      end

      describe 'with an arguments array with required and optional values' do
        let(:actual) { [Object.new.freeze, '', 0] }

        it { expect(result).to be false }

        it { expect(errors[0]).not_to be_empty }

        it { expect(errors[1]).not_to be_empty }

        it { expect(errors[2]).not_to be_empty }
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

    wrap_context 'when the contract has a variadic arguments constraint' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'variadic arguments constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_variadic_constraint constraint }
          .to raise_error RuntimeError, error_message
      end
    end
  end

  describe '#set_variadic_item_constraint' do
    let(:definition) { contract.send(:variadic_definition) }
    let(:receiver)   { contract.send(:variadic_constraint).receiver }

    it 'should define the method' do
      expect(contract)
        .to respond_to(:set_variadic_item_constraint)
        .with(1).argument
        .and_keywords(:as)
    end

    it 'should return the contract' do
      expect(contract.set_variadic_item_constraint Stannum::Constraint.new)
        .to be contract
    end

    describe 'with nil' do
      let(:error_message) do
        'item type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_item_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'item type must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { contract.set_variadic_item_constraint Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a class' do
      let(:type) { String }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_item_constraint(type)

        expect(receiver).to be_a Stannum::Constraints::Types::ArrayType
        expect(receiver.item_type).to be_a Stannum::Constraints::Type
        expect(receiver.item_type.expected_type).to be type
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_item_constraint(type, as: :splatted)

          expect(receiver).to be_a Stannum::Constraints::Types::ArrayType
          expect(receiver.item_type).to be_a Stannum::Constraints::Type
          expect(receiver.item_type.expected_type).to be type
        end

        it 'should update the property name' do
          expect { contract.set_variadic_item_constraint(type, as: :splatted) }
            .to change(definition, :property_name)
            .to be :splatted
        end
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraint.new(type: 'spec.type') }

      it 'should update the variadic constraint', :aggregate_failures do
        contract.set_variadic_item_constraint(constraint)

        expect(receiver).to be_a Stannum::Constraints::Types::ArrayType
        expect(receiver.item_type).to be_a Stannum::Constraint
        expect(receiver.item_type.options).to be == constraint.options
      end

      describe 'with as: a value' do
        it 'should update the variadic constraint', :aggregate_failures do
          contract.set_variadic_item_constraint(constraint, as: :splatted)

          expect(receiver).to be_a Stannum::Constraints::Types::ArrayType
          expect(receiver.item_type).to be_a Stannum::Constraint
          expect(receiver.item_type.options).to be == constraint.options
        end

        it 'should update the property name' do
          expect do
            contract.set_variadic_item_constraint(constraint, as: :splatted)
          end
            .to change(definition, :property_name)
            .to be :splatted
        end
      end
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      let(:constraint)    { Stannum::Constraint.new }
      let(:error_message) { 'variadic arguments constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_variadic_item_constraint constraint }
          .to raise_error RuntimeError, error_message
      end
    end
  end
end
