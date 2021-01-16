# frozen_string_literal: true

require 'stannum/constraints/union'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Union do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(*expected_constraints, **constructor_options)
  end

  let(:expected_constraints) do
    [
      Stannum::Constraints::Types::String.new,
      Stannum::Constraints::Types::Symbol.new
    ]
  end
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_constraints: expected_constraints } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_in_union'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_in_union'
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

  describe '#expected_constraints' do
    include_examples 'should have reader',
      :expected_constraints,
      -> { expected_constraints }
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_values) do
      expected_constraints.map do |constraint|
        {
          options: constraint.options,
          type:    constraint.type
        }
      end
    end
    let(:expected_errors) do
      {
        data: { constraints: expected_values },
        type: constraint.type
      }
    end

    context 'when the object does not match any of the constraints' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
    end

    context 'when the object matches one of the constraints' do
      let(:actual) { 'Greetings, programs!' }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_values) do
      expected_constraints.map do |constraint|
        {
          negated_type: constraint.negated_type,
          options:      constraint.options
        }
      end
    end
    let(:expected_errors) do
      {
        data: { constraints: expected_values },
        type: constraint.negated_type
      }
    end

    context 'when the object does not match any of the constraints' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    context 'when the object matches one of the constraints' do
      let(:actual) { 'Greetings, programs!' }

      include_examples 'should not match the constraint'
    end
  end
end
