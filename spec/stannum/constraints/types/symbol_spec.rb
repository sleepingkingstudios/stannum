# frozen_string_literal: true

require 'stannum/constraints/types/symbol'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::Symbol do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      Stannum::Constraints::Type::NEGATED_TYPE
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      Stannum::Constraints::Type::TYPE
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Symbol },
        type: constraint.type
      }
    end
    let(:matching) { :symbol }

    include_examples 'should match the type constraint'
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Symbol },
        type: constraint.negated_type
      }
    end
    let(:matching) { :symbol }

    include_examples 'should match the negated type constraint'
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      Stannum::Constraints::Type::NEGATED_TYPE
  end

  describe '#options' do
    let(:expected) { { expected_type: Symbol, required: true } }

    include_examples 'should have reader', :options, -> { be == expected }

    context 'when initialized with options' do
      subject(:constraint) { described_class.new(**options) }

      let(:options)  { { key: 'value' } }
      let(:expected) { super().merge(options) }

      it { expect(constraint.options).to be == expected }
    end
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      Stannum::Constraints::Type::TYPE
  end
end
