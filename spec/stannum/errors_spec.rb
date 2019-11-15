# frozen_string_literal: true

require 'stannum/errors'

RSpec.describe Stannum::Errors do
  shared_context 'when the errors has many root errors' do
    let(:raw_errors) do
      [
        { type: 'blank' },
        { type: 'invalid',  data: { key: 'value' } },
        { type: 'inverted', message: 'is upside down' }
      ]
    end
    let(:expected_errors) do
      raw_errors.map do |err|
        err
          .merge(data:    err[:data]    || {})
          .merge(message: err[:message] || nil)
      end
    end

    before(:example) do
      raw_errors.each do |data: {}, message: nil, type:|
        errors.add(type, message: message, **data)
      end
    end
  end

  shared_examples 'should determine the equality' do
    let(:other) { described_class.new }

    describe 'with nil' do
      it { expect(errors.send(method_name, nil)).to be false }
    end

    describe 'with an object' do
      it { expect(errors.send(method_name, Object.new.freeze)).to be false }
    end

    describe 'with an empty array' do
      it { expect(errors.send(method_name, other.to_a)).to be true }
    end

    describe 'with an empty errors object' do
      it { expect(errors.send(method_name, other)).to be true }
    end

    describe 'with an array with non-matching errors' do
      let(:other_errors) { %w[empty valid right_side_up] }

      before(:example) do
        other_errors.each { |type| other.add(type) }
      end

      it { expect(errors.send(method_name, other.to_a)).to be false }
    end

    describe 'with an errors object with non-matching errors' do
      let(:other_errors) { %w[empty valid right_side_up] }

      before(:example) do
        other_errors.each { |type| other.add(type) }
      end

      it { expect(errors.send(method_name, other)).to be false }
    end

    wrap_context 'when the errors has many root errors' do
      describe 'with nil' do
        it { expect(errors.send(method_name, nil)).to be false }
      end

      describe 'with an object' do
        it { expect(errors.send(method_name, Object.new.freeze)).to be false }
      end

      describe 'with an empty array' do
        it { expect(errors.send(method_name, [])).to be false }
      end

      describe 'with an empty errors object' do
        it { expect(errors.send(method_name, other)).to be false }
      end

      describe 'with an array with non-matching errors' do
        let(:other_errors) { %w[empty valid right_side_up] }

        before(:example) do
          other_errors.each { |type| other.add(type) }
        end

        it { expect(errors.send(method_name, other.to_a)).to be false }
      end

      describe 'with an errors object with non-matching errors' do
        let(:other_errors) { %w[empty valid right_side_up] }

        before(:example) do
          other_errors.each { |type| other.add(type) }
        end

        it { expect(errors.send(method_name, other)).to be false }
      end

      describe 'with an array with matching errors' do
        before(:example) do
          errors.each do |data:, message:, type:|
            other.add(type, message: message, **data)
          end
        end

        it { expect(errors.send(method_name, other.to_a)).to be true }
      end

      describe 'with an errors object with matching errors' do
        before(:example) do
          errors.each do |data:, message:, type:|
            other.add(type, message: message, **data)
          end
        end

        it { expect(errors.send(method_name, other)).to be true }
      end
    end
  end

  subject(:errors) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#==' do
    let(:method_name) { :== }

    include_examples 'should determine the equality'
  end

  describe '#add' do
    it 'should define the method' do
      expect(errors)
        .to respond_to(:add)
        .with(1).argument
        .and_keywords(:message)
        .and_any_keywords
    end

    def rescue_exception
      yield
    rescue StandardError # rubocop:disable Lint/HandleExceptions
    end

    describe 'with nil' do
      it 'should raise an exception' do
        expect { errors.add nil }
          .to raise_error ArgumentError, "error type can't be nil"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add nil } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { errors.add Object.new.freeze }
          .to raise_error ArgumentError, 'error type must be a String or Symbol'
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add Object.new.freeze } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an empty string' do
      it 'should raise an error' do
        expect { errors.add '' }
          .to raise_error ArgumentError, "error type can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add '' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with an empty symbol' do
      it 'should raise an error' do
        expect { errors.add :'' }
          .to raise_error ArgumentError, "error type can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add :'' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with a string' do
      let(:expected) { { data: {}, message: nil, type: 'some_error' } }

      it { expect(errors.add 'some_error').to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error' }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with a symbol' do
      let(:expected) { { data: {}, message: nil, type: 'some_error' } }

      it { expect(errors.add :some_error).to be errors }

      it 'should add the error' do
        expect { errors.add :some_error }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with message: nil' do
      let(:expected) { { data: {}, message: nil, type: 'some_error' } }

      it { expect(errors.add 'some_error', message: nil).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', message: nil }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with message: an object' do
      def add_error
        errors.add 'some_error', message: Object.new.freeze
      end

      it 'should raise an error' do
        expect { add_error }
          .to raise_error ArgumentError, 'message must be a String'
      end

      it 'should not add an error' do
        expect { rescue_exception { add_error } }.not_to change(errors, :to_a)
      end
    end

    describe 'with message: a symbol' do
      def add_error
        errors.add 'some_error', message: :some_message
      end

      it 'should raise an error' do
        expect { add_error }
          .to raise_error ArgumentError, 'message must be a String'
      end

      it 'should not add an error' do
        expect { rescue_exception { add_error } }.not_to change(errors, :to_a)
      end
    end

    describe 'with message: an empty string' do
      it 'should raise an error' do
        expect { errors.add 'some_error', message: '' }
          .to raise_error ArgumentError, "message can't be blank"
      end

      it 'should not add an error' do
        expect { rescue_exception { errors.add 'some_error', message: '' } }
          .not_to change(errors, :to_a)
      end
    end

    describe 'with message: a string' do
      let(:message)  { 'something went wrong' }
      let(:expected) { { data: {}, message: message, type: 'some_error' } }

      it { expect(errors.add 'some_error', message: message).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', message: message }
          .to change(errors, :to_a).to include expected
      end
    end

    describe 'with data' do
      let(:expected) do
        { data: { min: 0, max: 10 }, message: nil, type: 'some_error' }
      end

      it { expect(errors.add 'some_error', min: 0, max: 10).to be errors }

      it 'should add the error' do
        expect { errors.add 'some_error', min: 0, max: 10 }
          .to change(errors, :to_a).to include expected
      end
    end

    wrap_context 'when the errors has many root errors' do
      describe 'with a string' do
        let(:expected) { { data: {}, message: nil, type: 'some_error' } }

        it { expect(errors.add 'some_error').to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error' }
            .to change(errors, :to_a).to include expected
        end
      end

      describe 'with message: a string' do
        let(:message)  { 'something went wrong' }
        let(:expected) { { data: {}, message: message, type: 'some_error' } }

        it { expect(errors.add 'some_error', message: message).to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error', message: message }
            .to change(errors, :to_a).to include expected
        end
      end

      describe 'with data' do
        let(:expected) do
          { data: { min: 0, max: 10 }, message: nil, type: 'some_error' }
        end

        it { expect(errors.add 'some_error', min: 0, max: 10).to be errors }

        it 'should add the error' do
          expect { errors.add 'some_error', min: 0, max: 10 }
            .to change(errors, :to_a).to include expected
        end
      end
    end
  end

  describe '#each' do
    it { expect(errors).to respond_to(:each).with(0).arguments }

    describe 'with no arguments' do
      let(:enumerator) { errors.each }

      it { expect(errors.each).to be_a Enumerator }

      it { expect(enumerator.size).to be 0 }

      it 'should not yield control' do
        expect { |block| enumerator.each(&block) }.not_to yield_control
      end
    end

    describe 'with a block' do
      it 'should not yield control' do
        expect { |block| errors.each(&block) }.not_to yield_control
      end
    end

    wrap_context 'when the errors has many root errors' do
      it 'should yield each error' do
        yielded = []

        errors.each { |error| yielded << error }

        expect(yielded).to contain_exactly(*expected_errors)
      end
    end
  end

  describe '#empty?' do
    it { expect(errors).to respond_to(:empty?).with(0).arguments }

    it { expect(errors).to alias_method(:empty?).as(:blank?) }

    it { expect(errors.empty?).to be true }

    wrap_context 'when the errors has many root errors' do
      it { expect(errors.empty?).to be false }
    end
  end

  describe '#eql?' do
    let(:method_name) { :eql? }

    include_examples 'should determine the equality'
  end

  describe '#size' do
    it { expect(errors).to respond_to(:size).with(0).arguments }

    it { expect(errors).to alias_method(:size).as(:count) }

    it { expect(errors.size).to be 0 }

    wrap_context 'when the errors has many root errors' do
      it { expect(errors.size).to be expected_errors.size }
    end
  end

  describe '#to_a' do
    it { expect(errors).to respond_to(:to_a).with(0).arguments }

    it { expect(errors.to_a).to be == [] }

    wrap_context 'when the errors has many root errors' do
      it { expect(errors.to_a).to contain_exactly(*expected_errors) }
    end
  end
end
