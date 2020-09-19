# frozen_string_literal: true

require 'stannum'

module Spec
  class LightsConstraint < Stannum::Constraints::Delegator
    def initialize(count)
      super(Stannum::Constraints::Identity.new(count))
    end
  end
end
