# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for modules implementing Association functionality.
  module Associations
    autoload :Many, 'stannum/associations/many'
    autoload :One,  'stannum/associations/one'
  end
end
