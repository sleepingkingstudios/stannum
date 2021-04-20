# frozen_string_literal: true

require 'stannum/constraints/type'

require 'support/examples/constraint_examples'
require 'support/examples/optional_examples'

RSpec.describe Stannum::Constraints::Type do
  include Spec::Support::Examples::ConstraintExamples
  include Spec::Support::Examples::OptionalExamples

  subject(:constraint) do
    described_class.new(expected_type, **constructor_options)
  end

  let(:expected_type)       { String }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_type: expected_type, required: true } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_type'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_type'
  end

  describe '.new' do
    let(:error_message) { 'expected type must be a Class or Module' }

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:optional, :required)
        .and_any_keywords
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { described_class.new nil }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { described_class.new Object.new.freeze }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with an invalid class name' do
      it 'should raise an error' do
        expect { described_class.new 'NotADefinedClass' }
          .to raise_error(NameError, 'uninitialized constant NotADefinedClass')
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  include_examples 'should implement the Optional interface'

  include_examples 'should implement the Optional methods'

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, -> { expected_type }

    context 'when expected_type is a Class' do
      let(:expected_type) { StandardError }

      it { expect(constraint.expected_type).to be expected_type }
    end

    context 'when expected_type is a Class name' do
      subject(:constraint) { described_class.new(expected_type.name) }

      let(:expected_type) { StandardError }

      it { expect(constraint.expected_type).to be expected_type }
    end

    context 'when expected_type is a Module' do
      let(:expected_type) { Enumerable }

      it { expect(constraint.expected_type).to be expected_type }
    end

    context 'when expected_type is a Module name' do
      subject(:constraint) { described_class.new(expected_type.name) }

      let(:expected_type) { Enumerable }

      it { expect(constraint.expected_type).to be expected_type }
    end
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: expected_type },
        type: constraint.type
      }
    end

    context 'when expected_type is a Class' do
      let(:expected_type) { StandardError }
      let(:matching)      { StandardError.new }

      include_examples 'should match the type constraint'
    end

    context 'when expected_type is a Class name' do
      subject(:constraint) do
        described_class.new(expected_type.name, **constructor_options)
      end

      let(:expected_type) { StandardError }
      let(:matching)      { StandardError.new }

      include_examples 'should match the type constraint'
    end

    context 'when expected_type is a Module' do
      let(:expected_type) { Enumerable }
      let(:matching)      { [] }

      include_examples 'should match the type constraint'
    end

    context 'when expected_type is a Module name' do
      subject(:constraint) do
        described_class.new(expected_type.name, **constructor_options)
      end

      let(:expected_type) { Enumerable }
      let(:matching)      { [] }

      include_examples 'should match the type constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: expected_type },
        type: constraint.negated_type
      }
    end

    context 'when expected_type is a Class' do
      let(:expected_type) { StandardError }
      let(:matching)      { StandardError.new }

      include_examples 'should match the negated type constraint'
    end

    context 'when expected_type is a Class name' do
      subject(:constraint) do
        described_class.new(expected_type.name, **constructor_options)
      end

      let(:expected_type) { StandardError }
      let(:matching)      { StandardError.new }

      include_examples 'should match the negated type constraint'
    end

    context 'when expected_type is a Module' do
      let(:expected_type) { Enumerable }
      let(:matching)      { [] }

      include_examples 'should match the negated type constraint'
    end

    context 'when expected_type is a Module name' do
      subject(:constraint) do
        described_class.new(expected_type.name, **constructor_options)
      end

      let(:expected_type) { Enumerable }
      let(:matching)      { [] }

      include_examples 'should match the negated type constraint'
    end
  end

  describe '#with_options' do
    let(:copy) { subject.with_options(**options) }

    describe 'with empty options' do
      let(:options) { {} }

      context 'when the constraint is optional' do
        let(:constructor_options) { { required: false } }

        it { expect(copy.options[:required]).to be false }
      end

      context 'when the constraint is required' do
        let(:constructor_options) { { required: true } }

        it { expect(copy.options[:required]).to be true }
      end
    end

    describe 'with key: value' do
      let(:options) { { key: :value } }

      context 'when the constraint is optional' do
        let(:constructor_options) { { required: false } }

        it { expect(copy.options[:required]).to be false }
      end

      context 'when the constraint is required' do
        let(:constructor_options) { { required: true } }

        it { expect(copy.options[:required]).to be true }
      end
    end

    describe 'with optional: false' do
      let(:options) { { optional: false } }

      it { expect(copy.options[:required]).to be true }
    end

    describe 'with optional: true' do
      let(:options) { { optional: true } }

      it { expect(copy.options[:required]).to be false }
    end

    describe 'with required: false' do
      let(:options) { { required: false } }

      it { expect(copy.options[:required]).to be false }
    end

    describe 'with required: true' do
      let(:options) { { required: true } }

      it { expect(copy.options[:required]).to be true }
    end
  end
end
