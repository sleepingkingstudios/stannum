# frozen_string_literal: true

require 'stannum/constraints/types/hash'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::Hash do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::INVALID_KEY_TYPE' do
    include_examples 'should define frozen constant',
      :INVALID_KEY_TYPE,
      'stannum.constraints.types.hash.invalid_key'
  end

  describe '::INVALID_VALUE_TYPE' do
    include_examples 'should define frozen constant',
      :INVALID_VALUE_TYPE,
      'stannum.constraints.types.hash.invalid_value'
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
        .and_keywords(:key_type, :value_type)
        .and_any_keywords
    end

    describe 'with key_type: an Object' do
      let(:error_message) { 'key_type must be a Class or a constraint' }

      it 'should raise an error' do
        expect { described_class.new(key_type: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with value_type: an Object' do
      let(:error_message) { 'value_type must be a Class or a constraint' }

      it 'should raise an error' do
        expect { described_class.new(value_type: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#key_type' do
    include_examples 'should have reader', :key_type, nil

    context 'when initialized with key_type: nil' do
      let(:constructor_options) { super().merge(key_type: nil) }

      it { expect(constraint.key_type).to be nil }
    end

    context 'when initialized with key_type: a Class' do
      let(:key_type)            { String }
      let(:constructor_options) { super().merge(key_type: key_type) }

      it { expect(constraint.key_type).to be_a Stannum::Constraints::Type }

      it { expect(constraint.key_type.expected_type).to be key_type }
    end

    context 'when initialized with key_type: a constraint' do
      let(:key_type)            { Stannum::Constraint.new }
      let(:constructor_options) { super().merge(key_type: key_type) }

      it { expect(constraint.key_type).to be key_type }
    end
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Hash },
        type: constraint.type
      }
    end
    let(:matching) { {} }

    include_examples 'should match the type constraint'

    context 'when key_type is set' do
      let(:key_type)            { Symbol }
      let(:constructor_options) { super().merge(key_type: key_type) }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with non-matching keys' do
        let(:actual) { { 'ichi' => 1, 'ni' => 2, 'san' => 3 } }
        let(:expected_errors) do
          {
            data: { keys: actual.keys },
            type: described_class::INVALID_KEY_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with mixed matching and non-matching keys' do
        let(:actual) { { :ichi => 1, 'ni' => 2, :san => 3 } }
        let(:expected_errors) do
          {
            data: { keys: %w[ni] },
            type: described_class::INVALID_KEY_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { ichi: 1, ni: 2, san: 3 } }

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
          {
            data: { values: actual.values },
            type: described_class::INVALID_VALUE_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with mixed matching and non-matching values' do
        let(:actual) { { ichi: '1', ni: 2, san: '3' } }
        let(:expected_errors) do
          {
            data: { values: [2] },
            type: described_class::INVALID_VALUE_TYPE
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching values' do
        let(:actual) { { ichi: '1', ni: '2', san: '3' } }

        include_examples 'should match the constraint'
      end
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Hash },
        type: constraint.negated_type
      }
    end
    let(:matching) { {} }

    include_examples 'should match the negated type constraint'

    context 'when key_type is set' do
      let(:key_type)            { Symbol }
      let(:constructor_options) { super().merge(key_type: key_type) }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with non-matching keys' do
        let(:actual) { { 'ichi' => 1, 'ni' => 2, 'san' => 3 } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { ichi: 1, ni: 2, san: 3 } }

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
    end
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      Stannum::Constraints::Type::NEGATED_TYPE
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      Stannum::Constraints::Type::TYPE
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

      it { expect(constraint.value_type).to be value_type }
    end
  end
end