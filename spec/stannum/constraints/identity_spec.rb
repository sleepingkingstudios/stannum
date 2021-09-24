# frozen_string_literal: true

require 'stannum/constraints/identity'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Identity do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(expected_value, **constructor_options)
  end

  let(:expected_value)      { 'a string' }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_value: expected_value } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_value'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_value'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_value' do
    include_examples 'should have reader',
      :expected_value,
      -> { expected_value }
  end

  describe '#match' do
    let(:match_method)    { :match }
    let(:expected_errors) { { type: constraint.type } }
    let(:expected_messages) do
      expected_errors.merge(message: 'is not the expected value')
    end

    describe 'with a non-matching object' do
      let(:actual) { :a_symbol }

      include_examples 'should not match the constraint'
    end

    describe 'with an equal object' do
      let(:actual) { +'a string' }

      include_examples 'should not match the constraint'
    end

    describe 'with the original object' do
      let(:actual) { expected_value }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { { type: constraint.negated_type } }
    let(:expected_messages) do
      expected_errors.merge(message: 'is the expected value')
    end

    describe 'with a non-matching object' do
      let(:actual) { :a_symbol }

      include_examples 'should match the constraint'
    end

    describe 'with an equal object' do
      let(:actual) { +'a string' }

      include_examples 'should match the constraint'
    end

    describe 'with the original object' do
      let(:actual) { expected_value }

      include_examples 'should not match the constraint'
    end
  end
end
