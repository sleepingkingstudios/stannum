# frozen_string_literal: true

require 'stannum/contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'
require 'support/examples/contract_examples'
require 'support/entities/factory'
require 'support/entities/gadget'
require 'support/entities/manufacturer'

RSpec.describe Stannum::Contract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has property constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: :name, key: 'value' }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { property: :quantity, ichi: 1, ni: 2, san: 3 }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:,
          options:    { property: nil, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end
    let(:constructor_block) do
      definitions = constraints

      lambda do
        definitions.each do |definition|
          options   = definition.fetch(:options, {}).dup
          prop_name = options.delete(:property)

          if prop_name
            property(prop_name, definition[:constraint], **options)
          else
            constraint(definition[:constraint], **options)
          end
        end
      end
    end
  end

  shared_context 'when the contract has nested property constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { property: :name, key: 'value' }
        },
        {
          constraint: Stannum::Constraints::Type.new(String),
          options:    { property: %i[factory gadget name] }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:,
          options:    { property: nil, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end
    let(:constructor_block) do
      definitions = constraints

      lambda do
        definitions.each do |definition|
          options   = definition.fetch(:options, {}).dup
          prop_name = options.delete(:property)

          if prop_name
            property(prop_name, definition[:constraint], **options)
          else
            constraint(definition[:constraint], **options)
          end
        end
      end
    end
  end

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_block)   { -> {} }
  let(:constructor_options) { {} }

  describe '::Builder' do
    include Spec::Support::Examples::ContractBuilderExamples

    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      Stannum::Contract.new # rubocop:disable RSpec/DescribedClass
    end

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#contract' do
      include_examples 'should define reader',
        :contract,
        -> { contract }
    end

    describe '#property' do
      let(:property) { :foo }
      let(:custom_options) do
        { property: }
      end

      def define_from_block(...)
        builder.property(property, ...)
      end

      def define_from_constraint(constraint, **options)
        builder.property(property, constraint, **options)
      end

      it 'should define the method' do
        expect(builder)
          .to respond_to(:property)
          .with(1..2).arguments
          .and_any_keywords
          .and_a_block
      end

      include_examples 'should delegate to #constraint'

      describe 'with property: an Array' do
        let(:property) { %i[foo bar baz] }

        include_examples 'should delegate to #constraint'
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
        .and_a_block
    end

    describe 'with a block' do
      let(:builder) { instance_double(described_class::Builder, property: nil) }

      before(:example) do
        allow(described_class::Builder).to receive(:new).and_return(builder)
      end

      it 'should call the builder with the block', :aggregate_failures do
        described_class.new do
          property :foo, option: 'one'
          property :bar, option: 'two'
          property :baz, option: 'three'
        end

        expect(builder).to have_received(:property).with(:foo, option: 'one')
        expect(builder).to have_received(:property).with(:bar, option: 'two')
        expect(builder).to have_received(:property).with(:baz, option: 'three')
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#add_constraint' do
    describe 'with an invalid property name' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { Object.new.freeze }
      let(:error_message) do
        "invalid property name #{property.inspect}"
      end

      it 'should raise an error' do
        expect { contract.add_constraint(constraint, property:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { :attribute_name }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_constraint constraint, property:)
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_constraint(constraint, property:) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property:)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    { property:, sanity: false }
        )
      end
    end

    describe 'with a property constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { :attribute_name }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint constraint, property:, **options
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(constraint, property:, **options)
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property:, **options)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    options.merge(property:, sanity: false)
        )
      end
    end

    describe 'with a nested property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { %i[path to attribute] }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_constraint constraint, property:)
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_constraint(constraint, property:) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property:)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    { property:, sanity: false }
        )
      end
    end
  end

  describe '#add_property_constraint' do
    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_property_constraint)
        .with(2).arguments
        .and_keywords(:sanity)
        .and_any_keywords
    end

    describe 'with an invalid property name' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { Object.new.freeze }
      let(:error_message) do
        "invalid property name #{property.inspect}"
      end

      it 'should raise an error' do
        expect do
          contract.add_property_constraint(property, constraint)
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { :attribute_name }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_property_constraint(property, constraint))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_property_constraint(property, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_property_constraint(property, constraint)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    { property:, sanity: false }
        )
      end
    end

    describe 'with a property constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { :attribute_name }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_property_constraint(property, constraint, **options)
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_property_constraint(property, constraint, **options)
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_property_constraint(property, constraint, **options)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    options.merge(property:, sanity: false)
        )
      end
    end

    describe 'with a nested property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { %i[path to attribute] }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_property_constraint(property, constraint))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_property_constraint(property, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_property_constraint(property, constraint)

        expect(definition).to be_a_constraint_definition(
          constraint:,
          contract:,
          options:    { property:, sanity: false }
        )
      end
    end
  end

  describe '#each_constraint' do
    it { expect(contract).to respond_to(:each_constraint).with(0).arguments }

    it { expect(contract.each_constraint).to be_a Enumerator }

    it { expect(contract.each_constraint.count).to be 0 }

    it 'should not yield any constraints' do
      expect { |block| contract.each_constraint(&block) }.not_to yield_control
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the contract has property constraints' do
      let(:expected) { definitions }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end

    wrap_context 'when the contract has nested property constraints' do
      let(:expected) { definitions }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#each_pair' do
    let(:actual) { Object.new.freeze }

    def expected_property(options)
      property = Array(options.fetch(:property, []))

      return actual if property.empty?

      tools.obj.dig(actual, *property)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    it { expect(contract).to respond_to(:each_pair).with(1).argument }

    it { expect(contract.each_pair(actual)).to be_a Enumerator }

    it { expect(contract.each_pair(actual).count).to be 0 }

    it 'should not yield any constraint/value pairs' do
      expect { |block| contract.each_pair(actual, &block) }.not_to yield_control
    end

    wrap_context 'when the contract has property constraints' do
      let(:actual) do
        Spec::Gadget.new(
          name:        'Self-Sealing Stem Bolt',
          description: 'No one is sure what a self-sealing stem bolt is.',
          quantity:    1_000
        )
      end
      let(:expected) do
        definitions.map do |definition|
          [definition, expected_property(definition.options)]
        end
      end

      it { expect(contract.each_pair(actual).count).to be constraints.size }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end

    wrap_context 'when the contract has nested property constraints' do
      let(:actual) do
        Spec::Manufacturer.new
      end
      let(:expected) do
        definitions.map do |definition|
          [definition, expected_property(definition.options)]
        end
      end

      it { expect(contract.each_pair(actual).count).to be constraints.size }

      context 'when the nested properties do not exist' do
        let(:actual) do
          Spec::Manufacturer.new(
            name:    'Gadget Co.',
            factory: Spec::Factory.new
          )
        end

        it 'should yield each definition and the mapped property' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end

      context 'when the nested properties exist' do
        let(:actual) do
          Spec::Manufacturer.new(
            name:    'Gadget Co.',
            factory: Spec::Factory.new(
              address: '123 Example Street',
              gadget:  Spec::Gadget.new(
                name: 'Ambrosia Software Licenses'
              )
            )
          )
        end

        it 'should yield each definition and the mapped property' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end
  end

  describe '#map_errors' do
    let(:errors) { Stannum::Errors.new }

    it { expect(contract.send :map_errors, errors).to be errors }

    describe 'with a property' do
      let(:property) { :name }

      before(:example) do
        errors[:name].add('is too silly')
      end

      it 'should return the errors for the property' do
        expect(contract.send :map_errors, errors, property:)
          .to be == errors[:name]
      end
    end

    describe 'with a nested property' do
      let(:property) { %i[manufacturer address street] }

      before(:example) do
        errors[:manufacturer][:address][:street].add('is not on the map')
      end

      it 'should return the errors for the property' do
        expect(contract.send :map_errors, errors, property:)
          .to be == errors[:manufacturer][:address][:street]
      end
    end
  end

  describe '#map_value' do
    let(:value) { Spec::Gadget.new(name: 'Self-Sealing Stem Bolt') }

    it { expect(contract.send :map_value, value).to be value }

    describe 'with a property' do
      let(:property) { :name }

      it 'should return the property value' do
        expect(contract.send :map_value, value, property:)
          .to be value.name
      end
    end

    describe 'with a nested property' do
      let(:property) { %i[factory gadget name] }

      context 'when the property does not exist' do
        let(:value) do
          Spec::Manufacturer.new(
            name:    'Gadget Co.',
            factory: Spec::Factory.new
          )
        end

        it 'should return nil' do
          expect(contract.send :map_value, value, property:).to be nil
        end
      end

      context 'when the property exists' do
        let(:value) do
          Spec::Manufacturer.new(
            name:    'Gadget Co.',
            factory: Spec::Factory.new(
              address: '123 Example Street',
              gadget:  Spec::Gadget.new(
                name: 'Ambrosia Software Licenses'
              )
            )
          )
        end

        it 'should return the property value' do
          expect(contract.send :map_value, value, property:)
            .to be value.factory.gadget.name
        end
      end
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
  end
end
