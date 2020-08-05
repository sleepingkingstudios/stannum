# frozen_string_literal: true

require 'stannum/contracts/definition'

RSpec.describe Stannum::Contracts::Definition do
  subject(:definition) { described_class.new(attributes) }

  let(:attributes) do
    {
      constraint: Stannum::Constraints::Base.new,
      contract:   Stannum::Contracts::Base.new,
      options:    { key: 'value' }
    }
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0..1).arguments }
  end

  describe '#==' do
    describe 'with nil' do
      it { expect(definition == nil).to be false } # rubocop:disable Style/NilComparison
    end

    describe 'with an Object' do
      it { expect(definition == Object.new.freeze).to be false }
    end

    describe 'with another definition with non-matching attributes' do
      let(:other) do
        described_class.new(
          constraint: definition.constraint,
          contract:   definition.contract,
          options:    { key: 'value', other: 'value' }
        )
      end

      it { expect(definition == other).to be false }
    end

    describe 'with another definition with matching attributes' do
      let(:other) do
        described_class.new(
          constraint: definition.constraint,
          contract:   definition.contract,
          options:    {}.merge(definition.options)
        )
      end

      it { expect(definition == other).to be true }
    end
  end

  describe '#constraint' do
    include_examples 'should have property',
      :constraint,
      -> { attributes[:constraint] }
  end

  describe '#contract' do
    include_examples 'should have property',
      :contract,
      -> { attributes[:contract] }
  end

  describe '#options' do
    include_examples 'should have property',
      :options,
      -> { attributes[:options] }
  end
end
