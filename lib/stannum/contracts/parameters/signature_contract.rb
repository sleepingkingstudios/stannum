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

    def define_constraints(&)
      super

      add_key_constraint :arguments,
        Stannum::Constraints::Types::ArrayType.new
      add_key_constraint :keywords,
        Stannum::Constraints::Types::HashType.new(
          key_type: Stannum::Constraints::Types::SymbolType.new
        )
      add_key_constraint :block,
        Stannum::Constraints::Types::ProcType.new(optional: true)
    end
  end
end
