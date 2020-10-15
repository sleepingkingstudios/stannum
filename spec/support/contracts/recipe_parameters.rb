# frozen_string_literal: true

require 'bigdecimal'

require 'stannum/contracts/parameters_contract'

module Spec
  class IngredientContract < Stannum::Contracts::TupleContract
    def initialize
      super do
        item Stannum::Constraints::Type.new(String),
          property_name: :amount
        item Stannum::Constraints::Type.new(String, optional: true),
          property_name: :unit
      end
    end
  end

  class RecipeParameters < Stannum::Contracts::ParametersContract
    def initialize
      super do
        arguments :tools,       String
        keywords  :ingredients, Spec::IngredientContract.new
        block     true
      end
    end
  end
end
