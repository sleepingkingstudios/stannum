# frozen_string_literal: true

require 'stannum/constraints/delegator'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Delegator do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(receiver) }

  let(:receiver) { Stannum::Constraints::Type.new(String) }

  describe '.new' do
    let(:error_message) { 'receiver must be a Stannum::Constraints::Base' }

    it 'should define the constructor' do
      expect(described_class).to be_constructible.with(1).argument
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { described_class.new(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { described_class.new(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#does_not_match?' do
    let(:actual) { Object.new.freeze }

    it { expect(constraint).to respond_to(:does_not_match?).with(1).argument }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:does_not_match?)

      constraint.does_not_match?(actual)

      expect(receiver).to have_received(:does_not_match?).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.does_not_match?(actual)).to be true }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.does_not_match?(actual)).to be false }
    end
  end

  describe '#errors_for' do
    let(:actual)   { Object.new.freeze }
    let(:expected) { receiver.errors_for(actual) }

    it { expect(constraint).to respond_to(:errors_for).with(1).argument }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:errors_for)

      constraint.errors_for(actual)

      expect(receiver).to have_received(:errors_for).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.errors_for(actual)).to be == expected }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.errors_for(actual)).to be == expected }
    end
  end

  describe '#match' do
    let(:actual)   { Object.new.freeze }
    let(:expected) { receiver.match(actual) }

    it { expect(constraint).to respond_to(:match).with(1).argument }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:match)

      constraint.match(actual)

      expect(receiver).to have_received(:match).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.match(actual)).to be == expected }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.match(actual)).to be == expected }
    end
  end

  describe '#matches?' do
    let(:actual) { Object.new.freeze }

    it { expect(constraint).to respond_to(:matches?).with(1).argument }

    it { expect(constraint).to have_aliased_method(:matches?).as(:match?) }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:matches?)

      constraint.matches?(actual)

      expect(receiver).to have_received(:matches?).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.matches?(actual)).to be false }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.matches?(actual)).to be true }
    end
  end

  describe '#negated_errors_for' do
    let(:actual)   { Object.new.freeze }
    let(:expected) { receiver.negated_errors_for(actual) }

    it 'should define the method' do
      expect(constraint).to respond_to(:negated_errors_for).with(1).argument
    end

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:negated_errors_for)

      constraint.negated_errors_for(actual)

      expect(receiver).to have_received(:negated_errors_for).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.negated_errors_for(actual)).to be == expected }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.negated_errors_for(actual)).to be == expected }
    end
  end

  describe '#negated_match' do
    let(:actual)   { Object.new.freeze }
    let(:expected) { receiver.negated_match(actual) }

    it { expect(constraint).to respond_to(:negated_match).with(1).argument }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:negated_match)

      constraint.negated_match(actual)

      expect(receiver).to have_received(:negated_match).with(actual)
    end

    describe 'with an object that does not match the receiver' do
      let(:actual) { nil }

      it { expect(constraint.negated_match(actual)).to be == expected }
    end

    describe 'with an object that matches the receiver' do
      let(:actual) { 'string' }

      it { expect(constraint.negated_match(actual)).to be == expected }
    end
  end

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      -> { receiver.negated_type }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:negated_type)

      constraint.negated_type

      expect(receiver).to have_received(:negated_type).with(no_args)
    end
  end

  describe '#options' do
    include_examples 'should define reader',
      :options,
      -> { receiver.options }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:options)

      constraint.options

      expect(receiver).to have_received(:options).with(no_args)
    end
  end

  describe '#receiver' do
    include_examples 'should define reader', :receiver, -> { receiver }
  end

  describe '#receiver=' do
    let(:error_message) { 'receiver must be a Stannum::Constraints::Base' }

    include_examples 'should define writer', :receiver=

    describe 'with nil' do
      it 'should raise an error' do
        expect { constraint.receiver = nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { constraint.receiver = Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint' do
      let(:value) { Stannum::Constraint.new }

      it 'should set the receiver' do
        expect { constraint.receiver = value }
          .to change(constraint, :receiver)
          .to be value
      end
    end
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      -> { receiver.type }

    it 'should delegate to #receiver' do
      allow(receiver).to receive(:type)

      constraint.type

      expect(receiver).to have_received(:type).with(no_args)
    end
  end
end
