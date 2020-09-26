# frozen_string_literal: true

require 'stannum/constraints/presence'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Presence do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.present'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.absent'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
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

    describe 'with true' do
      let(:actual) { true }

      include_examples 'should match the constraint'
    end

    describe 'with false' do
      let(:actual) { false }

      include_examples 'should match the constraint'
    end

    describe 'with an integer' do
      let(:actual) { 0 }

      include_examples 'should match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string' do
      let(:actual) { 'string' }

      include_examples 'should match the constraint'
    end

    describe 'with an empty symbol' do
      let(:actual) { :'' }

      include_examples 'should not match the constraint'
    end

    describe 'with a symbol' do
      let(:actual) { :symbol }

      include_examples 'should match the constraint'
    end

    describe 'with an empty array' do
      let(:actual) { [] }

      include_examples 'should not match the constraint'
    end

    describe 'with an array' do
      let(:actual) { %w[a b c] }

      include_examples 'should match the constraint'
    end

    describe 'with an empty hash' do
      let(:actual) { {} }

      include_examples 'should not match the constraint'
    end

    describe 'with a hash' do
      let(:actual) { { a: 'a', b: 'b', c: 'c' } }

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

    describe 'with true' do
      let(:actual) { true }

      include_examples 'should not match the constraint'
    end

    describe 'with false' do
      let(:actual) { false }

      include_examples 'should not match the constraint'
    end

    describe 'with an integer' do
      let(:actual) { 0 }

      include_examples 'should not match the constraint'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with a string' do
      let(:actual) { 'string' }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty symbol' do
      let(:actual) { :'' }

      include_examples 'should match the constraint'
    end

    describe 'with a symbol' do
      let(:actual) { :symbol }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty array' do
      let(:actual) { [] }

      include_examples 'should match the constraint'
    end

    describe 'with an array' do
      let(:actual) { %w[a b c] }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty hash' do
      let(:actual) { {} }

      include_examples 'should match the constraint'
    end

    describe 'with a hash' do
      let(:actual) { { a: 'a', b: 'b', c: 'c' } }

      include_examples 'should not match the constraint'
    end
  end
end
