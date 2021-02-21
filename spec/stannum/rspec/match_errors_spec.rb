# frozen_string_literal: true

require 'stannum/errors'
require 'stannum/rspec/match_errors'

RSpec.describe RSpec::Matchers do # rubocop:disable RSpec/FilePath
  let(:example_group) { self }

  describe '#match_errors' do
    let(:expected) { Stannum::Errors.new }
    let(:matcher)  { example_group.match_errors(expected) }

    it 'should define the method' do
      expect(example_group)
        .to respond_to(:match_errors)
        .with(1).argument
    end

    it { expect(matcher).to be_a Stannum::RSpec::MatchErrorsMatcher }

    it 'should set the description' do
      expect(matcher.description)
        .to be == 'match the expected errors'
    end
  end
end
