# frozen_string_literal: true

require 'stannum/constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraint do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:negated_type, :type)
        .and_any_keywords
        .and_a_block
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#match' do
    let(:match_method)      { :match }
    let(:expected_errors)   { { type: constraint.type } }
    let(:expected_messages) { expected_errors.merge(message: 'is invalid') }

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

    context 'when initialized with a block' do
      subject(:constraint) do
        described_class.new(**constructor_options, &constructor_block)
      end

      let(:constructor_block) { ->(actual) { actual.nil? } }

      describe 'with an object that does not match the block' do
        let(:actual) { Object.new.freeze }

        include_examples 'should not match the constraint'
      end

      describe 'with an object that matches the block' do
        let(:actual) { nil }

        include_examples 'should match the constraint'
      end
    end
  end

  describe '#negated_match' do
    let(:match_method)      { :negated_match }
    let(:expected_errors)   { { type: constraint.negated_type } }
    let(:expected_messages) { expected_errors.merge(message: 'is valid') }

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

    context 'when initialized with a block' do
      subject(:constraint) do
        described_class.new(**constructor_options, &constructor_block)
      end

      let(:constructor_block) { ->(actual) { actual.nil? } }

      describe 'with an object that does not match the block' do
        let(:actual) { Object.new.freeze }

        include_examples 'should match the constraint'
      end

      describe 'with an object that matches the block' do
        let(:actual) { nil }

        include_examples 'should not match the constraint'
      end
    end
  end
end
