# frozen_string_literal: true

require 'stannum/constraints/boolean'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Boolean do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(**constructor_options)
  end

  let(:constructor_options) { {} }
  let(:expected_options)    { {} }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_boolean'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_boolean'
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

  describe '#match' do
    let(:match_method)    { :match }
    let(:expected_errors) { { type: constraint.type } }

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new }

      include_examples 'should not match the constraint'
    end

    describe 'with true' do
      let(:actual) { true }

      include_examples 'should match the constraint'
    end

    describe 'with false' do
      let(:actual) { false }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { { type: constraint.negated_type } }

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new }

      include_examples 'should match the constraint'
    end

    describe 'with true' do
      let(:actual) { true }

      include_examples 'should not match the constraint'
    end

    describe 'with false' do
      let(:actual) { false }

      include_examples 'should not match the constraint'
    end
  end
end
