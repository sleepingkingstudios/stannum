# frozen_string_literal: true

require 'stannum/constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraint do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**options) }

  let(:options) { {} }

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

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.valid'

    context 'when initialized with a negated type' do
      let(:negated_type) { 'spec.custom_negated_type' }
      let(:options)      { super().merge(negated_type: negated_type) }

      it { expect(constraint.negated_type).to be negated_type }
    end
  end

  describe '#options' do
    let(:expected) do
      {
        negated_type: Stannum::Constraints::Base::NEGATED_TYPE,
        type:         Stannum::Constraints::Base::TYPE
      }.merge(options)
    end

    include_examples 'should have reader', :options, -> { be == expected }

    context 'when initialized with a negated type' do
      let(:negated_type) { 'spec.custom_negated_type' }
      let(:options)      { super().merge(negated_type: negated_type) }

      it { expect(constraint.options).to be == expected }
    end

    context 'when initialized with a type' do
      let(:type)    { 'spec.custom_type' }
      let(:options) { super().merge(type: type) }

      it { expect(constraint.options).to be == expected }
    end

    context 'when initialized with options' do
      let(:options) do
        {
          language:  'Ada',
          log_level: 'panic',
          strict:    true
        }
      end

      it { expect(constraint.options).to be == expected }
    end
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.invalid'

    context 'when initialized with a type' do
      let(:type)    { 'spec.custom_type' }
      let(:options) { super().merge(type: type) }

      it { expect(constraint.type).to be type }
    end
  end

  context 'when initialized without a block' do
    let(:expected_errors) do
      Stannum::Errors.new.add(constraint.type)
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match', true, reversible: true

    include_examples 'should not match', false, reversible: true

    include_examples 'should not match',
      0,
      as:         'an integer',
      reversible: true

    include_examples 'should not match', Object.new.freeze, reversible: true

    include_examples 'should not match', 'a string', reversible: true

    include_examples 'should not match', '', 'an empty string', reversible: true

    include_examples 'should not match', :a_symbol, reversible: true

    include_examples 'should not match',
      [],
      as:         'an empty array',
      reversible: true

    include_examples 'should not match',
      %w[a b c],
      as:         'an array',
      reversible: true

    include_examples 'should not match',
      { a: 'a' },
      as:         'a hash',
      reversible: true

    context 'when initialized with a type' do
      let(:type)    { 'spec.custom_type' }
      let(:options) { super().merge(type: type) }

      include_examples 'should not match', nil, reversible: true
    end
  end

  context 'when initialized with a block' do
    subject(:constraint) { described_class.new(**options, &block) }

    let(:block) { ->(actual) { actual.nil? } }
    let(:expected_errors) do
      Stannum::Errors.new.add(constraint.type)
    end
    let(:negated_errors) do
      Stannum::Errors.new.add(constraint.negated_type)
    end

    include_examples 'should match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'a non-nil object',
      reversible: true

    context 'when initialized with a type' do
      let(:type)    { 'spec.custom_type' }
      let(:options) { super().merge(type: type) }

      include_examples 'should match', nil, reversible: true

      include_examples 'should not match',
        Object.new.freeze,
        as:         'a non-nil object',
        reversible: true
    end

    context 'when initialized with a negated type' do
      let(:negated_type) { 'spec.custom_negated_type' }
      let(:options)      { super().merge(negated_type: negated_type) }

      include_examples 'should match', nil, reversible: true

      include_examples 'should not match',
        Object.new.freeze,
        as:         'a non-nil object',
        reversible: true
    end
  end
end
