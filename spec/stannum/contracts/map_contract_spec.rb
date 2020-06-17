# frozen_string_literal: true

require 'stannum/contracts/map_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'

RSpec.describe Stannum::Contracts::MapContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractBuilderExamples

  shared_context 'with a block with one property constraint' do
    let(:name_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.errors.a_string',
        type:         'spec.errors.not_a_string'
      ) \
      do |value|
        value.is_a?(String) && !value.empty?
      end
    end
    let(:block) do
      constraint = name_constraint

      -> { property :name, constraint }
    end
  end

  shared_context 'with a block with many property constraints' do
    let(:block) do
      lambda do
        property(:length) { |value| value.is_a?(Integer) }
        property(:name)   { |value| value.is_a?(String) }

        property(:manufacturer) do |value|
          value.is_a?(Spec::Manufacturer)
        end
      end
    end

    example_class 'Spec::Manufacturer'
  end

  subject(:constraint) { described_class.new(&block) }

  let(:block) { -> {} }

  describe '.new' do
    shared_context 'with a contract subclass' do
      let(:described_class) { Spec::CustomContract }

      # rubocop:disable RSpec/DescribedClass
      example_class 'Spec::CustomContract', Stannum::Contracts::MapContract
      # rubocop:enable RSpec/DescribedClass
    end

    it { expect(described_class).to be_constructible.with(0).arguments }

    describe 'without a block' do
      it 'should not add any constraints' do
        contract = described_class.new {}

        expect(contract.send :constraints).to be == []
      end
    end

    describe 'with an empty block' do
      let(:block) { -> {} }

      it 'should not add any constraints' do
        contract = described_class.new(&block)

        expect(contract.send :constraints).to be == []
      end
    end

    wrap_context 'with a block with one property constraint' do
      let(:expected) do
        [
          {
            constraint: name_constraint,
            property:   :name
          }
        ]
      end

      it 'should add the property constraint' do
        contract = described_class.new(&block)

        expect(contract.send :constraints).to be == expected
      end
    end

    wrap_context 'with a block with many property constraints' do
      let(:expected) do
        [
          {
            constraint: an_instance_of(Stannum::Constraint),
            property:   :length
          },
          {
            constraint: an_instance_of(Stannum::Constraint),
            property:   :manufacturer
          },
          {
            constraint: an_instance_of(Stannum::Constraint),
            property:   :name
          }
        ]
      end

      it 'should add the property constraints' do
        contract = described_class.new(&block)

        expect(contract.send :constraints).to contain_exactly(*expected)
      end
    end

    context 'when the class defines a custom .build_constraints method' do
      include_context 'with a contract subclass'

      let(:block) { -> {} }

      before(:example) do
        Spec::CustomContract.class_eval do
          attr_reader :constructor_block

          def build_constraints(block)
            @constructor_block = block
          end
        end
      end

      it 'should call the build_constraints method with the block' do
        expect(described_class.new(&block).constructor_block).to be block
      end
    end

    context 'when the class defines a custom Builder module' do
      include_context 'with a contract subclass'

      let(:constraint) { Stannum::Constraint.new }
      let(:block) do
        name_constraint = constraint

        -> { property :name, name_constraint }
      end
      let(:expected) { [[:name, constraint]] }

      example_class 'Spec::CustomContractBuilder' do |klass|
        klass.class_eval do
          def initialize(contract)
            @contract = contract
          end

          attr_reader :contract

          def property(*args)
            contract.properties << args
          end
        end
      end

      before(:example) do
        Spec::CustomContract.const_set(:Builder, Spec::CustomContractBuilder)

        Spec::CustomContract.send(:define_method, :properties) do
          @properties ||= []
        end
      end

      it 'should execute the block in the context of the builder' do
        contract = described_class.new(&block)

        expect(contract.properties).to be == expected
      end
    end
  end

  describe '::Builder' do
    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      # rubocop:disable RSpec/DescribedClass
      Stannum::Contracts::MapContract.new
      # rubocop:enable RSpec/DescribedClass
    end

    def resolve_constraint(constraint = nil, &block)
      builder.property(property_name, constraint, &block)

      contract
        .send(:constraints)
        .find { |hsh| hsh[:property] == property_name }
        .fetch(:constraint)
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
      let(:property_name) { :property_name }

      it 'should define the method' do
        expect(builder)
          .to respond_to(:property)
          .with(1..2).arguments
          .and_a_block
      end

      include_examples 'should resolve the constraint'

      describe 'with an invalid property name' do
        let(:property_name) { Object.new.freeze }
        let(:error_message) { "invalid property name #{property_name.inspect}" }

        it 'should raise an exception' do
          expect { builder.property(property_name) }
            .to raise_error ArgumentError, error_message
        end
      end

      context 'when the contract defines #valid_property?' do
        let(:constraint) { Stannum::Constraint.new }

        before(:example) do
          allow(contract).to receive(:valid_property?) do |property_name|
            property_name.is_a?(Symbol)
          end
        end

        include_examples 'should resolve the constraint'

        describe 'with an invalid property name' do
          let(:property_name) { 'property_name' }
          let(:error_message) do
            "invalid property name #{property_name.inspect}"
          end

          it 'should raise an exception' do
            expect { builder.property(property_name, constraint) }
              .to raise_error ArgumentError, error_message
          end
        end
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#valid_property?' do
    it { expect(constraint).not_to respond_to(:valid_property?) }

    it 'should define the private method' do
      expect(constraint).to respond_to(:valid_property?, true).with(1).argument
    end

    describe 'with nil' do
      it { expect(constraint.send :valid_property?, nil).to be false }
    end

    describe 'with false' do
      it { expect(constraint.send :valid_property?, false).to be false }
    end

    describe 'with true' do
      it { expect(constraint.send :valid_property?, true).to be false }
    end

    describe 'with an object' do
      let(:object) { Object.new.freeze }

      it { expect(constraint.send :valid_property?, object).to be false }
    end

    describe 'with an array' do
      let(:object) { [] }

      it { expect(constraint.send :valid_property?, object).to be false }
    end

    describe 'with a hash' do
      let(:object) { {} }

      it { expect(constraint.send :valid_property?, object).to be false }
    end

    describe 'with an empty string' do
      let(:object) { '' }

      it { expect(constraint.send :valid_property?, object).to be false }
    end

    describe 'with an empty symbol' do
      let(:object) { :'' }

      it { expect(constraint.send :valid_property?, object).to be false }
    end

    describe 'with a valid constant name string' do
      let(:object) { 'GREETINGS_PROGRAMS' }

      it { expect(constraint.send :valid_property?, object).to be true }
    end

    describe 'with a valid method name string' do
      let(:object) { 'greetings_programs' }

      it { expect(constraint.send :valid_property?, object).to be true }
    end

    describe 'with a valid module name string' do
      let(:object) { 'GreetingsPrograms' }

      it { expect(constraint.send :valid_property?, object).to be true }
    end

    describe 'with a valid constant name symbol' do
      let(:object) { :GREETINGS_PROGRAMS }

      it { expect(constraint.send :valid_property?, object).to be true }
    end

    describe 'with a valid method name symbol' do
      let(:object) { :greetings_programs }

      it { expect(constraint.send :valid_property?, object).to be true }
    end

    describe 'with a valid module name symbol' do
      let(:object) { :GreetingsPrograms }

      it { expect(constraint.send :valid_property?, object).to be true }
    end
  end

  context 'when the contract has no constraints' do
    include_examples 'should match', nil

    include_examples 'should match when negated', nil

    include_examples 'should match', true

    include_examples 'should match when negated', true

    include_examples 'should match', false

    include_examples 'should match when negated', false

    include_examples 'should match', 0, as: 'an integer'

    include_examples 'should match when negated', 0, as: 'an integer'

    include_examples 'should match', Object.new.freeze

    include_examples 'should match when negated', Object.new.freeze

    include_examples 'should match', '', as: 'an empty string'

    include_examples 'should match when negated', '', as: 'an empty string'

    include_examples 'should match', 'a string'

    include_examples 'should match when negated', 'a string'

    include_examples 'should match', :a_symbol

    include_examples 'should match when negated', :a_symbol

    include_examples 'should match', [], as: 'an empty array'

    include_examples 'should match when negated', [], as: 'an empty array'

    include_examples 'should match', %w[a b c], as: 'an array'

    include_examples 'should match when negated', %w[a b c], as: 'an array'

    include_examples 'should match', {}, as: 'an empty hash'

    include_examples 'should match when negated', {}, as: 'an empty hash'

    include_examples 'should match', { a: 'a' }, as: 'a hash'

    include_examples 'should match when negated', { a: 'a' }, as: 'a hash'
  end

  context 'when the contract has one property constraint' do
    include_context 'with a block with one property constraint'

    let(:expected_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    %i[name],
          type:    'spec.errors.not_a_string'
        }
      ]
    end
    let(:negated_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    %i[name],
          type:    'spec.errors.a_string'
        }
      ]
    end

    example_class 'Spec::Widget', Struct.new(:name)

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should not match',
      -> { Spec::Widget.new },
      as:         'a widget without a name',
      reversible: true

    include_examples 'should not match',
      -> { Spec::Widget.new('') },
      as:         'a widget with an empty name',
      reversible: true

    include_examples 'should match',
      -> { Spec::Widget.new('Self-sealing Stem Bolt') },
      as:         'a widget with a name',
      reversible: true
  end

  context 'when the contract has many property constraints' do
    include_context 'with a block with many property constraints'

    let(:actual) { nil }
    let(:expected_errors) do
      errors = []

      unless actual.respond_to?(:length) && actual.length.is_a?(Integer)
        errors << %i[length]
      end

      unless actual.respond_to?(:name) && actual.name.is_a?(String)
        errors << %i[name]
      end

      unless actual.respond_to?(:manufacturer) &&
             actual.manufacturer.is_a?(Spec::Manufacturer)
        errors << %i[manufacturer]
      end

      errors.map do |path|
        {
          data:    {},
          message: nil,
          path:    path,
          type:    Stannum::Constraints::Base::TYPE
        }
      end
    end
    let(:negated_errors) do
      errors = []

      if actual.respond_to?(:length) && actual.length.is_a?(Integer)
        errors << %i[length]
      end

      if actual.respond_to?(:name) && actual.name.is_a?(String)
        errors << %i[name]
      end

      if actual.respond_to?(:manufacturer) &&
         actual.manufacturer.is_a?(Spec::Manufacturer)
        errors << %i[manufacturer]
      end

      errors.map do |path|
        {
          data:    {},
          message: nil,
          path:    path,
          type:    Stannum::Constraints::Base::NEGATED_TYPE
        }
      end
    end
    let(:manufacturer) { Spec::Manufacturer.new }

    example_class 'Spec::Widget', Struct.new(:name, :length, :manufacturer)

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should not match',
      -> { Spec::Widget.new },
      as:         'a widget with incorrect properties',
      reversible: true

    include_examples 'should not match',
      -> { Spec::Widget.new(nil, 10, manufacturer) },
      as: 'a widget without a name'

    include_examples 'should not match when negated',
      -> { Spec::Widget.new(nil, 10, manufacturer) },
      as: 'a widget without a name'

    include_examples 'should not match',
      -> { Spec::Widget.new('Self-sealing Stem Bolt', nil, manufacturer) },
      as: 'a widget without a length'

    include_examples 'should not match when negated',
      -> { Spec::Widget.new('Self-sealing Stem Bolt', nil, manufacturer) },
      as: 'a widget without a length'

    include_examples 'should not match',
      -> { Spec::Widget.new('Self-sealing Stem Bolt', 10) },
      as: 'a widget without a manufacturer'

    include_examples 'should not match when negated',
      -> { Spec::Widget.new('Self-sealing Stem Bolt', 10) },
      as: 'a widget without a manufacturer'

    include_examples 'should match',
      -> { Spec::Widget.new('Self-sealing Stem Bolt', 10, manufacturer) },
      as:         'a widget with valid properties',
      reversible: true
  end
end
