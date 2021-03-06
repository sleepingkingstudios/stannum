# frozen_string_literal: true

require 'stannum/constraints/base'

module Stannum
  # Constraint class for defining a custom or one-off constraint instance.
  #
  # The Stannum::Constraint class allows you to define a constraint instance
  # with a block, and optionally a type and negated type when generating errors
  # for non-matching objects.
  #
  # If your use case is more complicated, such as a constraint with multiple
  # expectations and thus different errors depending on the given object, use
  # a subclass of the Stannum::Constraints::Base class instead. For example, an
  # is_odd constraint that checks if an object is an odd integer might have
  # different errors when passed a non-integer object and when passed an even
  # integer, even though both are failing matches.
  #
  # Likewise, if you want to define a custom constraint class, it is recommended
  # that you use Stannum::Constraints::Base as the base class for all but the
  # simplest constraints.
  #
  # @example Defining a Custom Constraint
  #   is_integer = Stannum::Constraint.new { |actual| actual.is_a?(Integer) }
  #   is_integer.matches?(nil) #=> false
  #   is_integer.matches?(3)   #=> true
  #   is_integer.matches?(3.5) #=> false
  #
  # @example Defining a Custom Constraint With Errors
  #   is_even_integer = Stannum::Constraint.new(
  #     negated_type: 'examples.an_even_integer',
  #     type:         'examples.not_an_even_integer'
  #   ) { |actual| actual.is_a?(Integer) && actual.even? }
  #
  #   is_even_integer.matches?(nil) #=> false
  #   is_even_integer.matches?(2)   #=> true
  #   is_even_integer.matches?(3)   #=> false
  #
  # @see Stannum::Constraints::Base
  class Constraint < Stannum::Constraints::Base
    # @overload initialize(**options)
    #   @param options [Hash<Symbol, Object>] Configuration options for the
    #     constraint. Defaults to an empty Hash.
    #
    #   @yield The definition for the constraint. Each time #matches? is called
    #     for this constraint, the given object will be passed to this block and
    #     the result of the block will be returned.
    #   @yieldparam actual [Object] The object to check against the constraint.
    #   @yieldreturn [true, false] true if the given object matches the
    #     constraint, otherwise false.
    #
    #   @see #matches?
    def initialize(**options, &block)
      @definition = block

      super(**options)
    end

    # (see Stannum::Constraints::Base#matches?)
    def matches?(actual)
      @definition ? @definition.call(actual) : super
    end
    alias match? matches?
  end
end
