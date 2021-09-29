# frozen_string_literal: true

require 'stannum/constraints/types/big_decimal_type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::BigDecimalType do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_type: BigDecimal, required: true } }

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

  include_examples 'should implement the Constraint methods'

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, BigDecimal
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: BigDecimal },
        type: constraint.type
      }
    end
    let(:matching) { BigDecimal('0.0') }
    let(:expected_messages) do
      expected_errors.merge(message: 'is not a BigDecimal')
    end

    include_examples 'should match the type constraint'
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: BigDecimal },
        type: constraint.negated_type
      }
    end
    let(:matching) { BigDecimal('0.0') }
    let(:expected_messages) do
      expected_errors.merge(message: 'is a BigDecimal')
    end

    include_examples 'should match the negated type constraint'
  end
end
