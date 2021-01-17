# frozen_string_literal: true

require 'stannum/constraints/types/hash_with_indifferent_keys'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::HashWithIndifferentKeys do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_empty:   true,
      expected_type: Hash,
      key_type:      be_a_constraint(
        Stannum::Constraints::Hashes::IndifferentKey
      ),
      required:      true,
      value_type:    nil
    }
  end

  describe '::INVALID_KEY_TYPE' do
    include_examples 'should define frozen constant',
      :INVALID_KEY_TYPE,
      Stannum::Constraints::Types::Hash::INVALID_KEY_TYPE
  end

  describe '::INVALID_VALUE_TYPE' do
    include_examples 'should define frozen constant',
      :INVALID_VALUE_TYPE,
      Stannum::Constraints::Types::Hash::INVALID_VALUE_TYPE
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
        .and_keywords(:value_type)
        .and_any_keywords
    end

    describe 'with value_type: an Object' do
      let(:error_message) do
        'value type must be a Class or Module or a constraint'
      end

      it 'should raise an error' do
        expect { described_class.new(value_type: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, ::Hash
  end

  describe '#key_type' do
    include_examples 'should have reader',
      :key_type,
      -> { be_a_constraint(Stannum::Constraints::Hashes::IndifferentKey) }
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: {
          allow_empty: constraint.allow_empty?,
          required:    constraint.required?,
          type:        Hash
        },
        type: constraint.type
      }
    end
    let(:matching) { {} }

    include_examples 'should match the type constraint'

    describe 'with an empty hash' do
      let(:actual) { {} }

      include_examples 'should match the constraint'
    end

    describe 'with a hash with non-matching keys' do
      let(:actual) { { 1 => 1, 2 => 2, 3 => 3 } }
      let(:expected_errors) do
        {
          data: { keys: actual.keys },
          type: described_class::INVALID_KEY_TYPE
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with a hash with mixed matching and non-matching keys' do
      let(:actual) { { :ichi => 1, 2 => 2, :san => 3 } }
      let(:expected_errors) do
        {
          data: { keys: [2] },
          type: described_class::INVALID_KEY_TYPE
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with a hash with matching keys' do
      let(:actual) { { ichi: 1, ni: 2, san: 3 } }

      include_examples 'should match the constraint'
    end

    context 'when allow_empty is false' do
      let(:constructor_options) { super().merge(allow_empty: false) }
      let(:expected_errors) do
        {
          data: {
            allow_empty: constraint.allow_empty?,
            required:    constraint.required?,
            type:        Hash
          },
          type: Stannum::Constraints::Presence::TYPE
        }
      end

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a non-empty hash' do
        let(:actual) { { 'ichi' => 1, 'ni' => 2, 'san' => 3 } }

        include_examples 'should match the constraint'
      end
    end

    context 'when the constraint is optional' do
      let(:constructor_options) { super().merge(required: false) }

      describe 'with nil' do
        let(:actual) { nil }

        include_examples 'should match the constraint'
      end
    end

    context 'when value_type is set' do
      let(:value_type)          { String }
      let(:constructor_options) { super().merge(value_type: value_type) }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with non-matching values' do
        let(:actual) { { ichi: 1, ni: 2, san: 3 } }
        let(:expected_errors) do
          [
            {
              data: { value: 1 },
              path: %i[ichi],
              type: described_class::INVALID_VALUE_TYPE
            },
            {
              data: { value: 2 },
              path: %i[ni],
              type: described_class::INVALID_VALUE_TYPE
            },
            {
              data: { value: 3 },
              path: %i[san],
              type: described_class::INVALID_VALUE_TYPE
            }
          ]
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with mixed matching and non-matching values' do
        let(:actual) { { ichi: '1', ni: 2, san: '3' } }
        let(:expected_errors) do
          {
            data: { value: 2 },
            path: %i[ni],
            type: described_class::INVALID_VALUE_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching values' do
        let(:actual) { { ichi: '1', ni: '2', san: '3' } }

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
          type:        Hash
        },
        type: constraint.negated_type
      }
    end
    let(:matching) { {} }

    include_examples 'should match the negated type constraint'

    describe 'with an empty hash' do
      let(:actual) { {} }

      include_examples 'should not match the constraint'
    end

    describe 'with a hash with non-matching keys' do
      let(:actual) { { 1 => 1, 2 => 2, 3 => 3 } }

      include_examples 'should not match the constraint'
    end

    describe 'with a hash with matching keys' do
      let(:actual) { { ichi: 1, ni: 2, san: 3 } }

      include_examples 'should not match the constraint'
    end

    context 'when allow_empty is false' do
      let(:constructor_options) { super().merge(allow_empty: false) }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a non-empty hash' do
        let(:actual) { { 'ichi' => 1, 'ni' => 2, 'san' => 3 } }

        include_examples 'should not match the constraint'
      end
    end

    context 'when the constraint is optional' do
      let(:constructor_options) { super().merge(required: false) }

      describe 'with nil' do
        let(:actual) { nil }

        include_examples 'should not match the constraint'
      end
    end

    context 'when value_type is set' do
      let(:value_type)          { String }
      let(:constructor_options) { super().merge(value_type: value_type) }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with non-matching values' do
        let(:actual) { { ichi: 1, ni: 2, san: 3 } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching values' do
        let(:actual) { { ichi: '1', ni: '2', san: '3' } }

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
        expected_type: Hash,
        key_type:      be_a_constraint(
          Stannum::Constraints::Hashes::IndifferentKey
        ),
        required:      true,
        value_type:    nil
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

    context 'when initialized with value_type: a Class' do
      let(:value_type)          { String }
      let(:constructor_options) { super().merge(value_type: value_type) }
      let(:expected) do
        super().merge(value_type: be_a_constraint(Stannum::Constraints::Type))
      end

      it { expect(constraint.options).to deep_match expected }

      it 'should set the expected type' do
        expect(constraint.options[:value_type].expected_type).to be value_type
      end
    end

    context 'when initialized with value_type: a constraint' do
      let(:value_type)          { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(value_type: value_type) }
      let(:expected) do
        super().merge(value_type: be_a_constraint(Stannum::Constraint))
      end

      it { expect(constraint.options).to deep_match expected }

      it 'should set the options' do
        expect(constraint.options[:value_type].options)
          .to be == value_type.options
      end
    end
  end

  describe '#value_type' do
    include_examples 'should have reader', :value_type, nil

    context 'when initialized with value_type: nil' do
      let(:constructor_options) { super().merge(value_type: nil) }

      it { expect(constraint.value_type).to be nil }
    end

    context 'when initialized with value_type: a Class' do
      let(:value_type)          { String }
      let(:constructor_options) { super().merge(value_type: value_type) }

      it { expect(constraint.value_type).to be_a Stannum::Constraints::Type }

      it { expect(constraint.value_type.expected_type).to be value_type }
    end

    context 'when initialized with value_type: a constraint' do
      let(:value_type)          { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(value_type: value_type) }

      it { expect(constraint.value_type).to be_a Stannum::Constraint }

      it { expect(constraint.value_type.options).to be == value_type.options }
    end
  end
end
