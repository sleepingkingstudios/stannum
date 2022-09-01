# frozen_string_literal: true

require 'stannum/constraints/presence'
require 'stannum/inverted_constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::InvertedConstraint do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(wrapped, **constructor_options)
  end

  let(:constructor_options) { {} }
  let(:wrapped_options)     { {} }
  let(:wrapped) do
    Stannum::Constraints::Presence.new(**wrapped_options)
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

  describe '#==' do
    describe 'with a constraint' do
      let(:other) { Stannum::Constraints::Base.new }

      it { expect(constraint == other).to be false }
    end

    describe 'with an inverted constraint with non-matching constraint' do
      let(:other) do
        described_class.new(Stannum::Constraints::Base.new)
      end

      it { expect(constraint == other).to be false }
    end

    describe 'with an inverted constraint with matching constraint' do
      let(:other) do
        described_class.new(
          Stannum::Constraints::Presence.new(**wrapped_options)
        )
      end

      it { expect(constraint == other).to be true }
    end
  end

  describe '#clone' do
    it { expect(constraint.clone.constraint).to be == wrapped }
  end

  describe '#constraint' do
    include_examples 'should define reader',
      :constraint,
      -> { be == wrapped }
  end

  describe '#does_not_match?' do
    describe 'with an object that does not match the constraint' do
      let(:actual) { '' }

      it { expect(constraint.does_not_match?(actual)).to be false }
    end

    describe 'with an object that matches the constraint' do
      let(:actual) { 'ok' }

      it { expect(constraint.does_not_match?(actual)).to be true }
    end
  end

  describe '#errors_for' do
    describe 'with an object that does not match the constraint' do
      let(:actual)   { '' }
      let(:expected) { wrapped.negated_errors_for(actual) }

      it { expect(constraint.errors_for(actual)).to be == expected }
    end

    describe 'with an object that matches the constraint' do
      let(:actual)   { 'ok' }
      let(:expected) { wrapped.negated_errors_for(actual) }

      it { expect(constraint.errors_for(actual)).to be == expected }
    end
  end

  describe '#match' do
    let(:match_method)    { :match }
    let(:expected_errors) { wrapped.negated_errors_for(actual).to_a }
    let(:expected_messages) do
      wrapped.negated_errors_for(actual).with_messages.to_a
    end

    describe 'with an object that does not match the constraint' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with an object that matches the constraint' do
      let(:actual) { 'ok' }

      include_examples 'should not match the constraint'
    end
  end

  describe '#matches?' do
    describe 'with an object that does not match the constraint' do
      let(:actual) { '' }

      it { expect(constraint.matches?(actual)).to be true }
    end

    describe 'with an object that matches the constraint' do
      let(:actual) { 'ok' }

      it { expect(constraint.matches?(actual)).to be false }
    end
  end

  describe '#message' do
    context 'when the wrapped constraint has a :negated_message option' do
      let(:wrapped_options) { super().merge(negated_message: 'is valid') }

      it { expect(constraint.message).to be == 'is valid' }
    end
  end

  describe '#negated_errors_for' do
    describe 'with an object that does not match the constraint' do
      let(:actual)   { '' }
      let(:expected) { wrapped.errors_for(actual) }

      it { expect(constraint.negated_errors_for(actual)).to be == expected }
    end

    describe 'with an object that matches the constraint' do
      let(:actual)   { 'ok' }
      let(:expected) { wrapped.errors_for(actual) }

      it { expect(constraint.negated_errors_for(actual)).to be == expected }
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { wrapped.errors_for(actual).to_a }
    let(:expected_messages) do
      wrapped.errors_for(actual).with_messages.to_a
    end

    describe 'with an object that does not match the constraint' do
      let(:actual) { '' }

      include_examples 'should not match the constraint'
    end

    describe 'with an object that matches the constraint' do
      let(:actual) { 'ok' }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_message' do
    context 'when the wrapped constraint has a :message option' do
      let(:wrapped_options) { super().merge(message: 'is invalid') }

      it { expect(constraint.negated_message).to be == 'is invalid' }
    end
  end

  describe '#negated_type' do
    context 'when the wrapped constraint has a :type option' do
      let(:wrapped_options) { super().merge(type: 'spec.type') }

      it { expect(constraint.negated_type).to be == 'spec.type' }
    end
  end

  describe '#options' do
    let(:expected) { {} }

    context 'when the wrapped constraint has a :message option' do
      let(:wrapped_options) { super().merge(message: 'is invalid') }
      let(:expected)        { super().merge(negated_message: 'is invalid') }

      it { expect(constraint.options).to be == expected }
    end

    context 'when the wrapped constraint has a :negated_message option' do
      let(:wrapped_options) { super().merge(negated_message: 'is valid') }
      let(:expected)        { super().merge(message: 'is valid') }

      it { expect(constraint.options).to be == expected }
    end

    context 'when the wrapped constraint has a :negated_type option' do
      let(:wrapped_options) { super().merge(negated_type: 'spec.negated_type') }
      let(:expected)        { super().merge(type: 'spec.negated_type') }

      it { expect(constraint.options).to be == expected }
    end

    context 'when the wrapped constraint has a :type option' do
      let(:wrapped_options) { super().merge(type: 'spec.type') }
      let(:expected)        { super().merge(negated_type: 'spec.type') }

      it { expect(constraint.options).to be == expected }
    end
  end

  describe '#type' do
    context 'when the wrapped constraint has a :negated_type option' do
      let(:wrapped_options) { super().merge(negated_type: 'spec.negated_type') }

      it { expect(constraint.type).to be == 'spec.negated_type' }
    end
  end

  describe '#with_options' do
    let(:options) { {} }
    let(:copy)    { subject.with_options(**options) }

    describe 'with message: value' do
      let(:options) { super().merge(message: 'is invalid') }

      it { expect(copy.constraint.negated_message).to be == 'is invalid' }
    end

    describe 'with negated_message: value' do
      let(:options) { super().merge(negated_message: 'is valid') }

      it { expect(copy.constraint.message).to be == 'is valid' }
    end

    describe 'with negated_type: value' do
      let(:options) { super().merge(negated_type: 'spec.negated_type') }

      it { expect(copy.constraint.type).to be == 'spec.negated_type' }
    end

    describe 'with type: value' do
      let(:options) { super().merge(type: 'spec.type') }

      it { expect(copy.constraint.negated_type).to be == 'spec.type' }
    end
  end
end
