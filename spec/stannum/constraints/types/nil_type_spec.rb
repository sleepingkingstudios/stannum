# frozen_string_literal: true

require 'stannum/constraints/types/nil_type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::NilType do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_type: NilClass, required: true } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.types.is_nil'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.types.is_not_nil'
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
    include_examples 'should have reader', :expected_type, NilClass
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: NilClass },
        type: constraint.type
      }
    end
    let(:expected_messages) do
      expected_errors.merge(message: 'is not nil')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should not match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: NilClass },
        type: constraint.negated_type
      }
    end
    let(:expected_messages) do
      expected_errors.merge(message: 'is nil')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end
  end
end
