# frozen_string_literal: true

require 'stannum/constraints/format'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Format do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(expected_format, **constructor_options)
  end

  shared_context 'when the expected format is a regular expression' do
    let(:expected_format) { /\AGreetings/ }
  end

  let(:expected_format)     { 'Greetings' }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_format: } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.matches_format'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.does_not_match_format'
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

  describe '#expected_format' do
    include_examples 'should have reader',
      :expected_format,
      -> { expected_format }

    wrap_context 'when the expected format is a regular expression' do
      it { expect(constraint.expected_format).to be expected_format }
    end
  end

  describe '#match' do
    let(:match_method)    { :match }
    let(:expected_errors) { { type: described_class::TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'does not match the expected format')
    end

    describe 'with a non-string object' do
      let(:expected_errors) do
        {
          data: {
            required: true,
            type:     String
          },
          type: Stannum::Constraints::Type::TYPE
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'is not a String')
      end
      let(:actual) { :a_symbol }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string that does not match the format' do
      let(:actual) { 'Hello, world!' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string that matches the format' do
      let(:actual) { 'Say "Greetings, programs!"' }

      include_examples 'should match the constraint'
    end

    wrap_context 'when the expected format is a regular expression' do
      describe 'with a non-string object' do
        let(:expected_errors) do
          {
            data: {
              required: true,
              type:     String
            },
            type: Stannum::Constraints::Type::TYPE
          }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is not a String')
        end
        let(:actual) { :a_symbol }

        include_examples 'should not match the constraint'
      end

      describe 'with an empty string' do
        let(:actual) { '' }

        include_examples 'should not match the constraint'
      end

      describe 'with a string that does not match the format' do
        let(:actual) { 'Say "Greetings, programs!"' }

        include_examples 'should not match the constraint'
      end

      describe 'with a string that matches the format' do
        let(:actual) { 'Greetings, starfighter!' }

        include_examples 'should match the constraint'
      end
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { { type: described_class::NEGATED_TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'matches the expected format')
    end

    describe 'with a non-string object' do
      let(:actual) { :a_symbol }

      include_examples 'should match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with a string that does not match the format' do
      let(:actual) { 'Hello, world!' }

      include_examples 'should match the constraint'
    end

    describe 'with a string that matches the format' do
      let(:actual) { 'Say "Greetings, programs!"' }

      include_examples 'should not match the constraint'
    end

    wrap_context 'when the expected format is a regular expression' do
      describe 'with a non-string object' do
        let(:actual) { :a_symbol }

        include_examples 'should match the constraint'
      end

      describe 'with an empty string' do
        let(:actual) { '' }

        include_examples 'should match the constraint'
      end

      describe 'with a string that does not match the format' do
        let(:actual) { 'Say "Greetings, programs!"' }

        include_examples 'should match the constraint'
      end

      describe 'with a string that matches the format' do
        let(:actual) { 'Greetings, starfighter!' }

        include_examples 'should not match the constraint'
      end
    end
  end
end
