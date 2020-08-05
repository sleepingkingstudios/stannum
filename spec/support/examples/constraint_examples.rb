# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ConstraintExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should match the constraint' do
      let(:actual_status) do
        status, _ = subject.send(match_method, actual)

        status
      end
      let(:actual_errors) do
        _, errors = subject.send(match_method, actual)

        errors
      end

      it { expect(actual_status).to be true }

      it { expect(actual_errors).to be nil }
    end

    shared_examples 'should not match the constraint' do
      let(:actual_status) do
        status, _ = subject.send(match_method, actual)

        status
      end
      let(:actual_errors) do
        _, errors = subject.send(match_method, actual)

        errors
      end
      let(:wrapped_errors) do
        (expected_errors.is_a?(Array) ? expected_errors : [expected_errors])
          .map do |error|
            {
              data:    {},
              message: nil,
              path:    []
            }.merge(error)
          end
      end

      it { expect(actual_status).to be false }

      it { expect(actual_errors.to_a).to be == wrapped_errors }
    end

    shared_examples 'should match the value' do |negated: false|
      method_name = negated ? :negated_match : :match

      it 'should return true', :aggregate_failures do
        success, errors = subject.send(method_name, actual)

        expect(success).to be true
        expect(errors).to  be nil
      end
    end

    shared_examples 'should not match the value' do |negated: false|
      method_name = negated ? :negated_match      : :match
      errors_name = negated ? :negated_errors_for : :errors_for

      it 'should return false and the errors', :aggregate_failures do
        success, errors = subject.send(method_name, actual)

        expect(success).to be false
        expect(errors).to  be == subject.send(errors_name, actual)
      end
    end

    shared_examples 'should match' do |value, as: nil, reversible: false|
      describe '#match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          include_examples 'should match the value'
        end
      end

      describe '#matches?' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it { expect(subject.matches? actual).to be true }
        end
      end

      if reversible
        include_examples 'should not match when negated', value, as: as
      end
    end

    shared_examples 'should not match' do |value, as: nil, reversible: false|
      describe '#errors_for' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it { expect(subject.errors_for(actual)).to be == expected_errors }
        end
      end

      describe '#match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          include_examples 'should not match the value'
        end
      end

      describe '#matches?' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it { expect(subject.matches? actual).to be false }
        end
      end

      include_examples 'should match when negated', value, as: nil if reversible
    end

    shared_examples 'should match when negated' do |value, as: nil|
      describe '#does_not_match?' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it { expect(subject.does_not_match? actual).to be true }
        end
      end

      describe '#negated_match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          include_examples 'should match the value', negated: true
        end
      end
    end

    shared_examples 'should not match when negated' do |value, as: nil|
      describe '#does_not_match?' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it { expect(subject.does_not_match? actual).to be false }
        end
      end

      describe '#negated_errors_for' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          it 'should return the errors' do
            expect(subject.negated_errors_for(actual)).to be == negated_errors
          end
        end
      end

      describe '#negated_match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value.is_a?(Proc) ? instance_exec(&value) : value }

          include_examples 'should not match the value', negated: true
        end
      end
    end

    shared_examples 'should implement the Constraint interface' do
      describe '#does_not_match?' do
        it 'should define the method' do
          expect(subject).to respond_to(:does_not_match?).with(1).argument
        end
      end

      describe '#errors_for' do
        let(:actual) { Object.new.freeze }

        it { expect(subject).to respond_to(:errors_for).with(1).argument }

        # rubocop:disable Lint/RedundantCopDisableDirective
        # rubocop:disable RSpec/ExampleLength
        it 'should delegate to #update_errors_for', :aggregate_failures do
          allow(subject) # rubocop:disable RSpec/SubjectStub
            .to receive(:update_errors_for) do |keywords|
              keywords.fetch(:errors).add('spec.example_error')
            end

          errors = subject.errors_for actual

          expect(errors).to be_a Stannum::Errors
          expect(errors)
            .to include(be >= { type: 'spec.example_error' })

          expect(subject) # rubocop:disable RSpec/SubjectStub
            .to have_received(:update_errors_for)
            .with(actual: actual, errors: an_instance_of(Stannum::Errors))
        end
        # rubocop:enable Lint/RedundantCopDisableDirective
        # rubocop:enable RSpec/ExampleLength
      end

      describe '#match' do
        it { expect(subject).to respond_to(:match).with(1).argument }
      end

      describe '#matches?' do
        it { expect(subject).to respond_to(:matches?).with(1).argument }

        it { expect(subject).to alias_method(:matches?).as(:match?) }
      end

      describe '#negated_errors_for' do
        let(:actual) { Object.new.freeze }

        it 'should define the method' do
          expect(subject).to respond_to(:negated_errors_for).with(1).argument
        end

        # rubocop:disable Lint/RedundantCopDisableDirective
        # rubocop:disable RSpec/ExampleLength
        it 'should delegate to #update_negated_errors_for',
          :aggregate_failures \
        do
          allow(subject) # rubocop:disable RSpec/SubjectStub
            .to receive(:update_negated_errors_for) do |keywords|
              keywords.fetch(:errors).add('spec.example_error')
            end

          errors = subject.negated_errors_for actual

          expect(errors).to be_a Stannum::Errors
          expect(errors)
            .to include(be >= { type: 'spec.example_error' })

          expect(subject) # rubocop:disable RSpec/SubjectStub
            .to have_received(:update_negated_errors_for)
            .with(actual: actual, errors: an_instance_of(Stannum::Errors))
        end
        # rubocop:enable Lint/RedundantCopDisableDirective
        # rubocop:enable RSpec/ExampleLength
      end

      describe '#negated_match' do
        it 'should define the method' do
          expect(subject).to respond_to(:negated_match).with(1).argument
        end
      end
    end
  end
end
