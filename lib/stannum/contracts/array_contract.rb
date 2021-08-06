# frozen_string_literal: true

require 'stannum/constraints/types/array_type'
require 'stannum/contracts'
require 'stannum/contracts/tuple_contract'

module Stannum::Contracts
  # An ArrayContract defines constraints for an Array and its items.
  #
  # In order to match an ArrayContract, the object must be an instance of Array,
  # and the items in the array at each index must match the item constraint
  # defined for that index. If the :item_type option is set, each item must
  # match that type or constraint. Finally, unless the :allow_extra_items option
  # is set to true, the object must not have any extra items.
  #
  # @example Creating A Contract With Item Constraints
  #   third_base_constraint = Stannum::Constraint.new do |actual|
  #     actual == "I Don't Know"
  #   end
  #   array_contract = Stannum::Contracts::ArrayContract.new do
  #     item { |actual| actual == 'Who' }
  #     item { |actual| actual == 'What' }
  #     item third_base_constraint
  #   end
  #
  # @example With A Non-Array Object
  #   array_contract.matches?(nil) #=> false
  #   errors = array_contract.errors_for(nil)
  #   errors.to_a
  #   #=> [
  #     {
  #       type:    'stannum.constraints.type',
  #       data:    { required: true, type: Array },
  #       message: nil,
  #       path:    []
  #     }
  #   ]
  #
  # @example With An Object With Missing Items
  #   array_contract.matches?(['Who']) #=> false
  #   errors = array_contract.errors_for(['Who'])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.invalid', data: {}, path: [1], message: nil },
  #     { type: 'stannum.constraints.invalid', data: {}, path: [2], message: nil }
  #   ]
  #
  # @example With An Object With Incorrect Items
  #   array_contract.matches?(['What', 'What', "I Don't Know"]) #=> false
  #   errors = array_contract.errors_for(['What', 'What', "I Don't Know"])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.invalid', data: {}, path: [0], message: nil }
  #   ]
  #
  # @example With An Object With Valid Items
  #   array_contract.matches?(['Who', 'What', "I Don't Know"]) #=> true
  #   errors = array_contract.errors_for(['What', 'What', "I Don't Know"])
  #   errors.to_a #=> []
  #
  # @example With An Object With Extra Items
  #   array_contract.matches?(['Who', 'What', "I Don't Know", 'Tomorrow', 'Today']) #=> false
  #   errors = array_contract.errors_for(['Who', 'What', "I Don't Know", 'Tomorrow', 'Today'])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.tuples.extra_items', data: {}, path: [3], message: nil },
  #     { type: 'stannum.constraints.tuples.extra_items', data: {}, path: [4], message: nil }
  #   ]
  class ArrayContract < Stannum::Contracts::TupleContract
    # @param allow_extra_items [true, false] If false, then a tuple with extra
    #   items after the last expected item will not match the contract.
    # @param item_type [Stannum::Constraints::Base, Class, nil] If set, then
    #   the constraint will check the types of each item in the Array against
    #   the expected type and will fail if any items do not match.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(allow_extra_items: false, item_type: nil, **options, &block)
      super(
        allow_extra_items: allow_extra_items,
        item_type:         item_type,
        **options,
        &block
      )
    end

    # @return [Stannum::Constraints::Base, nil] the expected type for the items
    #   in the array.
    def item_type
      options[:item_type]
    end

    # (see Stannum::Contracts::Base#with_options)
    def with_options(**options)
      return super unless options.key?(:item_type)

      raise ArgumentError, "can't change option :item_type"
    end

    private

    def add_type_constraint
      add_constraint(
        Stannum::Constraints::Types::ArrayType.new(item_type: item_type),
        sanity: true
      )
    end
  end
end
