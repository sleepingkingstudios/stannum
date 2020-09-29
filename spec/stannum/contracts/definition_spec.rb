# frozen_string_literal: true

require 'stannum/contracts/definition'

RSpec.describe Stannum::Contracts::Definition do
  subject(:definition) { described_class.new(attributes) }

  let(:options) { { key: 'value' } }
  let(:attributes) do
    {
      constraint: Stannum::Constraints::Base.new,
      contract:   Stannum::Contracts::Base.new,
      options:    options
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

  describe '#property' do
    include_examples 'should have reader', :property, nil

    context 'when property is a Array' do
      let(:property) { %i[factory gadget name] }
      let(:options)  { super().merge(property: property) }

      it { expect(definition.property).to be property }
    end

    context 'when property is a Symbol' do
      let(:property) { :name }
      let(:options)  { super().merge(property: property) }

      it { expect(definition.property).to be property }
    end
  end

  describe '#property_name' do
    include_examples 'should have reader', :property_name, nil

    context 'when property is a Array' do
      let(:property) { %i[factory gadget name] }
      let(:options)  { super().merge(property: property) }

      it { expect(definition.property_name).to be property }
    end

    context 'when property is a Symbol' do
      let(:property) { :name }
      let(:options)  { super().merge(property: property) }

      it { expect(definition.property_name).to be property }
    end

    context 'when property_name is a Array' do
      let(:property)      { :name }
      let(:property_name) { %i[factory gadget name] }
      let(:options) do
        super().merge(property: property, property_name: property_name)
      end

      it { expect(definition.property_name).to be property_name }
    end

    context 'when property_name is a Symbol' do
      let(:property)      { %i[factory gadget name] }
      let(:property_name) { :name }
      let(:options) do
        super().merge(property: property, property_name: property_name)
      end

      it { expect(definition.property_name).to be property_name }
    end
  end

  describe '#sanity?' do
    include_examples 'should define predicate', :sanity?, false

    context 'when options: sanity is false' do
      let(:options) { super().merge(sanity: false) }

      it { expect(definition.sanity?).to be false }
    end

    context 'when options: sanity is true' do
      let(:options) { super().merge(sanity: true) }

      it { expect(definition.sanity?).to be true }
    end
  end
end
