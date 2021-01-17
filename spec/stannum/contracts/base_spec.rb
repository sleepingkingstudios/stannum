# frozen_string_literal: true

require 'stannum/contracts/base'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::Base do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has one constraint' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Base.new
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { sanity: false }.merge(definition.fetch(:options, {}))
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

  shared_context 'when the contract has many constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Base.new
        },
        {
          constraint: Stannum::Constraints::Base.new,
          options:    { key: 'value' }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          options:    { ichi: 1, ni: 2, san: 3 }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   contract,
          options:    { sanity: false }.merge(definition.fetch(:options, {}))
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

  shared_context 'when the contract includes other contracts' do
    let(:grandparent_contract) { described_class.new }
    let(:parent_contract)      { described_class.new }
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   grandparent_contract,
          options:    { metadata: :grandparent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   parent_contract,
          options:    { metadata: :parent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   contract,
          options:    { metadata: :self }
        }
      ]
    end
    let(:definitions) do
      constraints.map do |definition|
        Stannum::Contracts::Definition.new(
          constraint: definition[:constraint],
          contract:   definition[:contract],
          options:    { sanity: false }.merge(definition.fetch(:options, {}))
        )
      end
    end

    before(:example) do
      parent_contract.include(grandparent_contract)

      contract.include(parent_contract)

      constraints.each do |definition|
        definition[:contract].add_constraint(
          definition[:constraint],
          **definition.fetch(:options, {})
        )
      end
    end
  end

  shared_context 'when the contract has sanity constraints' do
    include_context 'when the contract includes other contracts'

    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   grandparent_contract,
          options:    { metadata: :grandparent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   parent_contract,
          options:    { metadata: :parent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   contract,
          options:    { metadata: :self }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   grandparent_contract,
          options:    { sanity: true, metadata: :grandparent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   parent_contract,
          options:    { sanity: true, metadata: :parent }
        },
        {
          constraint: Stannum::Constraints::Base.new,
          contract:   contract,
          options:    { sanity: true, metadata: :self }
        }
      ]
    end
    let(:grouped_definitions) do
      grouped = definitions.group_by(&:sanity?)

      grouped[true] + grouped[false]
    end
  end

  subject(:contract) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::Builder' do
    include Spec::Support::Examples::ContractBuilderExamples

    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      Stannum::Contracts::Base.new # rubocop:disable RSpec/DescribedClass
    end

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#contract' do
      include_examples 'should define reader',
        :contract,
        -> { contract }
    end

    describe '#constraint' do
      it 'should define the method' do
        expect(builder)
          .to respond_to(:constraint)
          .with(0..1).arguments
          .and_any_keywords
      end

      describe 'with no arguments' do
        let(:error_message) { 'invalid constraint nil' }

        it 'should raise an exception' do
          expect { builder.constraint }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a nil constraint' do
        let(:error_message) { 'invalid constraint nil' }

        it 'should raise an exception' do
          expect { builder.constraint(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an invalid constraint' do
        let(:constraint)    { Object.new.freeze }
        let(:error_message) { "invalid constraint #{constraint.inspect}" }

        it 'should raise an exception' do
          expect { builder.constraint(constraint) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a valid constraint' do
        let(:constraint) { Stannum::Constraint.new }

        it 'should return the builder' do
          expect(builder.constraint(constraint)).to be builder
        end

        it 'should add the constraint to the contract', :aggregate_failures do
          builder.constraint(constraint)

          definition = contract.each_constraint.to_a.last

          expect(definition).to be_a Stannum::Contracts::Definition
          expect(definition.constraint).to be constraint
          expect(definition.contract).to be contract
          expect(definition.options).to be == { sanity: false }
        end
      end

      describe 'with a valid constraint and options' do
        let(:constraint) { Stannum::Constraint.new }
        let(:options)    { { key: 'value' } }

        it 'should return the builder' do
          expect(builder.constraint(constraint, **options)).to be builder
        end

        it 'should add the constraint to the contract', :aggregate_failures do
          builder.constraint(constraint, **options)

          definition = contract.each_constraint.to_a.last

          expect(definition).to be_a Stannum::Contracts::Definition
          expect(definition.constraint).to be constraint
          expect(definition.contract).to be contract
          expect(definition.options).to be == { sanity: false }.merge(options)
        end
      end

      describe 'with a block' do
        let(:block)  { ->(actual) { actual.nil? } }
        let(:actual) { Object.new.freeze }

        it 'should return the builder' do
          expect(builder.constraint(&block)).to be builder
        end

        it 'should add the constraint to the contract', :aggregate_failures do
          builder.constraint(&block)

          definition = contract.each_constraint.to_a.last

          expect(definition).to be_a Stannum::Contracts::Definition
          expect(definition.constraint).to be_a Stannum::Constraint
          expect(definition.contract).to be contract
          expect(definition.options).to be == { sanity: false }
        end

        it 'should yield the block to the constraint' do
          expect do |block|
            builder.constraint(&block)

            definition = contract.each_constraint.to_a.last

            definition.constraint.match?(actual)
          end
            .to yield_with_args(actual)
        end
      end

      describe 'with a block and options' do
        let(:block)  { ->(actual) { actual.nil? } }
        let(:actual) { Object.new.freeze }
        let(:options) do
          {
            key:          'value',
            negated_type: 'spec.negated_type',
            type:         'spec.custom_type'
          }
        end

        it 'should return the builder' do
          expect(builder.constraint(**options, &block)).to be builder
        end

        it 'should add the constraint to the contract', :aggregate_failures do
          builder.constraint(**options, &block)

          definition = contract.each_constraint.to_a.last

          expect(definition).to be_a Stannum::Contracts::Definition
          expect(definition.constraint).to be_a Stannum::Constraint
          expect(definition.constraint.options).to be == options
          expect(definition.contract).to be contract
          expect(definition.options).to be == { sanity: false }.merge(options)
        end

        it 'should yield the block to the constraint' do
          expect do |block|
            builder.constraint(**options, &block)

            definition = contract.each_constraint.to_a.last

            definition.constraint.match?(actual)
          end
            .to yield_with_args(actual)
        end
      end

      describe 'with a block and a constraint' do
        let(:block)      { ->(actual) { actual.nil? } }
        let(:constraint) { Stannum::Constraint.new }
        let(:error_message) do
          'expected either a block or a constraint instance, but received' \
          " both a block and #{constraint.inspect}"
        end

        it 'should raise an exception' do
          expect { builder.constraint(constraint, &block) }
            .to raise_error ArgumentError, error_message
        end
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
      let(:builder) do
        instance_double(described_class::Builder, constraint: nil)
      end

      before(:example) do
        allow(described_class::Builder).to receive(:new).and_return(builder)
      end

      it 'should call the builder with the block', :aggregate_failures do
        described_class.new do
          constraint option: 'one'
          constraint option: 'two'
          constraint option: 'three'
        end

        expect(builder).to have_received(:constraint).with(option: 'one')
        expect(builder).to have_received(:constraint).with(option: 'two')
        expect(builder).to have_received(:constraint).with(option: 'three')
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#==' do
    describe 'with nil' do
      it { expect(contract == nil).to be false } # rubocop:disable Style/NilComparison
    end

    describe 'with an Object' do
      it { expect(contract == Object.new.freeze).to be false }
    end

    describe 'with a subclass instance' do
      it { expect(contract == Class.new(described_class).new).to be false }
    end

    describe 'with a contract instance with different constraints' do
      let(:other) do
        described_class
          .new(**contract.options)
          .add_constraint(Stannum::Constraint.new)
      end

      it { expect(contract == other).to be false }
    end

    describe 'with a contract instance with different options' do
      let(:other) { described_class.new(other_option: 'value') }

      it { expect(contract == other).to be false }
    end

    describe 'with a contract instance with identical options' do
      let(:other) { described_class.new(**contract.options) }

      it { expect(contract == other).to be true }
    end

    wrap_context 'when the contract has one constraint' do
      describe 'with a contract instance with different options' do
        let(:other) { described_class.new(**contract.options) }

        before(:example) do
          constraints.each do |definition|
            other.add_constraint(
              definition[:constraint],
              **definition.fetch(:options, {}).merge(key: 'value')
            )
          end
        end

        it { expect(contract == other).to be false }
      end

      describe 'with a contract instance with an identical constraint' do
        let(:other) { described_class.new(**contract.options) }

        before(:example) do
          constraints.each do |definition|
            other.add_constraint(
              definition[:constraint],
              **definition.fetch(:options, {})
            )
          end
        end

        it { expect(contract == other).to be true }
      end
    end

    wrap_context 'when the contract has many constraints' do
      describe 'with a contract instance with missing constraints' do
        let(:other) { described_class.new(**contract.options) }

        it { expect(contract == other).to be false }
      end

      describe 'with a contract instance with extra constraints' do
        let(:other) { described_class.new(**contract.options) }

        before(:example) do
          constraints.each do |definition|
            other.add_constraint(
              definition[:constraint],
              **definition.fetch(:options, {})
            )
          end

          other.add_constraint(Stannum::Constraint.new)
        end

        it { expect(contract == other).to be false }
      end

      describe 'with a contract instance with identical constraints' do
        let(:other) { described_class.new(**contract.options) }

        before(:example) do
          constraints.each do |definition|
            other.add_constraint(
              definition[:constraint],
              **definition.fetch(:options, {})
            )
          end
        end

        it { expect(contract == other).to be true }
      end
    end

    context 'when initialized with options' do
      let(:constructor_options) { super().merge(key: 'value') }

      describe 'with a contract instance with different constraints' do
        let(:other) do
          described_class
            .new(**contract.options)
            .add_constraint(Stannum::Constraint.new)
        end

        it { expect(contract == other).to be false }
      end

      describe 'with a contract instance with different options' do
        let(:other) { described_class.new(other_option: 'value') }

        it { expect(contract == other).to be false }
      end

      describe 'with a contract instance with identical options' do
        let(:other) { described_class.new(**contract.options) }

        it { expect(contract == other).to be true }
      end
    end
  end

  describe '#add_constraint' do
    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_constraint)
        .with(1).argument
        .and_any_keywords
    end

    describe 'with nil' do
      let(:error_message) do
        'must be an instance of Stannum::Constraints::Base'
      end

      it 'should raise an error' do
        expect { contract.add_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        'must be an instance of Stannum::Constraints::Base'
      end

      it 'should raise an error' do
        expect { contract.add_constraint Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it { expect(contract.add_constraint constraint).to be contract }

      it 'should add the constraint to the contract', :aggregate_failures do
        expect { contract.add_constraint(constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and options' do
        contract.add_constraint(constraint)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    { sanity: false }
        )
      end
    end

    describe 'with a constraint and options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_constraint(constraint, **options)).to be contract
      end

      it 'should add the constraint to the contract', :aggregate_failures do
        expect { contract.add_constraint(constraint, **options) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract and options' do
        contract.add_constraint(constraint, **options)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    { sanity: false }.merge(options)
        )
      end
    end

    wrap_context 'when the contract has many constraints' do
      describe 'with a constraint' do
        let(:constraint) { Stannum::Constraint.new }
        let(:definition) { contract.each_constraint.to_a.last }

        it { expect(contract.add_constraint constraint).to be contract }

        it 'should add the constraint to the contract', :aggregate_failures do
          expect { contract.add_constraint(constraint) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract and options' do
          contract.add_constraint(constraint)

          expect(definition).to be_a_constraint_definition(
            constraint: constraint,
            contract:   contract,
            options:    { sanity: false }
          )
        end
      end

      describe 'with a constraint and options' do
        let(:constraint) { Stannum::Constraint.new }
        let(:options)    { { key: 'value' } }
        let(:definition) { contract.each_constraint.to_a.last }

        it 'should return the contract' do
          expect(contract.add_constraint(constraint, **options)).to be contract
        end

        it 'should add the constraint to the contract', :aggregate_failures do
          expect { contract.add_constraint(constraint, **options) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract and options' do
          contract.add_constraint(constraint, **options)

          expect(definition).to be_a_constraint_definition(
            constraint: constraint,
            contract:   contract,
            options:    { sanity: false }.merge(options)
          )
        end
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

    wrap_context 'when the contract has one constraint' do
      let(:expected) { definitions }

      it { expect(contract.each_constraint.count).to be 1 }

      it 'should yield the definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_with_args(expected.first)
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the contract has many constraints' do
      let(:expected) { definitions }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end

    wrap_context 'when the contract includes other contracts' do
      let(:expected) { definitions }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody

    wrap_context 'when the contract has sanity constraints' do
      let(:expected) { grouped_definitions }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#each_pair' do
    let(:actual) { Object.new.freeze }

    it { expect(contract).to respond_to(:each_pair).with(1).argument }

    it { expect(contract.each_pair(actual)).to be_a Enumerator }

    it { expect(contract.each_pair(actual).count).to be 0 }

    it 'should not yield any constraint/value pairs' do
      expect { |block| contract.each_constraint(&block) }.not_to yield_control
    end

    wrap_context 'when the contract has one constraint' do
      let(:expected) { definitions.zip(Array.new(constraints.size, actual)) }

      it { expect(contract.each_pair(actual).count).to be 1 }

      it 'should yield the definition and the object' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_with_args(*expected.first)
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the contract has many constraints' do
      let(:expected) { definitions.zip(Array.new(constraints.size, actual)) }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition and the object' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end

    wrap_context 'when the contract includes other contracts' do
      let(:expected) { definitions.zip(Array.new(constraints.size, actual)) }

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition and the object' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody

    wrap_context 'when the contract has sanity constraints' do
      let(:expected) do
        grouped_definitions.zip(Array.new(constraints.size, actual))
      end

      it { expect(contract.each_constraint.count).to be constraints.size }

      it 'should yield each definition and the object' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#include' do
    let(:error_message) { 'must be an instance of Stannum::Contract' }

    it { expect(contract).to respond_to(:include).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { contract.include nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { contract.include Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint' do
      it 'should raise an error' do
        expect { contract.include Stannum::Constraints::Base.new }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty contract' do
      let(:other) { described_class.new }

      it 'should return the contract' do
        expect(contract.include other).to be contract
      end

      it 'should not change the constraints' do
        expect { contract.include other }
          .not_to(change { contract.each_constraint.to_a })
      end

      context 'when a constraint is added to the other contract' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:expected) do
          Stannum::Contracts::Definition.new(
            constraint: constraint,
            contract:   other,
            options:    { sanity: false }
          )
        end

        it 'should add the constraint to the contract' do
          contract.include other

          expect { other.add_constraint(constraint) }
            .to change { contract.each_constraint.to_a }
            .to include(expected)
        end
      end
    end

    describe 'with a contract with constraints' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:other)      { described_class.new }
      let(:expected) do
        Stannum::Contracts::Definition.new(
          constraint: constraint,
          contract:   other,
          options:    { sanity: false }
        )
      end

      before(:example) { other.add_constraint(constraint) }

      it 'should add the constraints to the contract' do
        expect { contract.include other }
          .to change { contract.each_constraint.to_a }
          .to include(expected)
      end
    end

    wrap_context 'when the contract has many constraints' do
      describe 'with a contract with constraints' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:other)      { described_class.new }
        let(:expected) do
          Stannum::Contracts::Definition.new(
            constraint: constraint,
            contract:   other,
            options:    { sanity: false }
          )
        end

        before(:example) { other.add_constraint(constraint) }

        it 'should add the constraints to the contract' do
          expect { contract.include other }
            .to change { contract.each_constraint.to_a }
            .to include(expected)
        end
      end
    end
  end

  describe '#map_errors' do
    let(:errors) { Stannum::Errors.new }

    it 'should define the private method' do
      expect(contract)
        .to respond_to(:map_errors, true)
        .with(1).argument
        .and_any_keywords
    end

    it { expect(contract.send(:map_errors, errors)).to be errors }

    describe 'with options' do
      let(:options) { { key: 'value' } }

      it { expect(contract.send(:map_errors, errors, **options)).to be errors }
    end
  end

  describe '#map_value' do
    let(:value) { Object.new.freeze }

    it 'should define the private method' do
      expect(contract)
        .to respond_to(:map_value, true)
        .with(1).argument
        .and_any_keywords
    end

    it { expect(contract.send(:map_value, value)).to be value }

    describe 'with options' do
      let(:options) { { key: 'value' } }

      it { expect(contract.send(:map_value, value, **options)).to be value }
    end
  end
end
