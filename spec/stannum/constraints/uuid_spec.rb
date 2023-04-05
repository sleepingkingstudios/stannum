# frozen_string_literal: true

require 'stannum/constraints/uuid'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Uuid do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(**constructor_options)
  end

  let(:constructor_options) { {} }
  let(:expected_options) do
    { expected_format: described_class::UUID_FORMAT }
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_a_uuid'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_a_uuid'
  end

  describe '::UUID_FORMAT' do
    include_examples 'should define frozen constant',
      :UUID_FORMAT,
      -> { an_instance_of(Regexp) }

    describe 'when matched with an empty string' do
      it { expect(''.match? described_class::UUID_FORMAT).to be false }
    end

    describe 'when matched with string with invalid characters' do
      let(:string) { '00000000-0000-0000-0000-00000000000O' }

      it { expect(string.match? described_class::UUID_FORMAT).to be false }
    end

    describe 'when matched with a string with insufficient length' do
      let(:string) { '00000000-0000-0000-0000-00000000000' }

      it { expect(string.match? described_class::UUID_FORMAT).to be false }
    end

    describe 'when matched with a string with excessive length' do
      let(:string) { '00000000-0000-0000-0000-0000000000000' }

      it { expect(string.match? described_class::UUID_FORMAT).to be false }
    end

    describe 'when matched with a string with invalid format' do
      let(:string) { '000000000000-0000-0000-0000-00000000' }

      it { expect(string.match? described_class::UUID_FORMAT).to be false }
    end

    describe 'when matched with a lowercase UUID string' do
      let(:string) { '01234567-89ab-cdef-0123-456789abcdef' }

      it { expect(string.match? described_class::UUID_FORMAT).to be true }
    end

    describe 'when matched with an uppercase UUID string' do
      let(:string) { '01234567-89AB-CDEF-0123-456789ABCDEF' }

      it { expect(string.match? described_class::UUID_FORMAT).to be true }
    end
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
    let(:match_method)    { :match }
    let(:expected_errors) { { type: described_class::TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'is not a valid UUID')
    end

    describe 'with a non-string object' do
      let(:expected_errors) do
        {
          data: {
            required: true,
            type:     String
          },
          type: Stannum::Constraints::Type::TYPE
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'is not a String')
      end
      let(:actual) { :a_symbol }

      include_examples 'should not match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should not match the constraint'
    end

    describe 'with string with invalid characters' do
      let(:actual) { '00000000-0000-0000-0000-00000000000O' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string with insufficient length' do
      let(:actual) { '00000000-0000-0000-0000-00000000000' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string with excessive length' do
      let(:actual) { '00000000-0000-0000-0000-0000000000000' }

      include_examples 'should not match the constraint'
    end

    describe 'with a string with invalid format' do
      let(:actual) { '000000000000-0000-0000-0000-00000000' }

      include_examples 'should not match the constraint'
    end

    describe 'with a lowercase UUID string' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      include_examples 'should match the constraint'
    end

    describe 'with an uppercase UUID string' do
      let(:actual) { '01234567-89AB-CDEF-0123-456789ABCDEF' }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method)    { :negated_match }
    let(:expected_errors) { { type: described_class::NEGATED_TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'is a valid UUID')
    end

    describe 'with a non-string object' do
      let(:actual) { :a_symbol }

      include_examples 'should match the constraint'
    end

    describe 'with an empty string' do
      let(:actual) { '' }

      include_examples 'should match the constraint'
    end

    describe 'with string with invalid characters' do
      let(:actual) { '00000000-0000-0000-0000-00000000000O' }

      include_examples 'should match the constraint'
    end

    describe 'with a string with insufficient length' do
      let(:actual) { '00000000-0000-0000-0000-00000000000' }

      include_examples 'should match the constraint'
    end

    describe 'with a string with excessive length' do
      let(:actual) { '00000000-0000-0000-0000-0000000000000' }

      include_examples 'should match the constraint'
    end

    describe 'with a string with invalid format' do
      let(:actual) { '000000000000-0000-0000-0000-00000000' }

      include_examples 'should match the constraint'
    end

    describe 'with a lowercase UUID string' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      include_examples 'should not match the constraint'
    end

    describe 'with an uppercase UUID string' do
      let(:actual) { '01234567-89AB-CDEF-0123-456789ABCDEF' }

      include_examples 'should not match the constraint'
    end
  end
end
