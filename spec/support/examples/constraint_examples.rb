# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ConstraintExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should match the value' do |negated: false|
      method_name = negated ? :negated_match : :match

      it 'should return true', :aggregate_failures do
        success, errors = constraint.send(method_name, actual)

        expect(success).to be true
        expect(errors).to  be nil
      end
    end

    shared_examples 'should not match the value' do |negated: false|
      method_name = negated ? :negated_match      : :match
      errors_name = negated ? :negated_errors_for : :errors_for

      it 'should return false and the errors', :aggregate_failures do
        success, errors = constraint.send(method_name, actual)

        expect(success).to be false
        expect(errors).to  be == constraint.send(errors_name, actual)
      end
    end

    shared_examples 'should not match' do |value, as: nil|
      describe '#errors_for' do
        describe "with #{as || value.inspect}" do
          it { expect(constraint.errors_for(value)).to be == expected_errors }
        end
      end

      describe '#match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value }

          include_examples 'should not match the value'
        end
      end

      describe '#matches?' do
        describe "with #{as || value.inspect}" do
          it { expect(constraint.matches? value).to be false }
        end
      end
    end

    shared_examples 'should match when negated' do |value, as: nil|
      describe '#does_not_match?' do
        describe "with #{as || value.inspect}" do
          it { expect(constraint.does_not_match? value).to be true }
        end
      end

      describe '#negated_match' do
        describe "with #{as || value.inspect}" do
          let(:actual) { value }

          include_examples 'should match the value', negated: true
        end
      end
    end

    shared_examples 'should implement the Constraint interface' do
      describe '#does_not_match?' do
        it 'should define the method' do
          expect(constraint).to respond_to(:does_not_match?).with(1).argument
        end
      end

      describe '#errors_for' do
        it { expect(constraint).to respond_to(:errors_for).with(1).argument }
      end

      describe '#match' do
        it { expect(constraint).to respond_to(:match).with(1).argument }
      end

      describe '#matches?' do
        it { expect(constraint).to respond_to(:matches?).with(1).argument }

        it { expect(constraint).to alias_method(:matches?).as(:match?) }
      end

      describe '#negated_errors_for' do
        it 'should define the method' do
          expect(constraint).to respond_to(:negated_errors_for).with(1).argument
        end
      end

      describe '#negated_match' do
        it 'should define the method' do
          expect(constraint).to respond_to(:negated_match).with(1).argument
        end
      end
    end
  end
end
