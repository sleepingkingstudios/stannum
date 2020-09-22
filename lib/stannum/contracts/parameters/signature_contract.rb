# frozen_string_literal: true

require 'stannum/contracts/parameters'

module Stannum::Contracts::Parameters
  # A SignatureContract defines a parameters object for a ParametersContract.
  class SignatureContract < Stannum::Contracts::HashContract
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(**options)
      super(key_type: Symbol, **options)
    end

    private

    def define_constraints(&block)
      super

      add_key_constraint :arguments,
        Stannum::Constraints::Types::Array.new
      add_key_constraint :keywords,
        Stannum::Constraints::Types::Hash.new(
          key_type: Stannum::Constraints::Types::Symbol.new
        )
      add_key_constraint :block,
        Stannum::Constraints::Types::Proc.new(optional: true)
    end
  end
end
