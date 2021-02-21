# frozen_string_literal: true

require 'stannum/errors'

require 'stannum/rspec/match_errors_matcher'

RSpec.describe Stannum::RSpec::MatchErrorsMatcher do
  subject(:matcher) { described_class.new(expected_errors) }

  let(:expected_errors) { Stannum::Errors.new }

  describe '::new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#description' do
    it { expect(matcher).to respond_to(:description).with(0).arguments }

    it { expect(matcher.description).to be == 'match the expected errors' }
  end

  describe '#does_not_match?' do
    shared_examples 'should set the failure message' do
      it 'should set the failure message' do
        matcher.does_not_match?(actual)

        expect(matcher.failure_message_when_negated).to be == failure_message
      end
    end

    let(:failure_message) do
      matcher =
        RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
        .new(expected_errors.to_a)

      matcher.does_not_match?(actual.to_a)

      matcher.failure_message_when_negated
    end

    it { expect(matcher).to respond_to(:does_not_match?).with(1).argument }

    describe 'with nil' do
      let(:actual) { nil }
      let(:failure_message) do
        'expected the errors not to match the expected errors, but the object' \
        ' is not an array or Errors object'
      end

      it { expect(matcher.does_not_match? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }
      let(:failure_message) do
        'expected the errors not to match the expected errors, but the object' \
        ' is not an array or Errors object'
      end

      it { expect(matcher.does_not_match? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an empty array' do
      let(:actual) { [] }

      it { expect(matcher.does_not_match? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an empty errors object' do
      let(:actual) { Stannum::Errors.new }

      it { expect(matcher.does_not_match? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an array with non-matching errors' do
      let(:actual) do
        errors = Stannum::Errors.new
        errors.add('spec.wrong_direction', message: 'not pointed towards space')
        errors[:payload].add('spec.not_installed', message: 'is not installed')
        errors[:engines][0]
          .add('spec.not_attached', message: 'is not attached')

        errors.to_a
      end

      it { expect(matcher.does_not_match? actual).to be true }
    end

    describe 'with an errors object with non-matching errors' do
      let(:actual) do
        errors = Stannum::Errors.new
        errors.add('spec.wrong_direction', message: 'not pointed towards space')
        errors[:payload].add('spec.not_installed', message: 'is not installed')
        errors[:engines][0]
          .add('spec.not_attached', message: 'is not attached')

        errors
      end

      it { expect(matcher.does_not_match? actual).to be true }
    end

    context 'when the expected errors has many errors' do
      let(:expected_errors) do
        errors = Stannum::Errors.new
        errors.add('spec.not_inspected', message: 'must be inspected')
        errors[:countdown].add('spec.not_finished', message: 'has not finished')
        errors[:fuel_tanks][0][:liquid_fuel]
          .add('spec.is_empty', message: 'is empty')

        errors
      end

      describe 'with nil' do
        let(:actual) { nil }
        let(:failure_message) do
          'expected the errors not to match the expected errors, but the' \
          ' object is not an array or Errors object'
        end

        it { expect(matcher.does_not_match? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an object' do
        let(:actual) { Object.new.freeze }
        let(:failure_message) do
          'expected the errors not to match the expected errors, but the' \
          ' object is not an array or Errors object'
        end

        it { expect(matcher.does_not_match? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an empty array' do
        let(:actual) { [] }

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an empty errors object' do
        let(:actual) { Stannum::Errors.new }

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an array with non-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add(
            'spec.wrong_direction',
            message: 'not pointed towards space'
          )
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:engines][0]
            .add('spec.not_attached', message: 'is not attached')

          errors.to_a
        end

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an errors object with non-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add(
            'spec.wrong_direction',
            message: 'not pointed towards space'
          )
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:engines][0]
            .add('spec.not_attached', message: 'is not attached')

          errors
        end

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an array with partially-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:fuel_tanks][0][:oxidizer]
            .add('spec.is_empty', message: 'is empty')

          errors.to_a
        end

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an errors object with partially-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:fuel_tanks][0][:oxidizer]
            .add('spec.is_empty', message: 'is empty')

          errors
        end

        it { expect(matcher.does_not_match? actual).to be true }
      end

      describe 'with an array with matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:countdown].add(
            'spec.not_finished',
            message: 'has not finished'
          )
          errors[:fuel_tanks][0][:liquid_fuel]
            .add('spec.is_empty', message: 'is empty')

          errors.to_a
        end

        it { expect(matcher.does_not_match? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an errors object with matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:countdown].add(
            'spec.not_finished',
            message: 'has not finished'
          )
          errors[:fuel_tanks][0][:liquid_fuel]
            .add('spec.is_empty', message: 'is empty')

          errors
        end

        it { expect(matcher.does_not_match? actual).to be false }

        include_examples 'should set the failure message'
      end
    end
  end

  describe '#failure_message' do
    it 'should define the method' do
      expect(matcher).to respond_to(:failure_message).with(0).arguments
    end
  end

  describe '#failure_message_when_negated' do
    it 'should define the method' do
      expect(matcher)
        .to respond_to(:failure_message_when_negated)
        .with(0).arguments
    end
  end

  describe '#matches?' do
    shared_examples 'should set the failure message' do
      it 'should set the failure message' do
        matcher.matches?(actual)

        expect(matcher.failure_message).to be == failure_message
      end
    end

    let(:failure_message) do
      matcher =
        RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
        .new(expected_errors.to_a)

      matcher.matches?(actual.to_a)

      matcher.failure_message
    end

    it { expect(matcher).to respond_to(:matches?).with(1).argument }

    describe 'with nil' do
      let(:actual) { nil }
      let(:failure_message) do
        'expected the errors to match the expected errors, but the object is' \
        ' not an array or Errors object'
      end

      it { expect(matcher.matches? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object' do
      let(:actual) { Object.new.freeze }
      let(:failure_message) do
        'expected the errors to match the expected errors, but the object is' \
        ' not an array or Errors object'
      end

      it { expect(matcher.matches? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an empty array' do
      let(:actual) { [] }

      it { expect(matcher.matches? actual).to be true }
    end

    describe 'with an empty errors object' do
      let(:actual) { Stannum::Errors.new }

      it { expect(matcher.matches? actual).to be true }
    end

    describe 'with an array with non-matching errors' do
      let(:actual) do
        errors = Stannum::Errors.new
        errors.add('spec.wrong_direction', message: 'not pointed towards space')
        errors[:payload].add('spec.not_installed', message: 'is not installed')
        errors[:engines][0]
          .add('spec.not_attached', message: 'is not attached')

        errors.to_a
      end

      it { expect(matcher.matches? actual).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an errors object with non-matching errors' do
      let(:actual) do
        errors = Stannum::Errors.new
        errors.add('spec.wrong_direction', message: 'not pointed towards space')
        errors[:payload].add('spec.not_installed', message: 'is not installed')
        errors[:engines][0]
          .add('spec.not_attached', message: 'is not attached')

        errors
      end

      it { expect(matcher.matches? actual).to be false }

      include_examples 'should set the failure message'
    end

    context 'when the expected errors has many errors' do
      let(:expected_errors) do
        errors = Stannum::Errors.new
        errors.add('spec.not_inspected', message: 'must be inspected')
        errors[:countdown].add('spec.not_finished', message: 'has not finished')
        errors[:fuel_tanks][0][:liquid_fuel]
          .add('spec.is_empty', message: 'is empty')

        errors
      end

      describe 'with nil' do
        let(:actual) { nil }
        let(:failure_message) do
          'expected the errors to match the expected errors, but the object' \
          ' is not an array or Errors object'
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an object' do
        let(:actual) { Object.new.freeze }
        let(:failure_message) do
          'expected the errors to match the expected errors, but the object' \
          ' is not an array or Errors object'
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an empty array' do
        let(:actual) { [] }

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an empty errors object' do
        let(:actual) { Stannum::Errors.new }

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an array with non-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add(
            'spec.wrong_direction',
            message: 'not pointed towards space'
          )
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:engines][0]
            .add('spec.not_attached', message: 'is not attached')

          errors.to_a
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an errors object with non-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add(
            'spec.wrong_direction',
            message: 'not pointed towards space'
          )
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:engines][0]
            .add('spec.not_attached', message: 'is not attached')

          errors
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an array with partially-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:fuel_tanks][0][:oxidizer]
            .add('spec.is_empty', message: 'is empty')

          errors.to_a
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an errors object with partially-matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:payload].add(
            'spec.not_installed',
            message: 'is not installed'
          )
          errors[:fuel_tanks][0][:oxidizer]
            .add('spec.is_empty', message: 'is empty')

          errors
        end

        it { expect(matcher.matches? actual).to be false }

        include_examples 'should set the failure message'
      end

      describe 'with an array with matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:countdown].add(
            'spec.not_finished',
            message: 'has not finished'
          )
          errors[:fuel_tanks][0][:liquid_fuel]
            .add('spec.is_empty', message: 'is empty')

          errors.to_a
        end

        it { expect(matcher.matches? actual).to be true }
      end

      describe 'with an errors object with matching errors' do
        let(:actual) do
          errors = Stannum::Errors.new
          errors.add('spec.not_inspected', message: 'must be inspected')
          errors[:countdown].add(
            'spec.not_finished',
            message: 'has not finished'
          )
          errors[:fuel_tanks][0][:liquid_fuel]
            .add('spec.is_empty', message: 'is empty')

          errors
        end

        it { expect(matcher.matches? actual).to be true }
      end
    end
  end
end
