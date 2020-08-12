# frozen_string_literal: true

require 'stannum/contracts/tuple_contract'

module Spec
  class BaseballContract < Stannum::Contracts::TupleContract
    def initialize
      super do
        item { |actual| actual == 'Who' }
        item { |actual| actual == 'What' }
        item { |actual| actual == 'I Don\'t Know' }
      end
    end
  end
end
