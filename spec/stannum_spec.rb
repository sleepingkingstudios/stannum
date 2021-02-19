# frozen_string_literal: true

require 'stannum'

RSpec.describe Stannum do
  describe '::gem_path' do
    let(:expected) do
      __dir__.sub(/#{File::SEPARATOR}spec#{File::SEPARATOR}?\z/, '')
    end

    include_examples 'should define class reader',
      :gem_path,
      -> { be == expected }
  end

  describe '::version' do
    let(:expected) { Stannum::Version.to_gem_version }

    include_examples 'should define class reader',
      :version,
      -> { be == expected }
  end
end
