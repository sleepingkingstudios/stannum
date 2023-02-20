# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'stannum/entities'

module Stannum
  # Namespace for modules implementing Entity functionality.
  module Entities
    autoload :Attributes, 'stannum/entities/attributes'
    autoload :Properties, 'stannum/entities/properties'
  end
end
