# frozen_string_literal: true

require 'stannum/constraints/types/array'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::Array do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      expected_type: Array,
      item_type:     nil,
      required:      true
    }
  end

  describe '::INVALID_ITEM_TYPE' do
    include_examples 'should define frozen constant',
      :INVALID_ITEM_TYPE,
      'stannum.constraints.types.array.invalid_item'
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      Stannum::Constraints::Type::NEGATED_TYPE
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      Stannum::Constraints::Type::TYPE
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:item_type)
        .and_any_keywords
    end

    describe 'with item_type: an Object' do
      let(:error_message) do
        'item type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { described_class.new(item_type: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, ::Array
  end

  describe '#item_type' do
    include_examples 'should have reader', :item_type, nil

    context 'when initialized with item_type: nil' do
      let(:constructor_options) { super().merge(item_type: nil) }

      it { expect(constraint.item_type).to be nil }
    end

    context 'when initialized with item_type: a Class' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type: item_type) }

      it { expect(constraint.item_type).to be_a Stannum::Constraints::Type }

      it { expect(constraint.item_type.expected_type).to be item_type }
    end

    context 'when initialized with item_type: a constraint' do
      let(:item_type)           { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(item_type: item_type) }

      it { expect(constraint.item_type).to be_a item_type.class }

      it { expect(constraint.item_type.options).to be == item_type.options }
    end
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Array },
        type: constraint.type
      }
    end
    let(:matching) { [] }

    include_examples 'should match the type constraint'

    context 'when item_type is set' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type: item_type) }

      describe 'with an empty array' do
        let(:actual) { [] }

        include_examples 'should match the constraint'
      end

      describe 'with an array with non-matching items' do
        let(:actual) { [1, 2, 3] }
        let(:expected_errors) do
          [
            {
              data: { value: actual[0] },
              path: [0],
              type: described_class::INVALID_ITEM_TYPE
            },
            {
              data: { value: actual[1] },
              path: [1],
              type: described_class::INVALID_ITEM_TYPE
            },
            {
              data: { value: actual[2] },
              path: [2],
              type: described_class::INVALID_ITEM_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an array with mixed matching and non-matching items' do
        let(:actual) { ['one', 2, 'three'] }
        let(:expected_errors) do
          {
            data: { value: actual[1] },
            path: [1],
            type: described_class::INVALID_ITEM_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an array with matching items' do
        let(:actual) { %w[one two three] }

        include_examples 'should match the constraint'
      end

      context 'when the constraint is optional' do
        let(:constructor_options) { super().merge(required: false) }

        describe 'with nil' do
          let(:actual) { nil }

          include_examples 'should match the constraint'
        end
      end
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Array },
        type: constraint.negated_type
      }
    end
    let(:matching) { [] }

    include_examples 'should match the negated type constraint'

    context 'when item_type is set' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type: item_type) }

      describe 'with an empty array' do
        let(:actual) { [] }

        include_examples 'should not match the constraint'
      end

      describe 'with an array with non-matching items' do
        let(:actual) { [1, 2, 3] }

        include_examples 'should not match the constraint'
      end

      describe 'with an array with mixed matching and non-matching items' do
        let(:actual) { ['one', 2, 'three'] }

        include_examples 'should not match the constraint'
      end

      describe 'with an array with matching items' do
        let(:actual) { %w[one two three] }

        include_examples 'should not match the constraint'
      end

      context 'when the constraint is optional' do
        let(:constructor_options) { super().merge(required: false) }

        describe 'with nil' do
          let(:actual) { nil }

          include_examples 'should not match the constraint'
        end
      end
    end
  end

  describe '#options' do
    let(:expected) do
      {
        expected_type: Array,
        item_type:     nil,
        required:      true
      }.merge(constructor_options)
    end

    context 'when initialized with item_type: a Class' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type: item_type) }
      let(:expected) do
        super().merge(item_type: be_a_constraint(Stannum::Constraints::Type))
      end

      it { expect(constraint.options).to deep_match expected }

      it 'should set the expected type' do
        expect(constraint.options[:item_type].expected_type).to be item_type
      end
    end

    context 'when initialized with item_type: a constraint' do
      let(:item_type)           { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(item_type: item_type) }
      let(:expected) do
        super().merge(item_type: be_a_constraint(Stannum::Constraint))
      end

      it { expect(constraint.options).to deep_match expected }

      it 'should set the options' do
        expect(constraint.options[:item_type].options)
          .to be == item_type.options
      end
    end
  end
end
