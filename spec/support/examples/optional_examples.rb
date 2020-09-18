# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module OptionalExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should implement the Optional interface' do
      describe '#optional?' do
        include_examples 'should have predicate', :optional?
      end

      describe '#required?' do
        include_examples 'should have predicate', :required?
      end
    end

    shared_examples 'should implement the Optional methods' \
    do |required_by_default: true|
      describe '#optional?' do
        context 'when options[:required] is false' do
          before(:example) do
            allow(subject).to receive(:options).and_return(required: false)
          end

          it { expect(subject.optional?).to be true }
        end

        context 'when options[:required] is true' do
          before(:example) do
            allow(subject).to receive(:options).and_return(required: true)
          end

          it { expect(subject.optional?).to be false }
        end
      end

      describe '#options' do
        it { expect(subject.options[:required]).to be required_by_default }

        context 'when initialized with optional: false' do
          let(:constructor_options) { super().merge(optional: false) }

          it { expect(subject.options[:required]).to be true }
        end

        context 'when initialized with optional: true' do
          let(:constructor_options) { super().merge(optional: true) }

          it { expect(subject.options[:required]).to be false }
        end

        context 'when initialized with required: false' do
          let(:constructor_options) { super().merge(required: false) }

          it { expect(subject.options[:required]).to be false }
        end

        context 'when initialized with required: true' do
          let(:constructor_options) { super().merge(required: true) }

          it { expect(subject.options[:required]).to be true }
        end
      end

      describe '#required?' do
        context 'when options[:required] is false' do
          before(:example) do
            allow(subject).to receive(:options).and_return(required: false)
          end

          it { expect(subject.required?).to be false }
        end

        context 'when options[:required] is true' do
          before(:example) do
            allow(subject).to receive(:options).and_return(required: true)
          end

          it { expect(subject.required?).to be true }
        end
      end
    end
  end
end
