---
breadcrumbs:
  - name: Documentation
    path: './'
---

# Contracts

A contract is a collection of [constraints](./constraints) that validate an object and its properties. Each `Stannum::Contract` holds a set of `Stannum::Constraints`, each of which must match an object or the referenced property for that object to match the contract as a whole. Contracts also obey the Constraint interface, and can be used inside other contracts to compose complex or nested validations.

## Contents

- [Defining Contracts](#defining-contracts)
- [Matching Objects](#matching-objects)
- [Negated Matching](#negated-matching)
- [Adding Constraints](#adding-constraints)
  - [Property Constraints](#property-constraints)
  - [Sanity Constraints](#sanity-constraints)
- [Combining Contracts](#combining-contracts)
- [Contract Subclasses](#contract-subclasses)
- [Built-In Contracts](#built-in-contracts)
  - [Array Contracts](#array-contracts)
  - [Hash Contracts](#hash-contracts)
  - [Parameters Contracts](#parameters-contracts)

### See Also

- [Constraints](./constraints)
- [Errors](./errors)

## Defining Contracts

Contracts can be created by passing a block to `Stannum::Contract.new`:

```ruby
contract = Stannum::Contract.new do
  constraint(type: 'examples.constraints.numeric') do |actual|
    actual.is_a?(Numeric)
  end

  constraint(type: 'examples.constraints.integer') do |actual|
    actual.is_a?(Integer)
  end

  constraint(type: 'examples.constraints.in_range') do |actual|
    actual >= 0 && actual <= 10 rescue false
  end
end
```

## Matching Objects

Like constraints, contracts are used to determine whether objects match the expected behavior.

```ruby
contract.matches?(nil)
#=> false
contract.errors_for(nil).map(&:type)
#=> ['examples.constraints.numeric', 'examples.constraints.integer', 'examples.constraints.in_range']

contract.matches?(99.0)
#=> false
contract.errors_for(99.0).map(&:type)
#=> ['examples.constraints.integer', 'examples.constraints.in_range']

contract.matches?(99)
#=> false
contract.errors_for(99).map(&:type)
#=> ['examples.constraints.in_range']

contract.matches?(5)
#=> true
```

As you can see, the contract matches the object against each of its constraints. If any of the constraints fail to match the object, then the contract also does not match. Finally, the errors from each failing constraint are aggregated together.

## Negated Matching

Like a constraint, a contract can perform a negated match. Whereas an object matches the contract if **all** of the constraints match the object, the object will pass a negated match if **none** of the constraints match the object.

```ruby
contract = Stannum::Contract.new do
  constraint(type: 'examples.constraints.color') do |hsh|
    hsh[:color] == 'red'
  end

  constraint(type: 'examples.constraints.shape') do |hsh|
    hsh[:color] == 'circle'
  end
end

contract.matches?({ color: 'red', shape: 'circle' })
#=> true
contract.does_not_match?({ color: 'red', shape: 'circle' })
#=> false
contract.errors_for({ color: 'red', shape: 'square' }).map(&:type)
#=> ['examples.constraints.color', 'examples.constraints.shape']

contract.matches?({ color: 'red', shape: 'square' })
#=> false
contract.does_not_match?({ color: 'red', shape: 'square' })
#=> false
contract.errors_for({ color: 'red', shape: 'square' }).map(&:type)
#=> ['examples.constraints.color']

contract.matches?({ color: 'blue', shape: 'square'})
#=> false
contract.does_not_match?({ color: 'blue', shape: 'square'})
#=> true
```

Note that for an object that partially matches the contract, both `#matches?` and `#does_not_match?` methods will return false. If you want to check whether **any** of the constraints do not match the object, use the `#matches?` method and apply the `!` boolean negation operator (or switch from an `if` to an `unless`).

## Adding Constraints

You can also add constraints to an existing contract using the `#add_constraint` method.

```ruby
constraint = Stannum::Constraint.new(type: 'examples.constraints.even') do |actual|
  actual.respond_to?(:even) && actual.even?
end

contract.add_constraint(constraint)
#=> true
```

The `#add_constraint` method returns the contract, so you can chain multiple `#add_constraint` calls together.

### Property Constraints

Constraints can also define constraints on the *properties* of the matched object. This is a powerful feature for defining validations on objects and nested data structures. To define a property constraint, use the `property` macro in a contract constructor block, or use the `#add_property_constraint` method on an existing contract.

```ruby
gadget_contract = Stannum::Contract.new do
  property :name, Stannum::Constraints::Presence.new

  property :name, Stannum::Constraints::Types::StringType.new

  property(:size, type: 'examples.constraints.size') do |size|
    %w[small medium large].include?(size)
  end

  property :manufacturer, Stannum::Contract.new do
    constraint Stannum::Constraints::Presence.new

    property :address, Stannum::Constraints::Presence.new
  end
end
```

There's a lot going on here, so let's break it down. First, we're defining constraints on the *properties* of the object, rather than on the object as a whole. In particular, note that we're setting multiple constraints on the `:name` property - an object will only match the contract if it's `#name` matches both of those constraints.

We're also using some pre-defined constraints, rather than having to start from scratch. The `Presence` constraint validates that an object is not `nil` and not `#empty?`, while the `Types::StringType` constraint validates that the object is an instance of `String`. For a full list of pre-defined constraints, see [Built-In Constraints](#builtin-constraints) and [Contracts](#builtin-contracts), below. You can also define your own constraint classes and reference them in your contracts.

Finally, note that the constraint for the `:manufacturer` property is itself a contract. We are asserting that the actual object has a non-`nil` `#manufacturer` property and that the manufacturer's `#address` is also non-`nil` (and not `#empty?`).

```ruby
gadget = Gadget.new(manufacturer: Manufacturer.new)
gadget_contract.matches?(gadget)
#=> false
gadget_contract.errors_for(gadget).map { |err| [err.path, err.type] }
#=> [
#     [%i[name], 'stannum.constraints.absent'],
#     [%i[name], 'stannum.constraints.is_not_type'],
#     [%i[size], 'examples.constraints.size'],
#     [%i[manufacturer address], 'stannum.constraints.absent']
#   ]
```

We've established that each error has a `#type`, which identifies which type of constraint failed to match the object. Here, we can see that each error also has a `#path` property, which represents the relative path of the property from the original matched object. For example, errors on the `gadget.name` property will have a path of `%i[name]`, while the error on the `gadget.manufacturer.address` will have a path of `%i[manufacturer address]`. A constraint without a property, i.e. on the matched object itself, will have a path of `[]`, an empty string.

The errors for a property or nested contract can also be accessed using the `#[]` operator or the `#dig` method.

```ruby
gadget_contract.errors_for(gadget)[:manufacturer].map { |err| [err.path, err.type] }
#=> [[%i[address], 'stannum.constraints.absent']]

gadget_contract.errors_for(gadget).dig(:manufacturer, :address).map { |err| [err.path, err.type] }
#=> [[[], 'stannum.constraints.absent']]
```

Be careful when defining property constraints on a contract that might be matched against `nil` or an unknown object type - Ruby will raise a `NoMethodError` when trying to access the property. To avoid this, you can add a sanity constraint (see below) to ensure that the contract only validates the expected type of object.

### Sanity Constraints

In some cases, before running through the full set of constraints in a contract, we want to run a quick sanity check to make sure the contract is even applicable to the object. By adding `sanity: true` when defining the constraint, you can mark a constraint as a sanity check.

```ruby
contract = Stannum::Contract.new do
  constraint(type: 'examples.constraints.nonzero') do |actual|
    actual != 0
  end
end

contract.add_constraint(
  Stannum::Constraints::Types::IntegerType.new,
  type:   'examples.constraints.numeric',
  sanity: true
)
```

When matching an object, all of a contract's sanity constraints will be evaluated first. The remaining constraints will be matched against the object *only* if all of the sanity constraints match the object. This can be especially important if some of the constraints return nonsensical results or even raise exceptions when given an invalid object.

```ruby
contract.matches?(nil)
#=> false
contract.errors_for(nil).map(&:type)
#=> ['examples.constraints.numeric']

contract.matches?(0)
#=> false
contract.errors_for(0).map(&:type)
#=> ['examples.constraints.nonzero']

contract.matches?(1)
#=> true
```

Likewise, when performing a negated match, the sanity constraints will be evaluated first, and the remaining constraints will be evaluated only if all of the sanity constraints match.

## Combining Contracts

Stannum provides two mechanisms for composing contracts together. Each contract is a constraint, and so can be added to another contract (with or without a property or scope). This allows you to create and reuse validation logic simply by adding a contract as a constraint:

```ruby
named_contract = Stannum::Contract.new do
  property :name, Stannum::Constraints::Presence.new
end

widget_contract = Stannum::Contract.new do
  constraint(Stannum::Constraints::Type.new(Widget))

  constraint(named_contract)
end

widget = Widget.new
widget_contract.matches?(Widget.new)
#=> false
widget_contract.matches?(Widget.new(name: 'Whirlygig'))
#=> true
```

The second mechanism is contract *concatenation*. Under the hood, concatenation directly pulls in the constraints from a concatenated contract, rather than evaluating that contract on its own. This can be likened to inheriting methods from a superclass or an included Module.

```ruby
gadget_contract = Stannum::Contract.new do
  constraint(Stannum::Constraints::Type.new(Gadget))

  concat(named_contract)
end
```

Using concatenation, you have finer control over the constraints that are added to the contract. Specifically, when defining a contract you can mark certain constraints as excluded from concatenation by adding the `concatenatable: false` keyword to `#add_constraint`. As an example, this can be useful if you want to inherit constraints about the properties of an object, but not potentially conflicting constraints about the object's type.

## Contract Subclasses

For most use cases, defining a custom contract subclass will involve adding default constraints for the contact. Stannum provides two easy methods for doing so. First, you can leverage the default behavior by passing a block to `super` in the contract constructor. This will allow you to take advantage of the `constraint`, `property`, and other macros.

```ruby
class GizmoContract
  def initialize(**_options)
    super do
      constraint Stannum::Constraints::Type.new(Gizmo), sanity: true

      property :complexity, Stannum::Constraints::Presence.new
    end
  end
end
```

As an alternative, `Stannum::Contract` defines a private `#define_constraints` method that is used to initialize any constraints.

```ruby
class WhirlygigContract
  private

  def define_constraints
    super

    constraint Stannum::Constraints::Type.new(Whirlygig), sanity: true

    property :rotation_speed, Stannum::Constraints::Types::FloatType.new
  end
end
```

## Built-In Contracts

By default, a `Stannum::Contract` accesses an object's properties as method calls, using the `.` dot notation. When validating `Array`s and `Hash`es, this approach is less useful. Therefore, Stannum provides special contracts for operating on data structures.

- [ArrayContract](#array-contracts): An `ArrayContract` validates sequential data.
- [HashContract](#hash-contracts): A `HashContract` validates key-value data.
- [ParametersContract](#parameters-contracts): A `ParametersContract` validates parameters for a method call.

A full list can be found in the [Reference Documentation](./reference) in the [Contracts](./reference/stannum/contracts) namespace.

### Array Contracts

An [ArrayContract](./reference/stannum/contracts/array-contract) is used for validating sequential data, using the `#[]` method to access indexed values.

```ruby
class BaseballContract < Stannum::Contracts::ArrayContract
  def initialize
    super do
      item { |actual| actual == 'Who' }
      item { |actual| actual == 'What' }
      item { |actual| actual == "I Don't Know" }
    end
  end
end

contract = BaseballContract.new
contract.matches?(nil)
#=> false
contract.errors_for(nil).map { |err| [err.path, err.type] }
#=> [[[], 'stannum.constraints.is_not_type']]

array = %w[Who What]
contract.matches?(array)
#=> false
contract.errors_for(array).map { |err| [err.path, err.type] }
#=> [[[2], 'stannum.constraints.invalid']]

array = ['Who', 'What', "I Don't Know"]
contract.matches?(array)
#=> true

array = ['Who', 'What', "I Don't Know", 'Tomorrow']
contract.matches?(array)
#=> false
contract.errors_for(array).map { |err| [err.path, err.type] }
#=> [[[3], 'stannum.constraints.tuples.extra_items']]
```

Here, we are defining an ArrayContract using the `#item` macro, which defines an item constraint for each successive item in the array. We can also define a property constraint using the `#property` macro, using an Integer as the property to validate. This would allow us to add multiple constraints for the value at a given index, although the recommended approach is to use a nested contract.

When matching an object, the contract first validates that the object is an instance of `Array`. If not, it will immedidately fail matching and the remaining constraints will not be matched against the object. If the object is an an array, then the contract checks each of the defined constraints against the value of the array at that index.

Finally, the constraint checks for the highest index expected by an item constraint. If the array contains additional items after this index, those items will fail with a type of `"extra_items"`. To allow additional items instead, pass `allow_extra_items: true` to the `ArrayContract` constructor.

```ruby
contract = BaseballContract.new(allow_extra_items: true)
contract.matches?(['Who', 'What', "I Don't Know", 'Tomorrow'])
#=> true
```

An `ArrayContract` will first validate that the object is an instance of `Array`. For validating Array-like objects that access indexed data using the `#[]` method, you can instead use a [TupleContract](./reference/stannum/contracts/tuple-contract).

### Hash Contracts

A [HashContract](./reference/stannum/contracts/hash-contract) is used for validating key-value data, using the `#[]` method to access values by key.

```ruby
class ResponseContract < Stannum::Contracts::HashContract
  def initialize
    super do
      key :status, Stannum::Constraints::Types::IntegerType.new

      key :json,
        Stannum::Contracts::HashContract.new(allow_extra_keys: true) do
          key :ok, Stannum::Constraints::Boolean.new
        end

      key :signature, Stannum::Constraints::Presence.new
    end
  end
end

contract = ResponseContract.new
contract.matches?(nil)
#=> false
contract.errors_for(nil).map { |err| [err.path, err.type] }
#=> [[[], 'stannum.constraints.is_not_type']]

response = { status: 500, json: {} }
contract.matches?(response)
#=> false
contract.errors_for(response).map { |err| [err.path, err.type] }
#=> [
#     %i[json ok], 'stannum.constraints.is_not_boolean'],
#     %i[signature], 'stannum.constraints.absent'
#   ]

response = { status: 200, json: { ok: true }, signature: '12345' }
contract.matches?(response)
#=> true

response = { status: 200, json: { ok: true }, signature: '12345', role: 'admin' }
#=> false
contract.errors_for(response).map { |err| [err.path, err.type] }
#=> [[%i[role], 'stannum.constraints.hashes.extra_keys']]
```

We define a HashContract using the `#key` macro, which defines a key-value constraint for the specified value in the hash. When validating a Hash, the value at each key must match the given constraint. The contract will also fail if there are additional keys without a corresponding constraint. To allow additional keys instead, pass `allow_extra_keys: true` to the `HashContract` constructor.

```ruby
contract = ResponseContract.new(allow_extra_keys: true)
response = { status: 200, json: { ok: true }, signature: '12345', role: 'admin' }
contract.matches?(response)
#=> true
```

A `HashContract` will first validate that the object is an instance of `Hash`. For validating Hash-like objects that access key-value data using the `#[]` method, you can instead use a [MapContract](./reference/stannum/contracts/map-contract).

### Parameters Contracts

A [ParametersContract](#parameters-contracts) is used for validating parameters for a method call.

```ruby
class AuthorizationParameters < Stannum::Contracts::ParametersContract
  def initialize
    super do
      argument :action, Symbol
      argument :record_class, Class, default: true

      keyword :role, String, default: true
      keyword :user, Stannum::Constraints::Type.new(User)
    end
  end
end

contract   = AuthorizationParameters.new
parameters = {
  arguments: [:create, Article],
  keywords:  {},
  block:     nil
}
contract.matches?(parameters)
#=> false
errors = contract.errors_for(parameters)
errors[:arguments].empty?
#=> true
errors[:keywords].empty?
#=> false
```

Each `ParametersContract` defines `.argument`, `.keyword`, and `.block` class methods to define the expected method parameters. The contract will automatically convert a Class into the corresponding [Type constraint](./reference/stannum/constraints/type).

- The `.argument` class method defines an expected argument. Like the `.item` class method in an `ArrayContract` (see [Array Contracts](#array-contracts), above), each call to `.argument` will reference the next positional argument.
- The `.keyword` class method defines an expected keyword.
- The `.block` class method can accept either a constraint, or `true` or `false`. If given a constraint, the block passed to the method will be matched against the constraint. If given `true`, then the contract will match against any block and will fail if the method is not called with a block; likewise, if given `false`, the contract will match if no block is given and fail if the method is called with a block.

Because of Ruby's semantics around arguments and keywords with default values, the `:default` keyword has a special meaning for parameters contracts. If `.argument` or `.keyword` is called with the `:default` keyword, it indicates that that parameter has a default value in the method definition. If that argument or keyword is *omitted*, the parameters will still match the contract. However, an explicit value of `nil` will still fail unless `nil` is a valid value for the relevant constraint.

`ParametersContract` also has support for variadic arguments and keywords.

```ruby
class RecipeParameters < Stannum::Contracts::ParametersContract
  def initialize
    super do
      arguments :tools,       String
      keywords  :ingredients, Stannum::Contracts::TupleContract.new do
        item Stannum::Constraints::Type.new(String),
          property_name: :amount
        item Stannum::Constraints::Type.new(String, optional: true),
          property_name: :unit
      end
      block     true
    end
  end
end
```

The `.arguments` class method creates a constraint that matches against any arguments without an explicit `.argument` expectation. Likewise, the `.keywords` class method creates a constraint that matches against any keywords without an explicit `.keyword` expectation - each key-value pair is converted to an Array with two items.

{% include breadcrumbs.md %}
