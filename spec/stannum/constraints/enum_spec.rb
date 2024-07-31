# frozen_string_literal: true

require 'stannum/constraints/enum'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Enum do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(*expected_values, **constructor_options)
  end

  let(:expected_values)     { ['Alan Bradley', 'Kevin Flynn'] }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_values: } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_in_list'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_in_list'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_unlimited_arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_values' do
    include_examples 'should have reader',
      :expected_values,
      -> { expected_values }
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { values: expected_values },
        type: constraint.type
      }
    end
    let(:expected_messages) do
      expected_errors.merge(message: 'is not in the list')
    end

    context 'when the object is not an expected value' do
      let(:actual) { 'Ed Dillinger' }

      include_examples 'should not match the constraint'
    end

    context 'when the object is an expected value' do
      let(:actual) { 'Alan Bradley' }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { values: expected_values },
        type: constraint.negated_type
      }
    end
    let(:expected_messages) do
      expected_errors.merge(message: 'is in the list')
    end

    context 'when the object is not an expected value' do
      let(:actual) { 'Ed Dillinger' }

      include_examples 'should match the constraint'
    end

    context 'when the object is an expected value' do
      let(:actual) { 'Alan Bradley' }

      include_examples 'should not match the constraint'
    end
  end
end
