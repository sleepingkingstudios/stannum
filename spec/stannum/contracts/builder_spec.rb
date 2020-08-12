# frozen_string_literal: true

require 'stannum/contracts/builder'

RSpec.describe Stannum::Contracts::Builder do
  subject(:builder) { described_class.new(contract) }

  let(:contract) { Stannum::Contracts::Base.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
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

  describe '#contract' do
    include_examples 'should have reader', :contract, -> { contract }
  end

  describe '#valid_constraint?' do
    it 'should define the private method' do
      expect(builder).to respond_to(:valid_constraint?, true).with(1).argument
    end

    describe 'with nil' do
      it { expect(builder.send(:valid_constraint?, nil)).to be false }
    end

    describe 'with an Object' do
      let(:object) { Object.new.freeze }

      it { expect(builder.send(:valid_constraint?, object)).to be false }
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraints::Base.new }

      it { expect(builder.send(:valid_constraint?, constraint)).to be true }
    end
  end
end
