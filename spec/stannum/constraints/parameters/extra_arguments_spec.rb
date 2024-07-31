# frozen_string_literal: true

require 'stannum/constraints/parameters/extra_arguments'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Parameters::ExtraArguments do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(expected_count, **constructor_options)
  end

  let(:expected_count)      { 3 }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_count: } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.parameters.no_extra_arguments'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.parameters.extra_arguments'
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_count' do
    include_examples 'should have reader', :expected_count

    context 'when initialized with an integer' do
      let(:expected_count) { 3 }

      it { expect(constraint.expected_count).to be 3 }
    end

    context 'when initialized with a proc' do
      let(:expected_count) do
        count = 3

        -> { count }
      end

      it { expect(constraint.expected_count).to be 3 }
    end
  end

  describe '#match' do
    let(:match_method) { :match }

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            missing: %i[size],
            methods: %i[size]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            missing: %i[size],
            methods: %i[size]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    context 'when initialized with an integer' do
      let(:expected_count) { 3 }

      describe 'with an empty tuple' do
        let(:actual) { [] }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with one item' do
        let(:actual) { Array.new(1) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with the expected number of items' do
        let(:actual) { Array.new(3) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with too many items' do
        let(:actual) { Array.new(5) { |index| "item #{index}" } }
        let(:expected_errors) do
          [
            {
              data: { value: 'item 3' },
              path: [3],
              type: described_class::TYPE
            },
            {
              data: { value: 'item 4' },
              path: [4],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra arguments')
          end
        end

        include_examples 'should not match the constraint'
      end
    end

    context 'when initialized with a proc' do
      let(:expected_count) do
        count = 3

        -> { count }
      end

      describe 'with an empty tuple' do
        let(:actual) { [] }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with one item' do
        let(:actual) { Array.new(1) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with the expected number of items' do
        let(:actual) { Array.new(3) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end

      describe 'with a tuple with too many items' do
        let(:actual) { Array.new(5) { |index| "item #{index}" } }
        let(:expected_errors) do
          [
            {
              data: { value: 'item 3' },
              path: [3],
              type: described_class::TYPE
            },
            {
              data: { value: 'item 4' },
              path: [4],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra arguments')
          end
        end

        include_examples 'should not match the constraint'
      end
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { { type: described_class::NEGATED_TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'does not have extra arguments')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should not match the constraint'
    end

    context 'when initialized with an integer' do
      let(:expected_count) { 3 }

      describe 'with an empty tuple' do
        let(:actual) { [] }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with one item' do
        let(:actual) { Array.new(1) { |index| "item #{index}" } }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with the expected number of items' do
        let(:actual) { Array.new(3) { |index| "item #{index}" } }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with too many items' do
        let(:actual) { Array.new(5) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end
    end

    context 'when initialized with a proc' do
      let(:expected_count) do
        count = 3

        -> { count }
      end

      describe 'with an empty tuple' do
        let(:actual) { [] }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with one item' do
        let(:actual) { Array.new(1) { |index| "item #{index}" } }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with the expected number of items' do
        let(:actual) { Array.new(3) { |index| "item #{index}" } }

        include_examples 'should not match the constraint'
      end

      describe 'with a tuple with too many items' do
        let(:actual) { Array.new(5) { |index| "item #{index}" } }

        include_examples 'should match the constraint'
      end
    end
  end
end
