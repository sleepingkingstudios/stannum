# frozen_string_literal: true

require 'stannum/constraints/hashes/indifferent_key'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Hashes::IndifferentKey do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { {} }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.hashes.is_string_or_symbol'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.hashes.is_not_string_or_symbol'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_messages) do
      expected_errors.merge(message: 'is not a String or a Symbol')
    end

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        { type: Stannum::Constraints::Presence::TYPE }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'is nil or empty')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        { type: described_class::TYPE }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an empty String' do
      let(:actual) { '' }
      let(:expected_errors) do
        { type: Stannum::Constraints::Presence::TYPE }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'is nil or empty')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with a String' do
      let(:actual) { 'a string' }

      include_examples 'should match the constraint'
    end

    describe 'with an empty Symbol' do
      let(:actual) { :'' }
      let(:expected_errors) do
        { type: Stannum::Constraints::Presence::TYPE }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'is nil or empty')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with a Symbol' do
      let(:actual) { :a_symbol }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      { type: described_class::NEGATED_TYPE }
    end
    let(:expected_messages) do
      expected_errors.merge(message: 'is a String or a Symbol')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an empty String' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with a String' do
      let(:actual) { 'a string' }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty Symbol' do
      let(:actual) { :'' }

      include_examples 'should match the constraint'
    end

    describe 'with a Symbol' do
      let(:actual) { :a_symbol }

      include_examples 'should not match the constraint'
    end
  end
end
