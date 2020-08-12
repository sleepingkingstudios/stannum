# frozen_string_literal: true

require 'stannum/contracts/property_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_examples'
require 'support/structs/gadget'

RSpec.describe Stannum::Contracts::PropertyContract do
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
          contract:   contract,
          options:    { property: nil, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end

    before(:example) do
      constraints.each do |definition|
        contract.add_constraint(
          definition[:constraint],
          **definition.fetch(:options, {})
        )
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
          contract:   contract,
          options:    { property: nil, sanity: false }
            .merge(definition.fetch(:options, {}))
        )
      end
    end

    before(:example) do
      constraints.each do |definition|
        contract.add_constraint(
          definition[:constraint],
          **definition.fetch(:options, {})
        )
      end
    end
  end

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

  describe '#add_constraint' do
    describe 'with a property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { :attribute_name }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_constraint constraint, property: property)
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_constraint(constraint, property: property) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property: property)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    { property: property, sanity: false }
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
          contract.add_constraint constraint, property: property, **options
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(constraint, property: property, **options)
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property: property, **options)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    options.merge(property: property, sanity: false)
        )
      end
    end

    describe 'with a nested property constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:property)   { %i[path to attribute] }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_constraint constraint, property: property)
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_constraint(constraint, property: property) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and property' do
        contract.add_constraint(constraint, property: property)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    { property: property, sanity: false }
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

      # @todo Extract this to spec/support/structs
      example_class 'Spec::Factory' do |klass|
        klass.include Stannum::Struct

        klass.attribute :address, String
        klass.attribute :gadget,  Spec::Gadget
      end

      # @todo Extract this to spec/support/structs
      example_class 'Spec::Manufacturer' do |klass|
        klass.include Stannum::Struct

        klass.attribute :factory, 'Spec::Factory'
        klass.attribute :name,    String
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
        expect(contract.send :map_errors, errors, property: property)
          .to be == errors[:name]
      end
    end

    describe 'with a nested property' do
      let(:property) { %i[manufacturer address street] }

      before(:example) do
        errors[:manufacturer][:address][:street].add('is not on the map')
      end

      it 'should return the errors for the property' do
        expect(contract.send :map_errors, errors, property: property)
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
        expect(contract.send :map_value, value, property: property)
          .to be value.name
      end
    end

    describe 'with a nested property' do
      let(:property) { %i[factory gadget name] }

      # @todo Extract this to spec/support/structs
      example_class 'Spec::Factory' do |klass|
        klass.include Stannum::Struct

        klass.attribute :address, String
        klass.attribute :gadget,  Spec::Gadget
      end

      # @todo Extract this to spec/support/structs
      example_class 'Spec::Manufacturer' do |klass|
        klass.include Stannum::Struct

        klass.attribute :factory, 'Spec::Factory'
        klass.attribute :name,    String
      end

      context 'when the property does not exist' do
        let(:value) do
          Spec::Manufacturer.new(
            name:    'Gadget Co.',
            factory: Spec::Factory.new
          )
        end

        it 'should return nil' do
          expect(contract.send :map_value, value, property: property).to be nil
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
          expect(contract.send :map_value, value, property: property)
            .to be value.factory.gadget.name
        end
      end
    end
  end
end
