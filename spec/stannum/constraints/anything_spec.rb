# frozen_string_literal: true

require 'stannum/constraints/anything'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Anything do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.anything'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:negated_type)
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#match' do
    let(:match_method) { :match }

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an empty String' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with a String' do
      let(:actual) { 'a string' }

      include_examples 'should match the constraint'
    end

    describe 'with an empty Symbol' do
      let(:actual) { :'' }

      include_examples 'should match the constraint'
    end

    describe 'with a Symbol' do
      let(:actual) { :a_symbol }

      include_examples 'should match the constraint'
    end

    describe 'with an empty Array' do
      let(:actual) { [] }

      include_examples 'should match the constraint'
    end

    describe 'with a Array' do
      let(:actual) { %w[a b c] }

      include_examples 'should match the constraint'
    end

    describe 'with an empty Hash' do
      let(:actual) { {} }

      include_examples 'should match the constraint'
    end

    describe 'with a Hash' do
      let(:actual) { { a: 1, b: 2, c: 3 } }

      include_examples 'should match the constraint'
    end
  end

  describe '#options' do
    let(:expected_options) do
      { negated_type: described_class::NEGATED_TYPE }
    end

    include_examples 'should have reader',
      :options,
      -> { be == expected_options }

    context 'when initialized with negated_type: value' do
      let(:negated_type)        { 'spec.negated_type' }
      let(:constructor_options) { super().merge(negated_type: negated_type) }
      let(:expected_options)    { super().merge(negated_type: negated_type) }

      it { expect(constraint.options).to be == expected_options }
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      { type: described_class::NEGATED_TYPE }
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty String' do
      let(:actual) { '' }

      include_examples 'should not match the constraint'
    end

    describe 'with a String' do
      let(:actual) { 'a string' }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty Symbol' do
      let(:actual) { :'' }

      include_examples 'should not match the constraint'
    end

    describe 'with a Symbol' do
      let(:actual) { :a_symbol }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty Array' do
      let(:actual) { [] }

      include_examples 'should not match the constraint'
    end

    describe 'with a Array' do
      let(:actual) { %w[a b c] }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty Hash' do
      let(:actual) { {} }

      include_examples 'should not match the constraint'
    end

    describe 'with a Hash' do
      let(:actual) { { a: 1, b: 2, c: 3 } }

      include_examples 'should not match the constraint'
    end

    context 'when initialized with negated_type: value' do
      let(:negated_type)        { 'spec.negated_type' }
      let(:constructor_options) { super().merge(negated_type: negated_type) }
      let(:expected_errors)     { { type: negated_type } }

      describe 'with nil' do
        let(:actual) { nil }

        include_examples 'should not match the constraint'
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

      describe 'with an Object' do
        let(:actual) { Object.new.freeze }

        include_examples 'should not match the constraint'
      end

      describe 'with an empty String' do
        let(:actual) { '' }

        include_examples 'should not match the constraint'
      end

      describe 'with a String' do
        let(:actual) { 'a string' }

        include_examples 'should not match the constraint'
      end

      describe 'with an empty Symbol' do
        let(:actual) { :'' }

        include_examples 'should not match the constraint'
      end

      describe 'with a Symbol' do
        let(:actual) { :a_symbol }

        include_examples 'should not match the constraint'
      end

      describe 'with an empty Array' do
        let(:actual) { [] }

        include_examples 'should not match the constraint'
      end

      describe 'with a Array' do
        let(:actual) { %w[a b c] }

        include_examples 'should not match the constraint'
      end

      describe 'with an empty Hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a Hash' do
        let(:actual) { { a: 1, b: 2, c: 3 } }

        include_examples 'should not match the constraint'
      end
    end
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.anything'

    context 'when initialized with negated_type: value' do
      let(:negated_type)        { 'spec.negated_type' }
      let(:constructor_options) { super().merge(negated_type: negated_type) }

      it { expect(constraint.negated_type).to be == negated_type }
    end
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.invalid'
  end
end
