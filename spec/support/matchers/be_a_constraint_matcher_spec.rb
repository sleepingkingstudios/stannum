# frozen_string_literal: true

require 'spec_helper'

require 'rspec/sleeping_king_studios/examples/rspec_matcher_examples'

require 'support/matchers/be_a_constraint_matcher'

RSpec.describe Spec::Support::Matchers::BeAConstraintMatcher do
  include RSpec::SleepingKingStudios::Examples::RSpecMatcherExamples

  shared_context 'when the expected constraint is a Class' do
    let(:expected_constraint) { Spec::ExampleConstraint }

    example_class 'Spec::ExampleConstraint', Stannum::Constraints::Base
  end

  shared_context 'when the expected constraint is a matcher' do
    let(:expected_constraint) { be_a(Spec::ExampleConstraint) }

    example_class 'Spec::ExampleConstraint', Stannum::Constraints::Base
  end

  shared_context 'when there are expected options' do
    subject(:matcher) do
      described_class.new(expected_constraint).with_options(**expected_options)
    end

    let(:expected_options) do
      {
        language:  'Ada',
        log_level: 'panic',
        strict:    true
      }
    end
  end

  subject(:matcher) { described_class.new(expected_constraint) }

  let(:expected_constraint) { nil }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0..1).arguments }
  end

  describe '#description' do
    let(:expected) { 'be a constraint' }

    it { expect(matcher).to respond_to(:description).with(0).arguments }

    it { expect(matcher.description).to be == expected }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the expected constraint is a Class' do
      let(:expected) { 'be a Spec::ExampleConstraint' }

      it { expect(matcher.description).to be == expected }

      wrap_context 'when there are expected options' do
        let(:expected) do
          %(#{super()} with options language: "Ada", log_level: "panic") \
            ', strict: true'
        end

        it { expect(matcher.description).to be == expected }
      end
    end

    wrap_context 'when the expected constraint is a matcher' do
      let(:expected) { 'be a Spec::ExampleConstraint' }

      it { expect(matcher.description).to be == expected }

      wrap_context 'when there are expected options' do
        let(:expected) do
          %(#{super()} with options language: "Ada", log_level: "panic") \
            ', strict: true'
        end

        it { expect(matcher.description).to be == expected }
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody

    wrap_context 'when there are expected options' do
      let(:expected) do
        %(#{super()} with options language: "Ada", log_level: "panic") \
          ', strict: true'
      end

      it { expect(matcher.description).to be == expected }
    end
  end

  describe '#does_not_match?' do
    let(:failure_message_when_negated) do
      "expected #{actual.inspect} not to be a constraint"
    end

    it { expect(matcher).to respond_to(:does_not_match?).with(1).argument }

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should pass with a negative expectation'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      include_examples 'should pass with a negative expectation'
    end

    describe 'with a constraint' do
      let(:actual) { Stannum::Constraint.new }

      include_examples 'should fail with a negative expectation'
    end

    wrap_context 'when the expected constraint is a Class' do
      let(:failure_message_when_negated) do
        "expected #{actual.inspect} not to be a #{expected_constraint.name}"
      end

      describe 'with a constraint that does not match the expected constraint' \
      do
        let(:actual) { Stannum::Constraint.new }

        include_examples 'should pass with a negative expectation'
      end

      describe 'with a constraint that matches the expected constraint' do
        let(:actual) { Spec::ExampleConstraint.new }

        include_examples 'should fail with a negative expectation'
      end

      wrap_context 'when there are expected options' do
        let(:actual) { Stannum::Constraint.new }
        let(:error_message) do
          '`expect().not_to be_a_constraint().with_options()` is not supported'
        end

        it 'should raise an error' do
          expect { matcher.does_not_match?(actual) }
            .to raise_error StandardError, error_message
        end
      end
    end

    wrap_context 'when the expected constraint is a matcher' do
      let(:failure_message_when_negated) do
        "expected #{actual.inspect} not to #{expected_constraint.description}"
      end

      describe 'with a constraint that does not match the expected constraint' \
      do
        let(:actual) { Stannum::Constraint.new }

        include_examples 'should pass with a negative expectation'
      end

      describe 'with a constraint that matches the expected constraint' do
        let(:actual) { Spec::ExampleConstraint.new }

        include_examples 'should fail with a negative expectation'
      end

      wrap_context 'when there are expected options' do
        let(:actual) { Stannum::Constraint.new }
        let(:error_message) do
          '`expect().not_to be_a_constraint().with_options()` is not supported'
        end

        it 'should raise an error' do
          expect { matcher.does_not_match?(actual) }
            .to raise_error StandardError, error_message
        end
      end
    end

    wrap_context 'when there are expected options' do
      let(:actual) { Stannum::Constraint.new }
      let(:error_message) do
        '`expect().not_to be_a_constraint().with_options()` is not supported'
      end

      it 'should raise an error' do
        expect { matcher.does_not_match?(actual) }
          .to raise_error StandardError, error_message
      end
    end
  end

  describe '#expected' do
    include_examples 'should have reader', :expected, nil

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when the expected constraint is a Class' do
      it { expect(matcher.expected).to be expected_constraint }
    end

    wrap_context 'when the expected constraint is a matcher' do
      it { expect(matcher.expected).to be expected_constraint }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#expected_options' do
    include_examples 'should have reader',
      :expected_options,
      -> { be == {} }

    wrap_context 'when there are expected options' do
      it { expect(matcher.expected_options).to be == expected_options }
    end
  end

  describe '#failure_message' do
    it { expect(matcher).to respond_to(:failure_message).with(0).arguments }
  end

  describe '#failure_message_when_negated' do
    it 'should define the method' do
      expect(matcher)
        .to respond_to(:failure_message_when_negated)
        .with(0).arguments
    end
  end

  describe '#matches?' do
    let(:failure_message) { "expected #{actual.inspect} to be a constraint" }

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    it { expect(matcher).to respond_to(:matches?).with(1).argument }

    describe 'with nil' do
      let(:actual) { nil }
      let(:failure_message) do
        "#{super()}, but is not a constraint"
      end

      include_examples 'should fail with a positive expectation'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:failure_message) do
        "#{super()}, but is not a constraint"
      end

      include_examples 'should fail with a positive expectation'
    end

    describe 'with a constraint' do
      let(:actual) { Stannum::Constraint.new }

      include_examples 'should pass with a positive expectation'
    end

    describe 'with a constraint with options' do
      let(:options) { { key: 'value' } }
      let(:actual)  { Stannum::Constraint.new(**options) }

      include_examples 'should pass with a positive expectation'
    end

    wrap_context 'when the expected constraint is a Class' do
      let(:failure_message) do
        "expected #{actual.inspect} to be a #{expected_constraint.name}"
      end

      describe 'with a constraint that does not match the expected constraint' \
      do
        let(:actual) { Stannum::Constraint.new }
        let(:failure_message) do
          "#{super()}, but is not an instance of #{expected_constraint}"
        end

        include_examples 'should fail with a positive expectation'
      end

      describe 'with a constraint that matches the expected constraint' do
        let(:actual) { Spec::ExampleConstraint.new }

        include_examples 'should pass with a positive expectation'
      end

      describe 'with a constraint with options' do
        let(:options) { { key: 'value' } }
        let(:actual)  { Spec::ExampleConstraint.new(**options) }

        include_examples 'should pass with a positive expectation'
      end

      wrap_context 'when there are expected options' do
        let(:diff_matcher) do
          RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
            .new(expected_options)
            .tap { |matcher| matcher.matches?(actual.options) }
        end
        let(:failure_message) do
          "#{super()}, but the options do not match:\n" +
            tools.str.indent(diff_matcher.failure_message, 2)
        end

        describe 'with a constraint with missing options' do
          let(:options) { {} }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with changed options' do
          let(:options) { expected_options.merge(language: 'Basic') }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with added options' do
          let(:options) { expected_options.merge(compiler: 'gcc') }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with matching options' do
          let(:options) { expected_options }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should pass with a positive expectation'
        end
      end
    end

    wrap_context 'when the expected constraint is a matcher' do
      let(:failure_message) do
        expected_constraint
          .tap { expected_constraint.matches?(actual) }
          .failure_message
      end

      describe 'with a constraint that does not match the expected constraint' \
      do
        let(:actual) { Stannum::Constraint.new }

        include_examples 'should fail with a positive expectation'
      end

      describe 'with a constraint that matches the expected constraint' do
        let(:actual) { Spec::ExampleConstraint.new }

        include_examples 'should pass with a positive expectation'
      end

      describe 'with a constraint with options' do
        let(:options) { { key: 'value' } }
        let(:actual)  { Spec::ExampleConstraint.new(**options) }

        include_examples 'should pass with a positive expectation'
      end

      wrap_context 'when there are expected options' do
        let(:diff_matcher) do
          RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
            .new(expected_options)
            .tap { |matcher| matcher.matches?(actual.options) }
        end
        let(:failure_message) do
          "#{super()}, but the options do not match:\n" +
            tools.str.indent(diff_matcher.failure_message, 2)
        end

        describe 'with a constraint with missing options' do
          let(:options) { {} }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with changed options' do
          let(:options) { expected_options.merge(language: 'Basic') }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with added options' do
          let(:options) { expected_options.merge(compiler: 'gcc') }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should fail with a positive expectation'
        end

        describe 'with a constraint with matching options' do
          let(:options) { expected_options }
          let(:actual)  { Spec::ExampleConstraint.new(**options) }

          include_examples 'should pass with a positive expectation'
        end
      end
    end

    wrap_context 'when there are expected options' do
      let(:diff_matcher) do
        RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
          .new(expected_options)
          .tap { |matcher| matcher.matches?(actual.options) }
      end
      let(:failure_message) do
        "#{super()}, but the options do not match:\n" +
          tools.str.indent(diff_matcher.failure_message, 2)
      end

      describe 'with a constraint with missing options' do
        let(:options) { {} }
        let(:actual)  { Stannum::Constraints::Base.new(**options) }

        include_examples 'should fail with a positive expectation'
      end

      describe 'with a constraint with changed options' do
        let(:options) { expected_options.merge(language: 'Basic') }
        let(:actual)  { Stannum::Constraints::Base.new(**options) }

        include_examples 'should fail with a positive expectation'
      end

      describe 'with a constraint with added options' do
        let(:options) { expected_options.merge(compiler: 'gcc') }
        let(:actual)  { Stannum::Constraints::Base.new(**options) }

        include_examples 'should fail with a positive expectation'
      end

      describe 'with a constraint with matching options' do
        let(:options) { expected_options }
        let(:actual)  { Stannum::Constraints::Base.new(**options) }

        include_examples 'should pass with a positive expectation'
      end
    end
  end

  describe '#with_options' do
    let(:options) { { key: 'value' } }

    it 'should define the method' do
      expect(matcher)
        .to respond_to(:with_options)
        .with(0).arguments
        .and_any_keywords
    end

    it { expect(matcher.with_options).to be matcher }

    it 'should set the expected options' do
      expect { matcher.with_options(**options) }
        .to change(matcher, :expected_options)
        .to be == options
    end
  end
end
