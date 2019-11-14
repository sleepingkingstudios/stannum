# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ConstraintExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should match the value' do
      it 'should return true', :aggregate_failures do
        success, errors = constraint.match(actual)

        expect(success).to be true
        expect(errors).to  be nil
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

    shared_examples 'should not match the value' do
      it 'should return false and the errors', :aggregate_failures do
        success, errors = constraint.match(actual)

        expect(success).to be false
        expect(errors).to  be == constraint.errors_for(actual)
      end
    end
  end
end
