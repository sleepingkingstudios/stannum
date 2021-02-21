# frozen_string_literal: true

require 'stannum/rspec/match_errors_matcher'

module RSpec
  module Matchers # rubocop:disable Style/Documentation
    def match_errors(expected)
      Stannum::RSpec::MatchErrorsMatcher.new(expected)
    end
  end
end
