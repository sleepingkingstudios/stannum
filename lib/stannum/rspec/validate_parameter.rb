# frozen_string_literal: true

require 'stannum/rspec/validate_parameter_matcher'

module Stannum::RSpec
  # Namespace for custom RSpec matcher macros.
  module Matchers
    # Builds a ValidateParameterMatcher.
    #
    # @param method_name [String, Symbol] The name of the method with validated
    #   parameters.
    # @param parameter_name [String, Symbol] The name of the validated method
    #   parameter.
    #
    # @return [Stannum::RSpec::ValidateParameterMatcher] the matcher.
    def validate_parameter(method_name, parameter_name)
      Stannum::RSpec::ValidateParameterMatcher.new(
        method_name:    method_name,
        parameter_name: parameter_name
      )
    end
  end
end
