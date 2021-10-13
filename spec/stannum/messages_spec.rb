# frozen_string_literal: true

require 'stannum/messages'

RSpec.describe Stannum::Messages do
  describe '.locales_path' do
    let(:expected) { File.join(Stannum.gem_path, 'config', 'locales') }

    include_examples 'should define class reader',
      :locales_path,
      -> { be == expected }
  end

  describe '.strategy' do
    let(:filename) { File.join(described_class.locales_path) }

    include_examples 'should define class reader',
      :strategy,
      -> { an_instance_of(Stannum::Messages::DefaultStrategy) }

    it 'should configure the default strategy' do
      expect(described_class.strategy.send(:load_path)).to be == [filename]
    end
  end

  describe '.strategy=' do
    let(:strategy) { -> {} }

    around(:example) do |example|
      original_strategy = described_class.strategy

      example.call
    ensure
      described_class.strategy = original_strategy
    end

    include_examples 'should define class writer', :strategy

    it 'should set the configured strategy' do
      expect { described_class.strategy = strategy }
        .to change(described_class, :strategy)
        .to be strategy
    end
  end
end
