# frozen_string_literal: true

require 'support/entities'

module Spec::Support::Entities
  module GenericProperties
    def initialize(**properties)
      @properties = {
        'amplitude' => nil,
        'frequency' => nil
      }

      super
    end

    def properties
      super.merge(@properties)
    end

    private

    def get_property(key)
      @properties.fetch(key.to_s) { super(key) }
    end

    def inspect_properties(**options)
      return super unless options.fetch(:properties, true)

      @properties.reduce(super) do |memo, (key, value)|
        "#{memo} #{key}: #{value.inspect}"
      end
    end

    def set_properties(properties, force:)
      matching, non_matching = bisect_properties(properties, @properties)

      super(non_matching, force:)

      defaults = {
        'amplitude' => nil,
        'frequency' => nil
      }
      values = force ? defaults : self.properties

      @properties = values.merge(matching)
    end

    def set_property(key, value)
      super unless @properties.key?(key.to_s)

      @properties[key.to_s] = value
    end
  end
end
