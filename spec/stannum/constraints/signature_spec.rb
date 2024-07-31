# frozen_string_literal: true

require 'stannum/constraints/signature'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Signature do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(*expected_methods, **constructor_options)
  end

  let(:expected_methods)    { %i[[] each size] }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_methods: } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.has_methods'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.does_not_have_methods'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_unlimited_arguments
        .and_any_keywords
    end

    describe 'with no arguments' do
      let(:error_message) { "expected methods can't be blank" }

      it 'should raise an error' do
        expect { described_class.new }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with nil' do
      let(:error_message) { 'expected method must be a String or Symbol' }

      it 'should raise an error' do
        expect { described_class.new nil }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with an Object' do
      let(:error_message) { 'expected method must be a String or Symbol' }

      it 'should raise an error' do
        expect { described_class.new Object.new.freeze }
          .to raise_error(ArgumentError, error_message)
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_methods' do
    include_examples 'should define reader',
      :expected_methods,
      -> { be == expected_methods }
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_messages) do
      expected_errors.merge(message: 'does not respond to the methods')
    end

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: expected_methods,
            methods: expected_methods
          }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to none of the methods' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: expected_methods,
            methods: expected_methods
          }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to some of the methods' do
      let(:actual) { Spec::Uncountable.new }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: %i[each size],
            methods: expected_methods
          }
        }
      end

      example_class 'Spec::Uncountable' do |klass|
        klass.define_method(:[]) { nil }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to all of the methods' do
      let(:actual) { [] }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_messages) do
      expected_errors.merge(message: 'responds to the methods')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an object that responds to none of the methods' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an object that responds to some of the methods' do
      let(:actual) { Spec::Uncountable.new }
      let(:expected_errors) do
        {
          type: described_class::NEGATED_TYPE,
          data: {
            missing: %i[each size],
            methods: expected_methods
          }
        }
      end

      example_class 'Spec::Uncountable' do |klass|
        klass.define_method(:[]) { nil }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to all of the methods' do
      let(:actual) { [] }
      let(:expected_errors) do
        {
          type: described_class::NEGATED_TYPE,
          data: {
            missing: %i[],
            methods: expected_methods
          }
        }
      end

      include_examples 'should not match the constraint'
    end
  end
end
