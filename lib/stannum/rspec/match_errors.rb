# frozen_string_literal: true

require 'stannum/rspec/match_errors_matcher'

module Stannum::RSpec
  # Namespace for custom RSpec matcher macros.
  module Matchers
    def match_errors(expected)
      Stannum::RSpec::MatchErrorsMatcher.new(expected)
    end
  end
end
