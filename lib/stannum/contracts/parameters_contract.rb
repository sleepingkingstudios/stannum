# frozen_string_literal: true

require 'stannum/contracts'

require 'stannum/support/coercion'

module Stannum::Contracts
  # A Parameters defines constraints on the parameters for a block or method.
  #
  # The ParametersContract requires that the actual object matched be a Hash
  # with the following keys: :arguments, with an Array value; :keywords, with a
  # Hash value; and :block, with a value of either a Proc or nil.
  #
  # For the arguments constraints, the contract verifies that the correct number
  # of arguments are given and that each argument matches the type or constraint
  # specified. If the contract has a variadic arguments constraint, then each
  # variadic (or "splatted") argument is checked against the type or constraint.
  #
  # For the keywords constraints, the contract verifies that the expected
  # keywords are given and that each keyword value matches the type or
  # constraint specified. If the contract has a variadic keywords constraint,
  # then each variadic keyword value is checked against the type or constraint.
  #
  # For the block constraint, the contract specifies that the block is present,
  # the block is absent, or the block matches the given constraint.
  #
  # @example Defining A Parameters Contract With Arguments
  #   contract = Stannum::Contracts::ParametersContract.new do
  #     argument :name, String
  #     argument :size, String, optional: true
  #   end
  #
  #   contract.matches?(
  #     { arguments: [], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: [:a_symbol], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: ['Widget', 'Small', :extra], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: ['Widget', 'Small', :extra], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: ['Widget'], keywords: {}, block: nil }
  #   )
  #   #=> true
  #
  #   contract.matches?(
  #     { arguments: ['Widget', 'Small'], keywords: {}, block: nil }
  #   )
  #   #=> true
  #
  # @example Defining A Parameters Contract With Keywords
  #   contract = Stannum::Contracts::ParametersContract.new do
  #     keyword :price,    String
  #     keyword :quantity, Integer, optional: true
  #   end
  #
  #   contract.matches?(
  #     { arguments: [], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       price: 1_000_000,
  #     },
  #     block: nil
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       currency: 'USD',
  #       price:    '$1_000_000',
  #     },
  #     block: nil
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       price: '$1_000_000',
  #     },
  #     block: nil
  #   )
  #
  #   #=> true
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       price:    '$1_000_000',
  #       quantity: 50,
  #     },
  #     block: nil
  #   )
  #   #=> true
  #
  # @example Defining A Parameters Contract With Variadic Arguments
  #   contract = Stannum::Contracts::ParametersContract.new do
  #     arguments :words, String
  #   end
  #
  #   contract.matches?(
  #     { arguments: [1, 2, 3], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: [], keywords: {}, block: nil }
  #   )
  #   #=> true
  #
  #   contract.matches?(
  #     { arguments: ['foo', 'bar', 'baz'], keywords: {}, block: nil }
  #   )
  #   #=> true
  #
  # @example Defining A Parameters Contract With Variadic Keywords
  #   contract = Stannum::Contracts::ParametersContract.new do
  #     keywords :options, Symbol
  #   end
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       price: 1_000_000,
  #     },
  #     block: nil
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {},
  #     block: nil
  #   )
  #   #=> true
  #
  #   contract.matches?(
  #     arguments: [],
  #     keywords:  {
  #       color: :red,
  #       shape: :triangle
  #     },
  #     block: nil
  #   )
  #   #=> true
  #
  # @example Defining A Parameters Contract With A Block Constraint
  #   contract = Stannum::Contracts::ParametersContract.new do
  #     block true
  #   end
  #
  #   contract.matches?(
  #     { arguments: [], keywords: {}, block: nil }
  #   )
  #   #=> false
  #
  #   contract.matches?(
  #     { arguments: [], keywords: {}, block: Proc.new }
  #   )
  #   #=> true
  class ParametersContract < Stannum::Contracts::HashContract
    # Builder class for defining item constraints for a ParametersContract.
    #
    # This class should not be invoked directly. Instead, pass a block to the
    # constructor for ParametersContract.
    #
    # @api private
    class Builder < Stannum::Contracts::PropertyContract::Builder
      # Adds an argument constraint to the contract.
      #
      # If the index is specified, then the constraint will be added for the
      # argument at the specified index. If the index is not given, then the
      # constraint will be applied to the next unconstrained argument. For
      # example, the first argument constraint will be added for the argument at
      # index 0, the second constraint for the argument at index 1, and so on.
      #
      # @overload argument(name, type, index: nil, **options)
      #   Generates an argument constraint based on the given type. If the type
      #   is a constraint, then the given constraint will be copied with the
      #   given options and added for the argument at the index. If the type is
      #   a Class or a Module, then a Stannum::Constraints::Type constraint will
      #   be created with the given type and options and added for the argument.
      #
      #   @param name [String, Symbol] The name of the argument.
      #   @param type [Class, Module, Stannum::Constraints:Base] The expected
      #     type of the argument.
      #   @param index [Integer, nil] The index of the argument. If not given,
      #     then the next argument will be constrained with the type.
      #   @param options [Hash<Symbol, Object>] Configuration options for the
      #     constraint. Defaults to an empty Hash.
      #
      #   @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      #
      # @overload argument(name, index: nil, **options, &block
      #   Generates a new Stannum::Constraint using the block.
      #
      #   @param name [String, Symbol] The name of the argument.
      #   @param index [Integer, nil] The index of the argument. If not given,
      #     then the next argument will be constrained with the type.
      #   @param options [Hash<Symbol, Object>] Configuration options for the
      #     constraint. Defaults to an empty Hash.
      #
      #   @yield The definition for the constraint. Each time #matches? is
      #     called for this constraint, the given object will be passed to this
      #     block and the result of the block will be returned.
      #   @yieldparam actual [Object] The object to check against the
      #     constraint.
      #   @yieldreturn [true, false] true if the given object matches the
      #     constraint, otherwise false.
      #
      #   @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      def argument(name, type = nil, index: nil, **options, &block)
        type = resolve_constraint_or_type(type, **options, &block)

        contract.add_argument_constraint(
          index,
          type,
          property_name: name,
          **options
        )

        self
      end

      # Sets the variadic arguments constraint for the contract.
      #
      # If the parameters includes variadic (or "splatted") arguments, then each
      # item in the variadic arguments array must match the given type or
      # constraint. If the type is a constraint, then the given constraint will
      # be copied with the given options. If the type is a Class or a Module,
      # then a Stannum::Constraints::Type constraint will be created with the
      # given type.
      #
      # @param name [String, Symbol] a human-readable name for the variadic
      #   arguments; used in generating error messages.
      # @param type [Class, Module, Stannum::Constraints:Base] The expected type
      #   of the variadic arguments items.
      #
      # @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      #
      # @raise [RuntimeError] if there is already a variadic arguments
      #   constraint defined for the contract.
      def arguments(name, type)
        contract.set_arguments_item_constraint(name, type)

        self
      end

      # Sets the block parameter constraint for the contract.
      #
      # If the expected presence is true, a block must be given as part of the
      # parameters. If the expected presence is false, a block must not be
      # given. If the presence is a constraint, then the block must match the
      # constraint.
      #
      # @param present [true, false, Stannum::Constraint] The expected presence
      #   of the block.
      #
      # @return [Stannum::Contracts::ParametersContract] the contract.
      #
      # @raise [RuntimeError] if there is already a block constraint defined for
      #   the contract.
      def block(present)
        contract.set_block_constraint(present)

        self
      end

      # Adds a keyword constraint to the contract.
      #
      # @overload keyword(name, type, **options)
      #   Generates a keyword constraint based on the given type. If the type is
      #   a constraint, then the given constraint will be copied with the given
      #   options and added for the given keyword. If the type is a Class or a
      #   Module, then a Stannum::Constraints::Type constraint will be created
      #   with the given type and options and added for the keyword.
      #
      #   @param keyword [Symbol] The keyword to constrain.
      #   @param type [Class, Module, Stannum::Constraints:Base] The expected
      #     type of the keyword.
      #   @param options [Hash<Symbol, Object>] Configuration options for the
      #     constraint. Defaults to an empty Hash.
      #
      #   @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      #
      # @overload keyword(name, **options, &block)
      #   Generates a new Stannum::Constraint using the block.
      #
      #   @param keyword [Symbol] The keyword to constrain.
      #   @param options [Hash<Symbol, Object>] Configuration options for the
      #     constraint. Defaults to an empty Hash.
      #
      #   @yield The definition for the constraint. Each time #matches? is
      #     called for this constraint, the given object will be passed to this
      #     block and the result of the block will be returned.
      #   @yieldparam actual [Object] The object to check against the
      #     constraint.
      #   @yieldreturn [true, false] true if the given object matches the
      #     constraint, otherwise false.
      #
      #   @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      def keyword(name, type = nil, **options, &block)
        type = resolve_constraint_or_type(type, **options, &block)

        contract.add_keyword_constraint(
          name,
          type,
          **options
        )

        self
      end

      # Sets the variadic keywords constraint for the contract.
      #
      # If the parameters includes variadic (or "splatted") keywords, then each
      # value in the variadic keywords hash must match the given type or
      # constraint. If the type is a constraint, then the given constraint will
      # be copied with the given options. If the type is a Class or a Module,
      # then a Stannum::Constraints::Type constraint will be created with the
      # given type.
      #
      # @param name [String, Symbol] a human-readable name for the variadic
      #   keywords; used in generating error messages.
      # @param type [Class, Module, Stannum::Constraints:Base] The expected type
      #   of the variadic keywords values.
      #
      # @return [Stannum::Contracts::ParametersContract::Builder] the builder.
      #
      # @raise [RuntimeError] if there is already a variadic keywords constraint
      #   defined for the contract.
      def keywords(name, type)
        contract.set_keywords_value_constraint(name, type)

        self
      end

      private

      def resolve_constraint_or_type(type = nil, **options, &block)
        if block_given? && type
          raise ArgumentError, ambiguous_values_error(type), caller(1..-1)
        end

        return type if type.is_a?(Module) || valid_constraint?(type)

        return Stannum::Constraint.new(**options, &block) if block

        raise ArgumentError,
          "invalid constraint #{type.inspect}",
          caller(1..-1)
      end
    end

    # Adds an argument constraint to the contract.
    #
    # Generates an argument constraint based on the given type. If the type is
    # a constraint, then the given constraint will be copied with the given
    # options and added for the argument at the index. If the type is a Class or
    # a Module, then a Stannum::Constraints::Type constraint will be created
    # with the given type and options and added for the argument.
    #
    # If the index is specified, then the constraint will be added for the
    # argument at the specified index. If the index is not given, then the
    # constraint will be applied to the next unconstrained argument. For
    # example, the first argument constraint will be added for the argument at
    # index 0, the second constraint for the argument at index 1, and so on.
    #
    # @param index [Integer, nil] The index of the argument. If not given, then
    #   the next argument will be constrained with the type.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the argument.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @return [Stannum::Contracts::ParametersContract] the contract.
    def add_argument_constraint(index, type, **options)
      index ||= next_index

      unless index.is_a?(Integer)
        raise ArgumentError, 'index must be an integer'
      end

      constraint = Stannum::Support::Coercion.type_constraint(type, **options)

      arguments_contract.add_index_constraint(index, constraint, **options)

      self
    end

    # Adds a keyword constraint to the contract.
    #
    # Generates a keyword constraint based on the given type. If the type is
    # a constraint, then the given constraint will be copied with the given
    # options and added for the given keyword. If the type is a Class or a
    # Module, then a Stannum::Constraints::Type constraint will be created with
    # the given type and options and added for the keyword.
    #
    # @param keyword [Symbol] The keyword to constrain.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the argument.
    # @param options [Hash<Symbol, Object>] Configuration options for the
    #   constraint. Defaults to an empty Hash.
    #
    # @return [Stannum::Contracts::ParametersContract] the contract.
    def add_keyword_constraint(keyword, type, **options)
      unless keyword.is_a?(Symbol)
        raise ArgumentError, 'keyword must be a symbol'
      end

      constraint = Stannum::Support::Coercion.type_constraint(type, **options)

      keywords_contract.add_key_constraint(keyword, constraint, **options)

      self
    end

    # Sets the variadic arguments constraint for the contract.
    #
    # If the parameters includes variadic (or "splatted") arguments, then each
    # item in the variadic arguments array must match the given type or
    # constraint. If the type is a constraint, then the given constraint will be
    # copied with the given options. If the type is a Class or a Module, then a
    # Stannum::Constraints::Type constraint will be created with the given type.
    #
    # @param name [String, Symbol] a human-readable name for the variadic
    #   arguments; used in generating error messages.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the variadic arguments items.
    #
    # @return [Stannum::Contracts::ParametersContract] the contract.
    #
    # @raise [RuntimeError] if there is already a variadic arguments constraint
    #   defined for the contract.
    def set_arguments_item_constraint(name, type)
      arguments_contract.set_variadic_item_constraint(type, as: name)

      self
    end

    # Sets the block parameter constraint for the contract.
    #
    # If the expected presence is true, a block must be given as part of the
    # parameters. If the expected presence is false, a block must not be given.
    # If the presence is a constraint, then the block must match the constraint.
    #
    # @param present [true, false, Stannum::Constraint] The expected presence of
    #   the block.
    #
    # @return [Stannum::Contracts::ParametersContract] the contract.
    #
    # @raise [RuntimeError] if there is already a block constraint defined for
    #   the contract.
    def set_block_constraint(present) # rubocop:disable Naming/AccessorMethodName
      raise 'block constraint is already set' if @block_constraint

      @block_constraint = build_block_constraint(present)

      add_key_constraint(:block, @block_constraint)
    end

    # Sets the variadic keywords constraint for the contract.
    #
    # If the parameters includes variadic (or "splatted") keywords, then each
    # value in the variadic keywords hash must match the given type or
    # constraint. If the type is a constraint, then the given constraint will be
    # copied with the given options. If the type is a Class or a Module, then a
    # Stannum::Constraints::Type constraint will be created with the given type.
    #
    # @param name [String, Symbol] a human-readable name for the variadic
    #   keywords; used in generating error messages.
    # @param type [Class, Module, Stannum::Constraints:Base] The expected type
    #   of the variadic keywords values.
    #
    # @return [Stannum::Contracts::ParametersContract] the contract.
    #
    # @raise [RuntimeError] if there is already a variadic keywords constraint
    #   defined for the contract.
    def set_keywords_value_constraint(name, type)
      keywords_contract.set_variadic_value_constraint(type, as: name)

      self
    end

    private

    attr_reader :block_constraint

    def add_extra_keys_constraint; end

    def add_type_constraint
      add_constraint \
        Stannum::Contracts::Parameters::SignatureContract.new,
        sanity: true
    end

    def arguments_contract
      @arguments_contract ||=
        Stannum::Contracts::Parameters::ArgumentsContract.new
    end

    def build_block_constraint(value)
      Stannum::Support::Coercion.presence_constraint(value) \
      do |present, **options|
        next Stannum::Constraints::Types::Proc.new(**options) if present

        Stannum::Constraints::Types::Nil.new(**options)
      end
    end

    def define_constraints(&block)
      super(&block)

      add_key_constraint :arguments, arguments_contract
      add_key_constraint :keywords,  keywords_contract
    end

    def keywords_contract
      @keywords_contract ||=
        Stannum::Contracts::Parameters::KeywordsContract.new
    end

    def next_index
      @next_index ||= -1

      @next_index += 1
    end
  end
end
