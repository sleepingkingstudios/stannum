# frozen_string_literal: true

require 'stannum/constraints/type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Type do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(expected_type) }

  let(:expected_type) { String }
  let(:expected_errors) do
    Stannum::Errors.new.add(constraint.type, type: expected_type)
  end
  let(:negated_errors) do
    Stannum::Errors.new.add(constraint.negated_type, type: expected_type)
  end

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

    it { expect(described_class).to be_constructible.with(1).argument }

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

  describe '#options' do
    let(:expected) { { expected_type: expected_type } }

    include_examples 'should have reader', :options, -> { be == expected }
  end

  context 'when expected_type is a Class' do
    let(:expected_type) { StandardError }

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should match',
      StandardError.new,
      as:         'an instance of the class',
      reversible: true

    include_examples 'should match',
      RuntimeError.new,
      as:         'an instance of a subclass',
      reversible: true
  end

  context 'when expected_type is a Class name' do
    subject(:constraint) { described_class.new(expected_type.name) }

    let(:expected_type) { StandardError }

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should match',
      StandardError.new,
      as:         'an instance of the class',
      reversible: true

    include_examples 'should match',
      RuntimeError.new,
      as:         'an instance of a subclass',
      reversible: true
  end

  context 'when expected_type is a Module' do
    let(:expected_type) { Enumerable }

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should match',
      [],
      as:         'an instance of a class including the module',
      reversible: true

    include_examples 'should match',
      Object.new.extend(Enumerable).freeze,
      as:         'an object extending the module',
      reversible: true
  end

  context 'when expected_type is a Module name' do
    subject(:constraint) { described_class.new(expected_type.name) }

    let(:expected_type) { Enumerable }

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should match',
      [],
      as:         'an instance of a class including the module',
      reversible: true

    include_examples 'should match',
      Object.new.extend(Enumerable).freeze,
      as:         'an object extending the module',
      reversible: true
  end

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

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.is_type'
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.is_not_type'
  end
end
