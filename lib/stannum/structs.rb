# frozen_string_literal: true

require 'stannum'

module Stannum
  # Namespace for classes and modules related to Structs.
  #
  # @note Normally, it is best to avoid relying on pluralization in namespaces,
  #   and this functionality should be in the Struct module itself. However,
  #   since Struct is itself included in end user classes, this results in extra
  #   modules being added to those classes, breaking encapsulation.
  module Structs; end
end
