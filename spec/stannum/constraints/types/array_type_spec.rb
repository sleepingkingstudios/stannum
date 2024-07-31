# frozen_string_literal: true

require 'stannum/constraints/types/array_type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::ArrayType do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_empty:   true,
      expected_type: Array,
      item_type:     nil,
      required:      true
    }
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
        .and_keywords(:allow_empty, :item_type)
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

  describe '#allow_empty?' do
    include_examples 'should define predicate', :allow_empty?, true

    context 'when initialized with allow_empty: false' do
      let(:constructor_options) { super().merge(allow_empty: false) }

      it { expect(constraint.allow_empty?).to be false }
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      it { expect(constraint.allow_empty?).to be true }
    end
  end

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, Array
  end

  describe '#item_type' do
    include_examples 'should have reader', :item_type, nil

    context 'when initialized with item_type: nil' do
      let(:constructor_options) { super().merge(item_type: nil) }

      it { expect(constraint.item_type).to be nil }
    end

    context 'when initialized with item_type: a Class' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type:) }

      it { expect(constraint.item_type).to be_a Stannum::Constraints::Type }

      it { expect(constraint.item_type.expected_type).to be item_type }
    end

    context 'when initialized with item_type: a constraint' do
      let(:item_type)           { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(item_type:) }

      it { expect(constraint.item_type).to be_a item_type.class }

      it { expect(constraint.item_type.options).to be == item_type.options }
    end
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: {
          allow_empty: constraint.allow_empty?,
          required:    constraint.required?,
          type:        Array
        },
        type: constraint.type
      }
    end
    let(:matching) { [] }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is not a Array'
        else
          'is not a Array or nil'
        end

      expected_errors.merge(message:)
    end

    include_examples 'should match the type constraint'

    context 'when allow_empty is false' do
      let(:constructor_options) { super().merge(allow_empty: false) }

      describe 'with an empty array' do
        let(:actual) { [] }
        let(:expected_errors) do
          {
            data: {
              allow_empty: constraint.allow_empty?,
              required:    constraint.required?,
              type:        Array
            },
            type: Stannum::Constraints::Presence::TYPE
          }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is nil or empty')
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a non-empty array' do
        let(:actual) { [1, 2, 3] }

        include_examples 'should match the constraint'
      end
    end

    context 'when item_type is set' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type:) }

      describe 'with an empty array' do
        let(:actual) { [] }

        include_examples 'should match the constraint'
      end

      describe 'with an array with non-matching items' do
        let(:actual) { [1, 2, 3] }
        let(:expected_errors) do
          [
            {
              data: { type: String, required: true },
              path: [0],
              type: Stannum::Constraints::Type::TYPE
            },
            {
              data: { type: String, required: true },
              path: [1],
              type: Stannum::Constraints::Type::TYPE
            },
            {
              data: { type: String, required: true },
              path: [2],
              type: Stannum::Constraints::Type::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'is not a String')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an array with mixed matching and non-matching items' do
        let(:actual) { ['one', 2, 'three'] }
        let(:expected_errors) do
          {
            data: { type: String, required: true },
            path: [1],
            type: Stannum::Constraints::Type::TYPE
          }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is not a String')
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
        data: {
          allow_empty: constraint.allow_empty?,
          required:    constraint.required?,
          type:        Array
        },
        type: constraint.negated_type
      }
    end
    let(:matching) { [] }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is a Array'
        else
          'is a Array or nil'
        end

      expected_errors.merge(message:)
    end

    include_examples 'should match the negated type constraint'

    context 'when allow_empty is false' do
      let(:constructor_options) { super().merge(allow_empty: false) }

      describe 'with an empty array' do
        let(:actual) { [] }

        include_examples 'should not match the constraint'
      end

      describe 'with a non-empty array' do
        let(:actual) { [1, 2, 3] }

        include_examples 'should not match the constraint'
      end
    end

    context 'when item_type is set' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type:) }

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
        allow_empty:   true,
        expected_type: Array,
        item_type:     nil,
        required:      true
      }.merge(constructor_options)
    end

    context 'when initialized with allow_empty: false' do
      let(:constructor_options) { super().merge(allow_empty: false) }
      let(:expected)            { super().merge(allow_empty: false) }

      it { expect(constraint.options).to deep_match expected }
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }
      let(:expected)            { super().merge(allow_empty: true) }

      it { expect(constraint.options).to deep_match expected }
    end

    context 'when initialized with item_type: a Class' do
      let(:item_type)           { String }
      let(:constructor_options) { super().merge(item_type:) }
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
      let(:constructor_options) { super().merge(item_type:) }
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
