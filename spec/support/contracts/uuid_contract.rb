# frozen_string_literal: true

require 'stannum/contracts/base'

require 'support/constraints/format_constraint'
require 'support/constraints/length_constraint'

module Spec
  class UuidContract < Stannum::Contracts::Base
    def initialize
      super

      add_constraint Stannum::Constraints::Type.new(String), sanity: true

      add_constraint Spec::LengthConstraint.new(36)

      add_constraint Spec::FormatConstraint.new(/\A[A-Fa-f0-9\-]+\d/)
    end
  end
end
