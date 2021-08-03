# frozen_string_literal: true

require 'stannum/contracts/parameters_contract'

require 'support/examples/constraint_examples'
require 'support/examples/contract_builder_examples'
require 'support/examples/contract_examples'

RSpec.describe Stannum::Contracts::ParametersContract do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::ContractExamples

  shared_context 'when the contract has many argument constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { argument: 'name' }
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { argument: 'size' }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { argument: 'mass' }
        }
      ]
    end

    before(:example) do
      constraints.each do |definition|
        argument   = definition[:options][:argument]
        constraint = definition[:constraint]

        contract.add_argument_constraint(
          nil,
          constraint,
          property_name: argument
        )
      end
    end
  end

  shared_context 'when the contract has a variadic arguments constraint' do
    before(:example) do
      contract.set_arguments_item_constraint(:values, String)
    end
  end

  shared_context 'when the contract has many keyword constraints' do
    let(:constraints) do
      [
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { keyword: :payload }
        },
        {
          constraint: Stannum::Constraints::Presence.new,
          options:    { keyword: :propellant }
        },
        {
          constraint: Stannum::Constraints::Type.new(Integer),
          options:    { keyword: :fuel }
        }
      ]
    end

    before(:example) do
      constraints.each do |definition|
        keyword    = definition[:options][:keyword]
        constraint = definition[:constraint]

        contract.add_keyword_constraint(keyword, constraint)
      end
    end
  end

  shared_context 'when the contract has a variadic keywords constraint' do
    before(:example) do
      contract.set_keywords_value_constraint(:options, String)
    end
  end

  shared_context 'when the contract has a block constraint' do
    before(:example) { contract.set_block_constraint(true) }
  end

  subject(:contract) do
    described_class.new(**constructor_options, &constructor_block)
  end

  let(:constructor_block)   { -> {} }
  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_extra_keys: false,
      key_type:         nil,
      value_type:       nil
    }
  end

  describe '::Builder' do
    include Spec::Support::Examples::ContractBuilderExamples

    subject(:builder) { described_class.new(contract) }

    let(:described_class) { super()::Builder }
    let(:contract) do
      Stannum::Contracts::ParametersContract.new # rubocop:disable RSpec/DescribedClass
    end

    describe '.new' do
      it { expect(described_class).to be_constructible.with(1).argument }
    end

    describe '#argument' do
      let(:options) { {} }
      let(:name)    { :description }

      before(:example) do
        allow(contract).to receive(:add_argument_constraint)
      end

      it { expect(builder.argument name, String).to be builder }

      it 'should define the method' do
        expect(builder)
          .to respond_to(:argument)
          .with(1..2).arguments
          .and_any_keywords
          .and_a_block
      end

      describe 'with nil' do
        let(:error_message) do
          'invalid constraint nil'
        end

        it 'should raise an error' do
          expect { builder.argument(name, nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }
        let(:error_message) do
          "invalid constraint #{object.inspect}"
        end

        it 'should raise an error' do
          expect { builder.argument(name, object) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a block' do
        let(:implementation) { -> {} }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, &implementation)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(nil, an_instance_of(Stannum::Constraint), property_name: name)
        end

        it 'should pass the implementation' do
          allow(contract).to receive(:add_argument_constraint) \
          do |_index, constraint, _options|
            constraint.matches?(nil)
          end

          expect { |block| builder.argument(name, &block) }.to yield_control
        end
      end

      describe 'with a block and options' do
        let(:implementation) { -> {} }
        let(:options)        { { key: 'value' } }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, **options, &implementation)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(
              nil,
              an_instance_of(Stannum::Constraint),
              property_name: name,
              **options
            )
        end
      end

      describe 'with a block and a constraint' do
        let(:constraint)     { Stannum::Constraints::Type.new(String) }
        let(:implementation) { -> {} }
        let(:error_message) do
          'expected either a block or a constraint instance, but received' \
          " both a block and #{constraint.inspect}"
        end

        it 'should raise an error' do
          expect { builder.argument(name, constraint, &implementation) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a class' do
        let(:type) { String }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, type)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(nil, type, property_name: name)
        end
      end

      describe 'with a class and options' do
        let(:type)    { String }
        let(:options) { { key: 'value' } }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, type, **options)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(nil, type, property_name: name, **options)
        end
      end

      describe 'with a constraint' do
        let(:constraint) { Stannum::Constraints::Type.new(String) }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, constraint)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(nil, constraint, property_name: name)
        end
      end

      describe 'with a constraint and options' do
        let(:constraint) { Stannum::Constraints::Type.new(String) }
        let(:options)    { { key: 'value' } }

        it 'should delegate to #add_argument_constraint' do
          builder.argument(name, constraint, **options)

          expect(contract)
            .to have_received(:add_argument_constraint)
            .with(nil, constraint, property_name: name, **options)
        end
      end
    end

    describe '#arguments' do
      let(:name) { :args }
      let(:type) { String }

      before(:example) do
        allow(contract).to receive(:set_arguments_item_constraint)
      end

      it { expect(builder).to respond_to(:arguments).with(2).arguments }

      it 'should delegate to #set_arguments_item_constraint' do
        builder.arguments(name, type)

        expect(contract)
          .to have_received(:set_arguments_item_constraint)
          .with(name, type)
      end

      it { expect(builder.arguments(name, type)).to be builder }
    end

    describe '#block' do
      let(:present) { true }

      before(:example) do
        allow(contract).to receive(:set_block_constraint)
      end

      it { expect(builder).to respond_to(:block).with(1).argument }

      it 'should delegate to #set_block_constraint' do
        builder.block(present)

        expect(contract).to have_received(:set_block_constraint).with(present)
      end

      it { expect(builder.block(true)).to be builder }
    end

    describe '#contract' do
      include_examples 'should define reader',
        :contract,
        -> { contract }
    end

    describe '#keyword' do
      let(:options) { {} }
      let(:name)    { :format }

      before(:example) do
        allow(contract).to receive(:add_keyword_constraint)
      end

      it 'should define the method' do
        expect(builder)
          .to respond_to(:keyword)
          .with(1..2).arguments
          .and_any_keywords
          .and_a_block
      end

      it { expect(builder.keyword(name, String)).to be builder }

      describe 'with nil' do
        let(:error_message) do
          'invalid constraint nil'
        end

        it 'should raise an error' do
          expect { builder.keyword(name, nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }
        let(:error_message) do
          "invalid constraint #{object.inspect}"
        end

        it 'should raise an error' do
          expect { builder.keyword(name, object) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a block' do
        let(:implementation) { -> {} }
        let(:expected) do
          ary = [name, an_instance_of(Stannum::Constraint)]

          RUBY_VERSION < '2.7' ? ary << {} : ary
        end

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, &implementation)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(*expected)
        end

        it 'should pass the implementation' do
          allow(contract).to receive(:add_keyword_constraint) \
          do |_name, constraint, _options|
            constraint.matches?(nil)
          end

          expect { |block| builder.keyword(name, &block) }.to yield_control
        end
      end

      describe 'with a block and options' do
        let(:implementation) { -> {} }
        let(:options)        { { key: 'value' } }

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, **options, &implementation)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(
              name,
              an_instance_of(Stannum::Constraint),
              **options
            )
        end
      end

      describe 'with a block and a constraint' do
        let(:constraint)     { Stannum::Constraints::Type.new(String) }
        let(:implementation) { -> {} }
        let(:error_message) do
          'expected either a block or a constraint instance, but received' \
          " both a block and #{constraint.inspect}"
        end

        it 'should raise an error' do
          expect { builder.keyword(name, constraint, &implementation) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a class' do
        let(:type) { String }
        let(:expected) do
          ary = [name, type]

          RUBY_VERSION < '2.7' ? ary << {} : ary
        end

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, type)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(*expected)
        end
      end

      describe 'with a class and options' do
        let(:type)    { String }
        let(:options) { { key: 'value' } }

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, type, **options)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(name, type, **options)
        end
      end

      describe 'with a constraint' do
        let(:constraint) { Stannum::Constraints::Type.new(String) }
        let(:expected) do
          ary = [name, constraint]

          RUBY_VERSION < '2.7' ? ary << {} : ary
        end

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, constraint)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(*expected)
        end
      end

      describe 'with a constraint and options' do
        let(:constraint) { Stannum::Constraints::Type.new(String) }
        let(:options)    { { key: 'value' } }

        it 'should delegate to #add_keyword_constraint' do
          builder.keyword(name, constraint, **options)

          expect(contract)
            .to have_received(:add_keyword_constraint)
            .with(name, constraint, **options)
        end
      end
    end

    describe '#keywords' do
      let(:name) { :kwargs }
      let(:type) { String }

      before(:example) do
        allow(contract).to receive(:set_keywords_value_constraint)
      end

      it { expect(builder).to respond_to(:keywords).with(2).arguments }

      it 'should delegate to #set_keywords_value_constraint' do
        builder.keywords(name, type)

        expect(contract)
          .to have_received(:set_keywords_value_constraint)
          .with(name, type)
      end

      it { expect(builder.keywords(name, String)).to be builder }
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
      let(:constructor_block) do
        lambda do
          argument :name, String

          keyword :payload, String
        end
      end
      let(:builder) do
        instance_double(
          described_class::Builder,
          argument: nil,
          keyword:  nil
        )
      end

      before(:example) do
        allow(described_class::Builder).to receive(:new).and_return(builder)
      end

      it 'should call the builder with the block', :aggregate_failures do
        described_class.new(&constructor_block)

        expect(builder).to have_received(:argument).with(:name, String)
        expect(builder).to have_received(:keyword).with(:payload, String)
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Contract methods'

  describe '#add_argument_constraint' do
    let(:arguments_contract) { contract.send(:arguments_contract) }
    let(:expected) do
      ary = [nil, String]

      RUBY_VERSION < '2.7' ? ary << {} : ary
    end

    before(:example) do
      allow(arguments_contract).to receive(:add_argument_constraint)
    end

    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_argument_constraint)
        .with(2).arguments
        .and_any_keywords
    end

    it { expect(contract.add_argument_constraint(nil, String)).to be contract }

    it 'should delegate to the arguments contract' do
      contract.add_argument_constraint(nil, String)

      expect(arguments_contract)
        .to have_received(:add_argument_constraint)
        .with(*expected)
    end

    describe 'with options' do
      let(:options)  { { key: :value } }
      let(:expected) { [nil, String] }

      it 'should delegate to the arguments contract' do
        contract.add_argument_constraint(nil, String, **options)

        expect(arguments_contract)
          .to have_received(:add_argument_constraint)
          .with(*expected, **options)
      end
    end
  end

  describe '#add_keyword_constraint' do
    let(:keyword)           { :option }
    let(:keywords_contract) { contract.send(:keywords_contract) }
    let(:expected) do
      ary = [keyword, String]

      RUBY_VERSION < '2.7' ? ary << {} : ary
    end

    before(:example) do
      allow(keywords_contract).to receive(:add_keyword_constraint)
    end

    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_keyword_constraint)
        .with(2).arguments
        .and_any_keywords
    end

    it 'should return the contract' do
      expect(contract.add_keyword_constraint(keyword, String))
        .to be contract
    end

    it 'should delegate to the keywords_contract contract' do
      contract.add_keyword_constraint(keyword, String)

      expect(keywords_contract)
        .to have_received(:add_keyword_constraint)
        .with(*expected)
    end

    describe 'with options' do
      let(:options)  { { key: :value } }
      let(:expected) { [keyword, String] }

      it 'should delegate to the keywords contract' do
        contract.add_keyword_constraint(keyword, String, **options)

        expect(keywords_contract)
          .to have_received(:add_keyword_constraint)
          .with(*expected, **options)
      end
    end
  end

  describe '#arguments_contract' do
    let(:arguments_contract) { contract.send :arguments_contract }

    include_examples 'should have private reader',
      :arguments_contract,
      -> { be_a Stannum::Contracts::Parameters::ArgumentsContract }

    it { expect(arguments_contract.each_constraint.count).to be 2 }

    wrap_context 'when the contract has many argument constraints' do
      it { expect(arguments_contract.each_constraint.count).to be 5 }
    end
  end

  describe '#each_constraint' do
    let(:builtin_definitions) do
      [
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::SignatureContract
          ),
          contract:   contract,
          options:    { property: nil, sanity: true }
        ),
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::ArgumentsContract
          ),
          contract:   contract,
          options:    {
            property:      :arguments,
            property_type: :key,
            sanity:        false
          }
        ),
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::KeywordsContract
          ),
          contract:   contract,
          options:    {
            property:      :keywords,
            property_type: :key,
            sanity:        false
          }
        )
      ]
    end
    let(:expected) { builtin_definitions }

    it { expect(contract).to respond_to(:each_constraint).with(0).arguments }

    it { expect(contract.each_constraint).to be_a Enumerator }

    it { expect(contract.each_constraint.count).to be 3 }

    it 'should yield each definition' do
      expect { |block| contract.each_constraint(&block) }
        .to yield_successive_args(*expected)
    end

    wrap_context 'when the contract has a block constraint' do
      let(:block_definition) do
        be_a_constraint_definition(
          constraint: be_a_constraint(Stannum::Constraints::Types::ProcType),
          contract:   contract,
          options:    {
            property:      :block,
            property_type: :key,
            sanity:        false
          }
        )
      end
      let(:expected) { builtin_definitions + [block_definition] }

      it { expect(contract.each_constraint.count).to be 4 }

      it 'should yield each definition' do
        expect { |block| contract.each_constraint(&block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#each_pair' do
    let(:actual) do
      {
        arguments: %w[ichi ni san],
        keywords:  { foo: :bar },
        block:     -> {}
      }
    end
    let(:builtin_definitions) do
      [
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::SignatureContract
          ),
          contract:   contract,
          options:    { property: nil, sanity: true }
        ),
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::ArgumentsContract
          ),
          contract:   contract,
          options:    {
            property:      :arguments,
            property_type: :key,
            sanity:        false
          }
        ),
        be_a_constraint_definition(
          constraint: be_a_constraint(
            Stannum::Contracts::Parameters::KeywordsContract
          ),
          contract:   contract,
          options:    {
            property:      :keywords,
            property_type: :key,
            sanity:        false
          }
        )
      ]
    end
    let(:values)   { [actual, actual[:arguments], actual[:keywords]] }
    let(:expected) { builtin_definitions.zip(values) }

    it { expect(contract).to respond_to(:each_pair).with(1).argument }

    it { expect(contract.each_pair(actual)).to be_a Enumerator }

    it { expect(contract.each_pair(actual).count).to be 3 }

    it 'should yield each definition' do
      expect { |block| contract.each_pair(actual, &block) }
        .to yield_successive_args(*expected)
    end

    wrap_context 'when the contract has a block constraint' do
      let(:block_definition) do
        be_a_constraint_definition(
          constraint: be_a_constraint(Stannum::Constraints::Types::ProcType),
          contract:   contract,
          options:    {
            property:      :block,
            property_type: :key,
            sanity:        false
          }
        )
      end
      let(:values)   { super() + [actual[:block]] }
      let(:expected) { (builtin_definitions + [block_definition]).zip(values) }

      it { expect(contract.each_pair(actual).count).to be 4 }

      it 'should yield each definition' do
        expect { |block| contract.each_pair(actual, &block) }
          .to yield_successive_args(*expected)
      end
    end
  end

  describe '#keywords_contract' do
    let(:keywords_contract) { contract.send(:keywords_contract) }

    include_examples 'should have private reader',
      :keywords_contract,
      -> { be_a Stannum::Contracts::Parameters::KeywordsContract }

    it { expect(keywords_contract.each_constraint.count).to be 2 }

    wrap_context 'when the contract has many keyword constraints' do
      it { expect(keywords_contract.each_constraint.count).to be 5 }
    end
  end

  describe '#set_arguments_item_constraint' do
    let(:arguments_contract) { contract.send(:arguments_contract) }

    before(:example) do
      allow(arguments_contract).to(
        receive(:set_variadic_item_constraint)
        .and_wrap_original { |fn, type, options| fn.call(type, **options) }
      )
    end

    it 'should define the method' do
      expect(contract)
        .to respond_to(:set_arguments_item_constraint)
        .with(2).arguments
    end

    it 'should delegate to #set_variadic_item_constraint' do
      contract.set_arguments_item_constraint(:args, String)

      expect(arguments_contract)
        .to have_received(:set_variadic_item_constraint)
        .with(String, as: :args)
    end

    it 'should return the contract' do
      expect(contract.set_arguments_item_constraint(:args, String))
        .to be contract
    end

    wrap_context 'when the contract has a variadic arguments constraint' do
      let(:error_message) { 'variadic arguments constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_arguments_item_constraint(:args, String) }
          .to raise_error error_message
      end
    end
  end

  describe '#set_block_constraint' do
    it 'should define the method' do
      expect(contract).to respond_to(:set_block_constraint).with(1).argument
    end

    it 'should return the contract' do
      expect(contract.set_block_constraint(true)).to be contract
    end

    describe 'with nil' do
      let(:error_message) do
        'present must be true or false or a constraint'
      end

      it 'should raise an error' do
        expect { contract.set_block_constraint(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'present must be true or false or a constraint'
      end

      it 'should raise an error' do
        expect { contract.set_block_constraint(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with false' do
      it 'should add a constraint' do
        expect { contract.set_block_constraint(false) }
          .to(change { contract.each_constraint.to_a.size }.by(1))
      end

      it 'should set the block constraint', :aggregate_failures do
        contract.set_block_constraint(false)

        definition = contract.each_constraint.to_a.last

        expect(definition.constraint)
          .to be_a_constraint(Stannum::Constraints::Types::NilType)
        expect(definition.property).to be :block
        expect(definition.options[:property_type]).to be :key
      end
    end

    describe 'with true' do
      it 'should add a constraint' do
        expect { contract.set_block_constraint(true) }
          .to(change { contract.each_constraint.to_a.size }.by(1))
      end

      it 'should set the block constraint', :aggregate_failures do
        contract.set_block_constraint(true)

        definition = contract.each_constraint.to_a.last

        expect(definition.constraint)
          .to be_a_constraint(Stannum::Constraints::Types::ProcType)
          .with_options(expected_type: Proc, required: true)
        expect(definition.property).to be :block
        expect(definition.options[:property_type]).to be :key
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraint.new(type: 'spec.type') }

      it 'should add a constraint' do
        expect { contract.set_block_constraint(constraint) }
          .to(change { contract.each_constraint.to_a.size }.by(1))
      end

      it 'should set the block constraint', :aggregate_failures do
        contract.set_block_constraint(constraint)

        definition = contract.each_constraint.to_a.last

        expect(definition.constraint)
          .to be_a_constraint(Stannum::Constraint)
          .with_options(type: 'spec.type')
        expect(definition.property).to be :block
        expect(definition.options[:property_type]).to be :key
      end
    end

    wrap_context 'when the contract has a block constraint' do
      let(:error_message) { 'block constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_block_constraint(true) }
          .to raise_error error_message
      end
    end
  end

  describe '#set_keywords_value_constraint' do
    let(:keywords_contract) { contract.send(:keywords_contract) }

    before(:example) do
      allow(keywords_contract).to(
        receive(:set_variadic_value_constraint)
        .and_wrap_original { |fn, type, options| fn.call(type, **options) }
      )
    end

    it 'should define the method' do
      expect(contract)
        .to respond_to(:set_keywords_value_constraint)
        .with(2).arguments
    end

    it 'should delegate to #set_variadic_value_constraint' do
      contract.set_keywords_value_constraint(:kwargs, String)

      expect(keywords_contract)
        .to have_received(:set_variadic_value_constraint)
        .with(String, as: :kwargs)
    end

    it 'should return the contract' do
      expect(contract.set_keywords_value_constraint(:kwargs, String))
        .to be contract
    end

    wrap_context 'when the contract has a variadic keywords constraint' do
      let(:error_message) { 'variadic keywords constraint is already set' }

      it 'should raise an error' do
        expect { contract.set_keywords_value_constraint(:kwargs, String) }
          .to raise_error error_message
      end
    end
  end
end
