# frozen_string_literal: true

require 'stannum/constraints'

module Stannum::Constraints
  # Namespace for Hash-specific constraints.
  module Hashes
    autoload :ExtraKeys,
      'stannum/constraints/hashes/extra_keys'
    autoload :IndifferentExtraKeys,
      'stannum/constraints/hashes/indifferent_extra_keys'
    autoload :IndifferentKey,
      'stannum/constraints/hashes/indifferent_key'
  end
end
