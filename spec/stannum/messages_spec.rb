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
    let(:filename) { File.join(described_class.locales_path, 'en.rb') }

    include_examples 'should define class reader',
      :strategy,
      -> { an_instance_of(Stannum::Messages::DefaultStrategy) }

    it 'should configure the default strategy' do
      expect(described_class.strategy.send(:filename)).to be == filename
    end
  end
end
