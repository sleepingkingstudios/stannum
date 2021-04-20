# frozen_string_literal: true

require 'stannum/rspec/match_errors'

module Spec::Support
  module Matchers
    autoload :BeAConstraintMatcher, 'support/matchers/be_a_constraint_matcher'

    def be_a_constraint(expected = nil)
      Spec::Support::Matchers::BeAConstraintMatcher.new(expected)
    end
  end
end
