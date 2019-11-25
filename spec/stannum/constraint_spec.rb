# frozen_string_literal: true

require 'stannum/constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraint do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new }

  let(:expected_errors) do
    Stannum::Errors.new.add(constraint.type)
  end
  let(:negated_errors) do
    Stannum::Errors.new.add(constraint.negated_type)
  end

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
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should not match', nil

  include_examples 'should match when negated', nil

  include_examples 'should not match', true

  include_examples 'should match when negated', true

  include_examples 'should not match', false

  include_examples 'should match when negated', false

  include_examples 'should not match', 0, as: 'an integer'

  include_examples 'should match when negated', 0, as: 'an integer'

  include_examples 'should not match', Object.new.freeze

  include_examples 'should match when negated', Object.new.freeze

  include_examples 'should not match', 'a string'

  include_examples 'should match when negated', 'a string'

  include_examples 'should not match', '', 'an empty string'

  include_examples 'should match when negated', '', 'an empty string'

  include_examples 'should not match', :a_symbol

  include_examples 'should match when negated', :a_symbol

  include_examples 'should not match', [], as: 'an empty array'

  include_examples 'should match when negated', [], as: 'an empty array'

  include_examples 'should not match', %w[a b c], as: 'an array'

  include_examples 'should match when negated', %w[a b c], as: 'an array'

  include_examples 'should not match', { a: 'a' }, as: 'a hash'

  include_examples 'should match when negated', { a: 'a' }, as: 'a hash'

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
    it 'should return an errors object' do
      expect(constraint.errors_for nil).to be_a Stannum::Errors
    end
  end

  describe '#match' do
    context 'when #matches? returns false' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(false)
      end

      include_examples 'should not match the value'
    end

    context 'when #matches? returns true' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:matches?)
          .and_return(true)
      end

      include_examples 'should match the value'
    end
  end

  describe '#negated_errors_for' do
    it 'should return an errors object' do
      expect(constraint.negated_errors_for nil).to be_a Stannum::Errors
    end

    it { expect(constraint.negated_errors_for nil).to be == negated_errors }
  end

  describe '#negated_match' do
    context 'when #does_not_match? returns false' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:does_not_match?)
          .and_return(false)
      end

      include_examples 'should not match the value', negated: true
    end

    context 'when #does_not_match? returns true' do
      let(:actual) { nil }

      before(:example) do
        allow(constraint) # rubocop:disable RSpec/SubjectStub
          .to receive(:does_not_match?)
          .and_return(true)
      end

      include_examples 'should match the value', negated: true
    end
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.valid'
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.invalid'
  end
end
