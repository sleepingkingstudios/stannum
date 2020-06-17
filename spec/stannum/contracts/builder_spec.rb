# frozen_string_literal: true

require 'stannum/contracts/builder'

require 'support/examples/contract_builder_examples'

RSpec.describe Stannum::Contracts::Builder do
  include Spec::Support::Examples::ContractBuilderExamples

  subject(:builder) { described_class.new(contract) }

  let(:contract) { Stannum::Contract.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#contract' do
    include_examples 'should have reader', :contract, -> { contract }
  end

  describe '#resolve_constraint' do
    def resolve_constraint(constraint = nil, &block)
      builder.send(:resolve_constraint, constraint, &block)
    end

    it 'should define the private method' do
      expect(builder)
        .to respond_to(:resolve_constraint, true)
        .with(0..1).arguments
        .and_a_block
    end

    include_examples 'should resolve the constraint'
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
