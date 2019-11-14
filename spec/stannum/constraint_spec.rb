# frozen_string_literal: true

require 'stannum/constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraint do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new }

  let(:expected_errors) do
    Stannum::Errors.new.add(constraint.type)
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.invalid'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  include_examples 'should not match', nil

  include_examples 'should not match', true

  include_examples 'should not match', false

  include_examples 'should not match', 0, as: 'an integer'

  include_examples 'should not match', Object.new.freeze

  include_examples 'should not match', 'a string'

  include_examples 'should not match', :a_symbol

  describe '#errors_for' do
    it { expect(constraint).to respond_to(:errors_for).with(1).argument }

    it 'should return an errors object' do
      expect(constraint.errors_for nil).to be_a Stannum::Errors
    end
  end

  describe '#match' do
    it { expect(constraint).to respond_to(:match).with(1).argument }

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

  describe '#matches?' do
    it { expect(constraint).to respond_to(:matches?).with(1).argument }

    it { expect(constraint).to alias_method(:matches?).as(:match?) }
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.invalid'
  end
end
