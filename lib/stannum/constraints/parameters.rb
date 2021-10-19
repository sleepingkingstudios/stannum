# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for constraints that match method parameters.
  module Parameters
    autoload :ExtraKeywords, 'stannum/constraints/parameters/extra_keywords'
  end
end
