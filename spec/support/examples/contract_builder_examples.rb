# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ContractBuilderExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should resolve the constraint' do
      describe 'with a nil constraint' do
        let(:error_message) { 'invalid constraint nil' }

        it 'should raise an exception' do
          expect { resolve_constraint }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an invalid constraint' do
        let(:constraint)    { Object.new.freeze }
        let(:error_message) { "invalid constraint #{constraint.inspect}" }

        it 'should raise an exception' do
          expect { resolve_constraint(constraint) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with a valid constraint' do
        let(:constraint) { Stannum::Constraint.new }

        it 'should resolve the constraint' do
          expect(resolve_constraint(constraint)).to be constraint
        end
      end

      describe 'with a block' do
        let(:block)  { ->(actual) { actual.nil? } }
        let(:actual) { Object.new.freeze }

        it 'should resolve an anonymous constraint' do
          expect(resolve_constraint(&block)).to be_a Stannum::Constraint
        end

        it 'should yield the block to the constraint' do
          expect do |block|
            constraint = resolve_constraint(&block)

            constraint.match?(actual)
          end
            .to yield_with_args(actual)
        end
      end

      describe 'with a block and a constraint' do
        let(:block)      { ->(actual) { actual.nil? } }
        let(:constraint) { Stannum::Constraint.new }
        let(:error_message) do
          'expected either a block or a constraint instance, but received' \
          " both a block and #{constraint.inspect}"
        end

        it 'should raise an exception' do
          expect { resolve_constraint(constraint, &block) }
            .to raise_error ArgumentError, error_message
        end
      end
    end
  end
end
