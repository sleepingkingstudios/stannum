# frozen_string_literal: true

require 'stannum/constraints/hashes/extra_keys'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Hashes::ExtraKeys do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(expected_keys, **constructor_options)
  end

  let(:expected_keys)       { %i[foo bar baz] }
  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_keys: Set.new(expected_keys) } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.hashes.no_extra_keys'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.hashes.extra_keys'
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_any_keywords
    end

    describe 'with expected_keys: nil' do
      let(:error_message) { 'expected_keys must be an Array or a Proc' }

      it 'should raise an error' do
        expect { described_class.new nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with expected_keys: an Array with invalid items' do
      let(:error_message) { 'key must be a String or Symbol' }

      it 'should raise an error' do
        expect { described_class.new([nil]) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_keys' do
    include_examples 'should have reader', :expected_keys

    context 'when initialized with an array' do
      let(:expected_keys) { %i[foo bar baz] }

      it { expect(constraint.expected_keys).to be_a Set }

      it { expect(constraint.expected_keys.to_a).to be == expected_keys }
    end

    context 'when initialized with a proc' do
      let(:expected_keys) do
        keys = %i[foo bar baz]

        -> { keys }
      end

      it { expect(constraint.expected_keys).to be_a Set }

      it { expect(constraint.expected_keys.to_a).to be == %i[foo bar baz] }
    end
  end

  describe '#match' do
    let(:match_method) { :match }

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            missing: %i[keys],
            methods: %i[keys]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            missing: %i[keys],
            methods: %i[keys]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    context 'when initialized with an array' do
      let(:expected_keys) { %i[foo bar baz] }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with extra keys' do
        let(:actual) { { wibble: 'wibble', wobble: 'wobble' } }
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            },
            {
              data: { value: 'wobble' },
              path: %i[wobble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with missing keys' do
        let(:actual) { { foo: 'foo' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with missing and extra keys' do
        let(:actual) { { foo: 'foo', wibble: 'wibble' } }
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { foo: 'foo', bar: 'bar', baz: 'baz' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with matching keys and extra keys' do
        let(:actual) do
          {
            foo:    'foo',
            bar:    'bar',
            baz:    'baz',
            wibble: 'wibble',
            wobble: 'wobble'
          }
        end
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            },
            {
              data: { value: 'wobble' },
              path: %i[wobble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end
    end

    context 'when initialized with a proc' do
      let(:expected_keys) do
        keys = %i[foo bar baz]

        -> { keys }
      end

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with extra keys' do
        let(:actual) { { wibble: 'wibble', wobble: 'wobble' } }
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            },
            {
              data: { value: 'wobble' },
              path: %i[wobble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with missing keys' do
        let(:actual) { { foo: 'foo' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with missing and extra keys' do
        let(:actual) { { foo: 'foo', wibble: 'wibble' } }
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { foo: 'foo', bar: 'bar', baz: 'baz' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with matching keys and extra keys' do
        let(:actual) do
          {
            foo:    'foo',
            bar:    'bar',
            baz:    'baz',
            wibble: 'wibble',
            wobble: 'wobble'
          }
        end
        let(:expected_errors) do
          [
            {
              data: { value: 'wibble' },
              path: %i[wibble],
              type: described_class::TYPE
            },
            {
              data: { value: 'wobble' },
              path: %i[wobble],
              type: described_class::TYPE
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'has extra keys')
          end
        end

        include_examples 'should not match the constraint'
      end
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) { { type: described_class::NEGATED_TYPE } }
    let(:expected_messages) do
      expected_errors.merge(message: 'does not have extra keys')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should not match the constraint'
    end

    context 'when initialized with an array' do
      let(:expected_keys) { %i[foo bar baz] }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with extra keys' do
        let(:actual) { { wibble: 'wibble', wobble: 'wobble' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with missing keys' do
        let(:actual) { { foo: 'foo' } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with missing and extra keys' do
        let(:actual) { { foo: 'foo', wibble: 'wibble' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { foo: 'foo', bar: 'bar', baz: 'baz' } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys and extra keys' do
        let(:actual) do
          {
            foo:    'foo',
            bar:    'bar',
            baz:    'baz',
            wibble: 'wibble',
            wobble: 'wobble'
          }
        end

        include_examples 'should match the constraint'
      end
    end

    context 'when initialized with a proc' do
      let(:expected_keys) do
        keys = %i[foo bar baz]

        -> { keys }
      end
      let(:expected_errors) { { type: described_class::NEGATED_TYPE } }

      describe 'with an empty hash' do
        let(:actual) { {} }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with extra keys' do
        let(:actual) { { wibble: 'wibble', wobble: 'wobble' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with missing keys' do
        let(:actual) { { foo: 'foo' } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with missing and extra keys' do
        let(:actual) { { foo: 'foo', wibble: 'wibble' } }

        include_examples 'should match the constraint'
      end

      describe 'with a hash with matching keys' do
        let(:actual) { { foo: 'foo', bar: 'bar', baz: 'baz' } }

        include_examples 'should not match the constraint'
      end

      describe 'with a hash with matching keys and extra keys' do
        let(:actual) do
          {
            foo:    'foo',
            bar:    'bar',
            baz:    'baz',
            wibble: 'wibble',
            wobble: 'wobble'
          }
        end

        include_examples 'should match the constraint'
      end
    end
  end
end
