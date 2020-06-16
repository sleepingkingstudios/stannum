# frozen_string_literal: true

require 'stannum/contracts/builder'

RSpec.describe Stannum::Contracts::Builder do
  subject(:builder) { described_class.new(contract) }

  let(:contract) { Stannum::Contract.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#contract' do
    include_examples 'should have reader', :contract, -> { contract }
  end

  describe '#resolve_constraint' do
    it 'should define the private method' do
      expect(builder)
        .to respond_to(:resolve_constraint, true)
        .with(0..1).arguments
        .and_a_block
    end

    describe 'with a nil constraint' do
      let(:error_message) { 'invalid constraint nil' }

      it 'should raise an exception' do
        expect { builder.send(:resolve_constraint, nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an invalid constraint' do
      let(:constraint)    { Object.new.freeze }
      let(:error_message) { "invalid constraint #{constraint.inspect}" }

      it 'should raise an exception' do
        expect { builder.send(:resolve_constraint, constraint) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a valid constraint' do
      let(:constraint) { Stannum::Constraint.new }

      it 'should return the constraint' do
        expect(builder.send(:resolve_constraint, constraint))
          .to be constraint
      end
    end

    describe 'with a block' do
      let(:block)  { ->(actual) { actual.nil? } }
      let(:actual) { Object.new.freeze }

      it 'should return an anonymous constraint' do
        expect(builder.send(:resolve_constraint, &block))
          .to be_a Stannum::Constraint
      end

      it 'should yield the block to the constraint' do
        expect do |block|
          constraint = builder.send(:resolve_constraint, &block)

          constraint.match?(actual)
        end
          .to yield_with_args(actual)
      end

      describe 'with a block and a constraint' do
        let(:constraint) { Stannum::Constraint.new }
        let(:error_message) do
          'expected either a block or a constraint instance, but received' \
          " both a block and #{constraint.inspect}"
        end

        it 'should raise an exception' do
          expect { builder.send(:resolve_constraint, constraint, &block) }
            .to raise_error ArgumentError, error_message
        end
      end
    end
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
