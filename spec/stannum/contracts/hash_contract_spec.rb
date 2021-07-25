# frozen_string_literal: true

require 'stannum/contracts/hash_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::HashContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has many key constraints' do
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

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_block)   { -> {} }
  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_extra_keys: false,
      allow_hash_like:  false,
      key_type:         nil
    }
  end

  describe '::Builder' do
    include Spec::Support::Examples::ContractBuilderExamples

    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      Stannum::Contracts::HashContract.new # rubocop:disable RSpec/DescribedClass
    end

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#contract' do
      include_examples 'should define reader',
        :contract,
        -> { contract }
    end

    describe '#key' do
      let(:property) { :name }
      let(:custom_options) do
        { property: property, property_type: :key }
      end

      def define_from_block(**options, &block)
        builder.key(property, **options, &block)
      end

      def define_from_constraint(constraint, **options)
        builder.key(property, constraint, **options)
      end

      it 'should define the method' do
        expect(builder)
          .to respond_to(:key)
          .with(1..2).arguments
          .and_any_keywords
          .and_a_block
      end

      include_examples 'should delegate to #constraint'
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:allow_extra_keys, :allow_hash_like, :key_type)
        .and_any_keywords
        .and_a_block
    end

    describe 'with key_type: an Object' do
      let(:error_message) do
        'key type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { described_class.new key_type: Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
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
    describe 'with a key constraint' do
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

    describe 'with a key constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(
          contract.add_constraint(
            constraint,
            property:      :name,
            property_type: :key,
            **options
          )
        )
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect do
          contract.add_constraint(
            constraint,
            property:      :name,
            property_type: :key,
            **options
          )
        end
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_constraint(
          constraint,
          property:      :name,
          property_type: :key,
          **options
        )

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      :name,
            property_type: :key,
            sanity:        false,
            **options
          }
        )
      end
    end

    context 'when initialized with key_type: a class' do
      let(:constructor_options) { super().merge(key_type: String) }

      describe 'with an invalid key' do
        let(:constraint)    { Stannum::Constraint.new }
        let(:error_message) { 'invalid property name :name' }

        it 'should raise an error' do
          expect do
            contract.add_constraint(
              constraint,
              property:      :name,
              property_type: :key
            )
          end
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a key constraint' do
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
    end

    context 'when initialized with key_type: a constraint' do
      let(:key_type)            { Stannum::Constraints::Type.new(String) }
      let(:constructor_options) { super().merge(key_type: key_type) }

      describe 'with an invalid key' do
        let(:constraint)    { Stannum::Constraint.new }
        let(:error_message) { 'invalid property name :name' }

        it 'should raise an error' do
          expect do
            contract.add_constraint(
              constraint,
              property:      :name,
              property_type: :key
            )
          end
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a key constraint' do
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
    end
  end

  describe '#add_key_constraint' do
    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_key_constraint)
        .with(2).arguments
        .and_keywords(:sanity)
        .and_any_keywords
    end

    describe 'with a key constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_key_constraint(:name, constraint))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_key_constraint(:name, constraint) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do
        contract.add_key_constraint(:name, constraint)

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

    describe 'with a key constraint with options' do
      let(:constraint) { Stannum::Constraint.new }
      let(:options)    { { key: 'value' } }
      let(:definition) { contract.each_constraint.to_a.last }

      it 'should return the contract' do
        expect(contract.add_key_constraint(:name, constraint, **options))
          .to be contract
      end

      it 'should add the constraint to the contract' do
        expect { contract.add_key_constraint(:name, constraint, **options) }
          .to change { contract.each_constraint.count }
          .by(1)
      end

      it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
        contract.add_key_constraint(:name, constraint, **options)

        expect(definition).to be_a_constraint_definition(
          constraint: constraint,
          contract:   contract,
          options:    {
            property:      :name,
            property_type: :key,
            sanity:        false,
            **options
          }
        )
      end
    end

    context 'when initialized with key_type: a class' do
      let(:constructor_options) { super().merge(key_type: String) }

      describe 'with an invalid key' do
        let(:constraint)    { Stannum::Constraint.new }
        let(:error_message) { 'invalid property name :name' }

        it 'should raise an error' do
          expect { contract.add_key_constraint(:name, constraint) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a key constraint' do
        let(:constraint) { Stannum::Constraint.new }
        let(:definition) { contract.each_constraint.to_a.last }

        it 'should return the contract' do
          expect(contract.add_key_constraint('name', constraint))
            .to be contract
        end

        it 'should add the constraint to the contract' do
          expect { contract.add_key_constraint('name', constraint) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract' do
          contract.add_key_constraint('name', constraint)

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

      describe 'with a key constraint with options' do
        let(:constraint) { Stannum::Constraint.new }
        let(:options)    { { key: 'value' } }
        let(:definition) { contract.each_constraint.to_a.last }

        it 'should return the contract' do
          expect(contract.add_key_constraint('name', constraint, **options))
            .to be contract
        end

        it 'should add the constraint to the contract' do
          expect { contract.add_key_constraint('name', constraint, **options) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
          contract.add_key_constraint('name', constraint, **options)

          expect(definition).to be_a_constraint_definition(
            constraint: constraint,
            contract:   contract,
            options:    {
              property:      'name',
              property_type: :key,
              sanity:        false,
              **options
            }
          )
        end
      end
    end

    context 'when initialized with key_type: a constraint' do
      let(:key_type)            { Stannum::Constraints::Type.new(String) }
      let(:constructor_options) { super().merge(key_type: key_type) }

      describe 'with an invalid key' do
        let(:constraint)    { Stannum::Constraint.new }
        let(:error_message) { 'invalid property name :name' }

        it 'should raise an error' do
          expect { contract.add_key_constraint(:name, constraint) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a key constraint' do
        let(:constraint) { Stannum::Constraint.new }
        let(:definition) { contract.each_constraint.to_a.last }

        it 'should return the contract' do
          expect(contract.add_key_constraint('name', constraint))
            .to be contract
        end

        it 'should add the constraint to the contract' do
          expect { contract.add_key_constraint('name', constraint) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract' do
          contract.add_key_constraint('name', constraint)

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

      describe 'with a key constraint with options' do
        let(:constraint) { Stannum::Constraint.new }
        let(:options)    { { key: 'value' } }
        let(:definition) { contract.each_constraint.to_a.last }

        it 'should return the contract' do
          expect(contract.add_key_constraint('name', constraint, **options))
            .to be contract
        end

        it 'should add the constraint to the contract' do
          expect { contract.add_key_constraint('name', constraint, **options) }
            .to change { contract.each_constraint.count }
            .by(1)
        end

        it 'should store the contract' do # rubocop:disable RSpec/ExampleLength
          contract.add_key_constraint('name', constraint, **options)

          expect(definition).to be_a_constraint_definition(
            constraint: constraint,
            contract:   contract,
            options:    {
              property:      'name',
              property_type: :key,
              sanity:        false,
              **options
            }
          )
        end
      end
    end
  end

  describe '#allow_extra_keys?' do
    include_examples 'should have predicate', :allow_extra_keys?, false

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }

      it { expect(contract.allow_extra_keys?).to be true }
    end
  end

  describe '#each_constraint' do
    let(:expected_keys) { Set.new }
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

    wrap_context 'when the contract has many key constraints' do
      let(:expected) { builtin_definitions + definitions }

      it { expect(contract.each_constraint.count).to be 2 + constraints.size }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
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

      it { expect(contract.each_constraint.count).to be 1 }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has many key constraints' do
        let(:expected) { builtin_definitions + definitions }

        it { expect(contract.each_constraint.count).to be 1 + constraints.size }

        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    context 'when initialized with allow_hash_like: true' do
      let(:constructor_options) { super().merge(allow_hash_like: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Map
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

      wrap_context 'when the contract has many key constraints' do
        let(:expected) { builtin_definitions + definitions }

        it { expect(contract.each_constraint.count).to be 2 + constraints.size }

        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    context 'when the contract includes another hash contract' do
      let(:other_contract) { described_class.new(allow_hash_like: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Map
              expect(definition.sanity?).to be true
            end
          ),
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
          )
        ]
      end

      before(:example) { contract.include(other_contract) }

      it { expect(contract.each_constraint.count).to be 3 }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has many key constraints' do
        let(:expected) { builtin_definitions + definitions }

        it 'should have the expected size' do
          expect(contract.each_constraint.count).to be 3 + constraints.size
        end

        it 'should yield each definition' do
          expect { |block| contract.each_constraint(&block) }
            .to yield_successive_args(*expected)
        end
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

    wrap_context 'when the contract has many key constraints' do
      let(:values) do
        definitions.map do |definition|
          contract.send(:map_value, actual, **definition.options)
        end
      end
      let(:expected) do
        builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
          definitions.zip(values)
      end

      it 'should have the expected size' do
        expect(contract.each_pair(actual).count).to be(2 + constraints.size)
      end

      it 'should yield each definition' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
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

      wrap_context 'when the contract has many key constraints' do
        let(:values) do
          definitions.map do |definition|
            contract.send(:map_value, actual, **definition.options)
          end
        end
        let(:expected) do
          builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
            definitions.zip(values)
        end

        it 'should have the expected size' do
          expect(contract.each_pair(actual).count).to be(1 + constraints.size)
        end

        it 'should yield each definition' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    context 'when initialized with allow_hash_like: true' do
      let(:constructor_options) { super().merge(allow_hash_like: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Map
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

      it { expect(contract.each_pair(actual).count).to be 2 }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has many key constraints' do
        let(:values) do
          definitions.map do |definition|
            contract.send(:map_value, actual, **definition.options)
          end
        end
        let(:expected) do
          builtin_definitions.zip(Array.new(builtin_definitions.size, actual)) +
            definitions.zip(values)
        end

        it 'should have the expected size' do
          expect(contract.each_pair(actual).count).to be(2 + constraints.size)
        end

        it 'should yield each definition' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    context 'when the contract includes another hash contract' do
      let(:other_contract) { described_class.new(allow_hash_like: true) }
      let(:builtin_definitions) do
        [
          an_instance_of(Stannum::Contracts::Definition).and(
            satisfy do |definition|
              expect(definition.constraint)
                .to be_a Stannum::Constraints::Signatures::Map
              expect(definition.sanity?).to be true
            end
          ),
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
              expect(definition.constraint.expected_keys)
                .to be == expected_keys
              expect(definition.sanity?).to be false
            end
          )
        ]
      end

      before(:example) { contract.include(other_contract) }

      it { expect(contract.each_pair(actual).count).to be 3 }

      it 'should yield each definition and the mapped property' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end

      wrap_context 'when the contract has many key constraints' do
        let(:values) do
          definitions.map do |definition|
            contract.send(:map_value, actual, **definition.options)
          end
        end
        let(:expected) do
          builtin_definitions.zip(
            Array.new(builtin_definitions.size, actual)
          ) +
            definitions.zip(values)
        end

        it 'should have the expected size' do
          expect(contract.each_pair(actual).count).to be(3 + constraints.size)
        end

        it 'should yield each definition' do
          expect { |block| contract.each_pair(actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end
  end

  describe '#map_errors' do
    let(:errors) { Stannum::Errors.new }

    it { expect(contract.send :map_errors, errors).to be errors }

    describe 'with property_type: :key' do
      let(:key) { :name }

      before(:example) do
        errors[key].add('spec.keyed_error')
      end

      it 'should return the errors for the index' do
        expect(
          contract.send(
            :map_errors,
            errors,
            property:      key,
            property_type: :key
          )
        )
          .to be == errors[key]
      end
    end
  end

  describe '#map_value' do
    let(:value) { { name: 'Self-sealing Stem Bolt' } }

    it { expect(contract.send :map_value, value).to be value }

    describe 'with property_type: :key' do
      let(:key) { :name }

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

  describe '#options' do
    let(:expected) do
      {
        allow_extra_keys: false,
        allow_hash_like:  false,
        key_type:         nil
      }
    end

    include_examples 'should have reader', :options, -> { be == expected }

    context 'when initialized with allow_extra_keys: true' do
      let(:constructor_options) { super().merge(allow_extra_keys: true) }
      let(:expected)            { super().merge(allow_extra_keys: true) }

      it { expect(contract.options).to be == expected }
    end

    context 'when initialized with allow_hash_like: true' do
      let(:constructor_options) { super().merge(allow_hash_like: true) }
      let(:expected)            { super().merge(allow_hash_like: true) }

      it { expect(contract.options).to be == expected }
    end

    context 'when initialized with key_type: a class' do
      let(:constructor_options) { super().merge(key_type: String) }
      let(:expected) do
        super().merge(key_type: be_a_constraint(Stannum::Constraints::Type))
      end

      it { expect(contract.options).to deep_match expected }

      it 'should set the expected type' do
        expect(contract.options[:key_type].expected_type).to be String
      end
    end

    context 'when initialized with key_type: a constraint' do
      let(:key_type)            { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(key_type: key_type) }
      let(:expected) do
        super().merge(key_type: be_a_constraint(Stannum::Constraint))
      end

      it { expect(contract.options).to deep_match expected }

      it 'should set the options' do
        expect(contract.options[:key_type].options)
          .to be == key_type.options
      end
    end
  end

  describe '#with_options' do
    describe 'with allow_extra_keys: value' do
      let(:error_message) { "can't change option :allow_extra_keys" }

      it 'should raise an exception' do
        expect { contract.with_options(allow_extra_keys: true) }
          .to raise_error ArgumentError, error_message
      end
    end
  end
end
