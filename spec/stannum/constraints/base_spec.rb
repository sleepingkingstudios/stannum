# frozen_string_literal: true

require 'stannum/constraints/base'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Base do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

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

  describe '#negated_errors_for' do
    let(:negated_errors) do
      Stannum::Errors.new.add(constraint.negated_type)
    end

    it { expect(constraint.negated_errors_for nil).to be_a Stannum::Errors }

    it { expect(constraint.negated_errors_for nil).to be == negated_errors }
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
end
