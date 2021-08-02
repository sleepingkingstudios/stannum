# frozen_string_literal: true

require 'stannum/contracts'

module Stannum::Contracts
  # A TupleContract defines constraints for an ordered, indexed object.
  #
  # In order to match a TupleContract, the object must respond to the :[],
  # :each, and :size methods, and the items in the object at each index must
  # match the item constraint defined for that index. Finally, unless the
  # :allow_extra_items option is set to true, the object must not have any extra
  # items.
  #
  # @example Creating A Contract With Item Constraints
  #   third_base_constraint = Stannum::Constraint.new do |actual|
  #     actual == "I Don't Know"
  #   end
  #   tuple_contract = Stannum::Contracts::TupleContract.new do
  #     item { |actual| actual == 'Who' }
  #     item { |actual| actual == 'What' }
  #     item third_base_constraint
  #   end
  #
  # @example With A Non-Tuple Object
  #   tuple_contract.matches?(nil) #=> false
  #   errors = tuple_contract.errors_for(nil)
  #   errors.to_a
  #   #=> [
  #     {
  #       type:    'stannum.constraints.does_not_have_methods',
  #       data:    { methods: [:[], :each, :size], missing: [:[], :each, :size] },
  #       message: nil,
  #       path:    []
  #     }
  #   ]
  #
  # @example With An Object With Missing Items
  #   tuple_contract.matches?(['Who']) #=> false
  #   errors = tuple_contract.errors_for(['Who'])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.invalid', data: {}, path: [1], message: nil },
  #     { type: 'stannum.constraints.invalid', data: {}, path: [2], message: nil }
  #   ]
  #
  # @example With An Object With Incorrect Items
  #   tuple_contract.matches?(['What', 'What', "I Don't Know"]) #=> false
  #   errors = tuple_contract.errors_for(['What', 'What', "I Don't Know"])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.invalid', data: {}, path: [0], message: nil }
  #   ]
  #
  # @example With An Object With Valid Items
  #   tuple_contract.matches?(['Who', 'What', "I Don't Know"]) #=> true
  #   errors = tuple_contract.errors_for(['What', 'What', "I Don't Know"])
  #   errors.to_a #=> []
  #
  # @example With An Object With Extra Items
  #   tuple_contract.matches?(['Who', 'What', "I Don't Know", 'Tomorrow', 'Today']) #=> false
  #   errors = tuple_contract.errors_for(['Who', 'What', "I Don't Know", 'Tomorrow', 'Today'])
  #   errors.to_a
  #   #=> [
  #     { type: 'stannum.constraints.tuples.extra_items', data: {}, path: [3], message: nil },
  #     { type: 'stannum.constraints.tuples.extra_items', data: {}, path: [4], message: nil }
  #   ]
  class TupleContract < Stannum::Contracts::PropertyContract
    # Builder class for defining item constraints for a TupleContract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for TupleContract.
    #
    # @api private
    class Builder < Stannum::Contracts::PropertyContract::Builder
      # @param contract [Stannum::Contract] The contract to which constraints
      #   are added.
      def initialize(contract)
        super

        @current_index = -1
      end

      # Defines an item constraint on the contract.
      #
      # Each time an item constraint is defined, the constraint is tied to an
      # incrementing index, i.e. the first constraint is matched against the
      # item at index 0, the second at index 1, and so on. This can be overriden
      # by setting the :property option.
      #
      # @overload item(constraint, **options)
      #   Adds the given constraint to the contract for the next index.
      #
      #   @param constraint [Stannum::Constraint::Base] The constraint to add.
      #   @param options [Hash<Symbol, Object>] Options for the constraint.
      #
      # @overload item(**options) { |value| }
      #   Creates a new Stannum::Constraint object with the given block, and
      #   adds that constraint to the contract for the next index.
      #
      #   @param options [Hash<Symbol, Object>] Options for the constraint.
      #   @yieldparam value [Object] The value of the property when called.
      def item(constraint = nil, **options, &block)
        index = (@current_index += 1)

        self.constraint(
          constraint,
          property:      index,
          property_type: :index,
          **options,
          &block
        )
      end
    end

    # @param allow_extra_items [true, false] If false, then a tuple with extra
    #   items after the last expected item will not match the contract.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   contract. Defaults to an empty Hash.
    def initialize(allow_extra_items: false, **options, &block)
      super(allow_extra_items: allow_extra_items, **options, &block)
    end

    # Adds an index constraint to the contract.
    #
    # When the contract is called, the contract will find the value of the
    # object at the given index.
    #
    # @param index [Integer] The index of the value to match.
    # @param constraint [Stannum::Constraints::Base] The constraint to add.
    # @param sanity [true, false] Marks the constraint as a sanity constraint,
    #   which is always matched first and will always short-circuit on a failed
    #   match.
    # @param options [Hash<Symbol, Object>] Options for the constraint. These
    #   can be used by subclasses to define the value and error mappings for the
    #   constraint.
    #
    # @return [self] the contract.
    #
    # @see Stannum::Contracts::PropertyContract#add_constraint.
    def add_index_constraint(index, constraint, sanity: false, **options)
      add_constraint(
        constraint,
        property:      index,
        property_type: :index,
        sanity:        sanity,
        **options
      )
    end

    # @return [true, false] If false, then a tuple with extra items after the
    #   last expected item will not match the contract.
    def allow_extra_items?
      !!options[:allow_extra_items]
    end

    # (see Stannum::Contracts::Base#with_options)
    def with_options(**options)
      return super unless options.key?(:allow_extra_items)

      raise ArgumentError, "can't change option :allow_extra_items"
    end

    protected

    def expected_count
      each_constraint.reduce(0) do |count, definition|
        next count unless definition.options[:property_type] == :index

        index = 1 + definition.options.fetch(:property, -1)

        index > count ? index : count
      end
    end

    def map_value(actual, **options)
      return super unless options[:property_type] == :index

      actual[options[:property]]
    end

    def valid_property?(property: nil, property_type: nil, **options)
      return super unless property_type == :index

      property.is_a?(Integer)
    end

    def validate_property?(**options)
      options[:property_type] == :index || super
    end

    private

    def add_extra_items_constraint
      return if allow_extra_items?

      count = -> { expected_count }

      add_constraint Stannum::Constraints::Tuples::ExtraItems.new(count)
    end

    def add_type_constraint
      add_constraint Stannum::Constraints::Signatures::Tuple.new, sanity: true
    end

    def define_constraints(&block)
      add_type_constraint

      add_extra_items_constraint

      super
    end
  end
end
