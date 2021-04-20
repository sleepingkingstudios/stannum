# frozen_string_literal: true

require 'stannum/rspec/match_errors_matcher'

module Stannum::RSpec
  # Namespace for custom RSpec matcher macros.
  module Matchers
    # Builds a MatchErrorsMatcher.
    #
    # @param expected [Stannum::Errors] The expected errors.
    #
    # @return [Stannum::RSpec::MatchErrorsMatcher] the matcher.
    def match_errors(expected)
      Stannum::RSpec::MatchErrorsMatcher.new(expected)
    end
  end
end
