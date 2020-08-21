# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ContractBuilderExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should delegate to #constraint' do
      let(:options) { {} }
      let(:expected_options) do
        defined?(custom_options) ? custom_options.merge(options) : options
      end

      before(:example) do
        allow(builder).to receive(:constraint)
      end

      describe 'with a block' do
        let(:implementation) { -> {} }

        it 'should delegate to #constraint' do
          define_from_block(&implementation)

          expect(builder)
            .to have_received(:constraint)
            .with(nil, **expected_options)
        end

        it 'should pass the implementation' do
          allow(builder).to receive(:constraint) do |*_args, &block|
            block.call
          end

          expect { |block| define_from_block(&block) }.to yield_control
        end
      end

      describe 'with a block and options' do
        let(:implementation) { -> {} }
        let(:options)        { { key: 'value' } }

        it 'should delegate to #constraint' do
          define_from_block(**options, &implementation)

          expect(builder)
            .to have_received(:constraint)
            .with(nil, **expected_options)
        end
      end

      describe 'with a constraint' do
        let(:constraint) { Stannum::Constraints::Base.new }

        it 'should delegate to #constraint' do
          define_from_constraint(constraint)

          expect(builder)
            .to have_received(:constraint)
            .with(constraint, **expected_options)
        end
      end

      describe 'with a constraint and options' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:options)    { { key: 'value' } }

        it 'should delegate to #constraint' do
          define_from_constraint(constraint, **options)

          expect(builder)
            .to have_received(:constraint)
            .with(constraint, **expected_options)
        end
      end
    end
  end
end
