# frozen_string_literal: true

require 'stannum/constraints/base'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Base do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.valid'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.invalid'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  describe '#==' do
    describe 'with nil' do
      it { expect(constraint == nil).to be false } # rubocop:disable Style/NilComparison
    end

    describe 'with an Object' do
      it { expect(constraint == Object.new.freeze).to be false }
    end

    describe 'with a subclass instance' do
      it { expect(constraint == Class.new(described_class).new).to be false }
    end

    describe 'with a constraint instance with different options' do
      let(:other) { described_class.new(other_option: 'value') }

      it { expect(constraint == other).to be false }
    end

    describe 'with a constraint instance with identical options' do
      let(:other) { described_class.new(**constraint.options) }

      it { expect(constraint == other).to be true }
    end

    context 'when initialized with options' do
      let(:constructor_options) { super().merge(key: 'value') }

      describe 'with a constraint instance with different options' do
        let(:other) { described_class.new(other_option: 'value') }

        it { expect(constraint == other).to be false }
      end

      describe 'with a constraint instance with identical options' do
        let(:other) { described_class.new(**constraint.options) }

        it { expect(constraint == other).to be true }
      end
    end
  end

  describe '#does_not_match?' do
    context 'when #matches? returns false' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(false)
      end

      it { expect(constraint.does_not_match? actual).to be true }
    end

    context 'when #matches? returns true' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(true)
      end

      it { expect(constraint.does_not_match? actual).to be false }
    end
  end

  describe '#errors_for' do
    let(:expected_errors) do
      Stannum::Errors.new.add(constraint.type)
    end

    it { expect(constraint.errors_for nil).to be_a Stannum::Errors }

    it { expect(constraint.errors_for nil).to be == expected_errors }

    describe 'with errors: an errors object' do
      let(:errors)          { Stannum::Errors.new.add('spec.prior_error') }
      let(:expected_errors) { super().add('spec.prior_error') }

      it 'should add the errors to the given errors object' do
        expect(constraint.errors_for nil, errors:)
          .to be == expected_errors
      end
    end

    context 'when initialized with message: value' do
      let(:message) { 'is invalid' }
      let(:constructor_options) do
        super().merge(message:)
      end
      let(:expected_errors) do
        Stannum::Errors.new.add(constraint.type, message:)
      end

      it { expect(constraint.errors_for nil).to be == expected_errors }

      describe 'with errors: an errors object' do
        let(:errors)          { Stannum::Errors.new.add('spec.prior_error') }
        let(:expected_errors) { super().add('spec.prior_error') }

        it 'should add the errors to the given errors object' do
          expect(constraint.errors_for nil, errors:)
            .to be == expected_errors
        end
      end
    end
  end

  describe '#match' do
    let(:expected_errors) { { type: constraint.type } }
    let(:match_method)    { :match }

    context 'when #matches? returns false' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(false)
      end

      include_examples 'should not match the constraint'
    end

    context 'when #matches? returns true' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(true)
      end

      include_examples 'should match the constraint'
    end
  end

  describe '#matches?' do
    it { expect(constraint.matches? nil).to be false }
  end

  describe '#message' do
    include_examples 'should define reader', :message, -> { be nil }

    context 'when initialized with message: value' do
      let(:message) { 'is invalid' }
      let(:constructor_options) do
        super().merge(message:)
      end

      it { expect(constraint.message).to be == message }
    end
  end

  describe '#negated_errors_for' do
    let(:negated_errors) do
      Stannum::Errors.new.add(constraint.negated_type)
    end

    it { expect(constraint.negated_errors_for nil).to be_a Stannum::Errors }

    it { expect(constraint.negated_errors_for nil).to be == negated_errors }

    describe 'with errors: an errors object' do
      let(:errors)         { Stannum::Errors.new.add('spec.prior_error') }
      let(:negated_errors) { super().add('spec.prior_error') }

      it 'should add the errors to the given errors object' do
        expect(constraint.negated_errors_for nil, errors:)
          .to be == negated_errors
      end
    end

    context 'when initialized with message: value' do
      let(:negated_message) { 'is valid' }
      let(:constructor_options) do
        super().merge(negated_message:)
      end
      let(:negated_errors) do
        Stannum::Errors.new.add(
          constraint.negated_type,
          message: negated_message
        )
      end

      it { expect(constraint.negated_errors_for nil).to be == negated_errors }

      describe 'with errors: an errors object' do
        let(:errors)         { Stannum::Errors.new.add('spec.prior_error') }
        let(:negated_errors) { super().add('spec.prior_error') }

        it 'should add the errors to the given errors object' do
          expect(constraint.negated_errors_for nil, errors:)
            .to be == negated_errors
        end
      end
    end
  end

  describe '#negated_match' do
    let(:expected_errors) { { type: constraint.negated_type } }
    let(:match_method)    { :negated_match }

    context 'when #does_not_match? returns false' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:does_not_match?)
          .and_return(false)
      end

      include_examples 'should not match the constraint'
    end

    context 'when #does_not_match? returns true' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:does_not_match?)
          .and_return(true)
      end

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_message' do
    include_examples 'should define reader', :negated_message, -> { be nil }

    context 'when initialized with negated_message: value' do
      let(:negated_message) { 'is valid' }
      let(:constructor_options) do
        super().merge(negated_message:)
      end

      it { expect(constraint.negated_message).to be == negated_message }
    end
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      -> { be == described_class::NEGATED_TYPE }

    context 'when initialized with type: value' do
      let(:negated_type) { 'spec.custom_negated_type' }
      let(:constructor_options) do
        super().merge(negated_type:)
      end

      it { expect(constraint.negated_type).to be == negated_type }
    end
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      -> { be == described_class::TYPE }

    context 'when initialized with type: value' do
      let(:type) { 'spec.custom_type' }
      let(:constructor_options) do
        super().merge(type:)
      end

      it { expect(constraint.type).to be == type }
    end
  end
end
