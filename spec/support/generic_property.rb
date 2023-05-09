# frozen_string_literal: true

module Spec
  class GenericProperty < Struct.new(:name, :options, :type, keyword_init: true) # rubocop:disable Style/StructInheritance
    class Builder
      def initialize(*); end

      def call(*); end
    end
  end
end
