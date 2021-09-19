# Stannum

A library for defining and validating data structures.

Stannum defines the following objects:

- [Constraints](#constraints): A validator object that responds to `#match`, `#matches?` and `#errors_for` for a given object.
- [Contracts](#contracts): A collection of constraints about an object or its properties. Obeys the `Constraint` interface.
- [Errors](#errors): Data object for storing validation errors. Supports arbitrary nesting of errors.
- [Structs](#structs): Defines a mutable data object with a specified set of typed attributes.

## About

Stannum provides a framework-independent toolkit for defining structured data entities and validations. It provides a middle ground between unstructured data (raw `Hash`es, `Structs`, or libraries like `Hashie`) and full frameworks like `ActiveModel`.

First and foremost, Stannum provides you with the tools to validate your data. Using a `Stannum::Constraint`, you can apply your validation logic to literally any object, whether pure Ruby or from any framework or toolkit. Stannum provides a range of pre-defined constraints, including constraints for validating object types, defined methods, and more. You can also define custom constraints for any check that can output either `true` or `false`.

Finally, you can combine your constraints into a `Stannum::Contract` to combine multiple validations of your object and its properties. Stannum provides pre-defined contracts for asserting on objects, `Array`s, `Hash`es, and even method parameters.

Stannum also defines the `Stannum::Struct` module for defining structured data entities that are not tied to any framework or datastore. Stannum structs have more functionality and a friendlier interface than a core library `Struct`, provide more structure than a `Hash` or hash-like object (such as an `OpenStruct` or `Hashie::Mash`), and are completely independent from the source of the data. Need to load seed data from a YAML configuration file, perform operations in a SQL database, cross-reference with a MongoDB data store, and use an in-memory data array for lightning-fast tests? A `Stannum::Struct` won't fight you every step of the way.

### Why Stannum?

Stannum is not tied to any framework. You can create constraints and contracts to validate Ruby objects and Structs, data structures such as Arrays, Hashes, and Sets, and even framework objects such as `ActiveRecord::Model`s and `Mongoid::Document`s.

Still, most projects and applications use one framework to handle their data. Why use Stannum constraints?

- **Composability:** Because Stannum contracts are their own objects, they can be combined together. Reuse validation logic without duplicating code or defining abstract ancestor classes .
- **Polymorphism:** Your data validation is separate from your model definitions. This gives you two major advantages over the traditional approach:
    - You can use the same contract to validate different objects. Do you have a shared concern that cuts across multiple domain objects, such as attaching images, having comments, or creating an audit trail? You can write one contract for the concern and apply that same contract to each applicable model or object.
    - You can use different contracts to validate the same object in different contexts. Need different validations for a regular user versus an admin? Need to handle published articles more strictly than drafts? Need to provide custom validations for each step in your state machine? Stannum has you covered, and because contracts are composable, you can pull in the constraints you need without duplicating your logic.
- **Separation of Concerns:** Your data validation is independent from your entities. This means that you can use the same tools to validate anything from controller parameters to models to configuration files.

### Compatibility

Stannum is tested against Ruby (MRI) 2.6 through 3.0.

### Documentation

Documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

### License

Copyright (c) 2019-2021 Rob Smith

Stannum is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/stannum.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/stannum/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/stannum/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Stannum` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/stannum/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

<!-- ## Getting Started  -->

## Reference

<a id="constraints"></a>

### Constraints

```ruby
require 'stannum/constraint'
```

Constraints provide the foundation for data validation in Stannum. Fundamentally, each `Stannum::Constraint`encapsulates a predicate - a statement that can be either true or false - that can be applied to other objects. If the statement is true about the object, that object "matches" the constraint. If the statement is false, the object does not match the constraint.

The easiest way to define a constraint is by passing a block to `Stannum::Constraint.new`:

```ruby
constraint = Stannum::Constraint.new do |object|
  object.is_a?(String) && !object.empty?
end
```

Here, we've created a very simple constraint, which will match any non-empty string and will not match empty strings or other objects. When you define a constraint using `Stannum::Constraint.new`, the constraint will pass for an object if and only if the block returns `true` for that object. We can also pass in additional metadata about the constraint such as a type or message to display - we will revisit this in [Errors, Types and Messages](#constraints-errors-types-messages), below.

#### Matching Objects

Defining a constraint is only half the battle - next, we need to use the constraint. Each `Stannum::Constraint` defines a standard set of methods to match objects.

First, the `#matches?` method will return true if the object matches the constraint, and will return false if the object does not match.

```ruby
constraint.matches?(nil)
#=> false

constraint.matches?('')
#=> false

constraint.matches?('Greetings, programs!')
#=> true
```

Knowing that an object does not match isn't always enough information - we need to know why. Stannum defines the `Stannum::Errors` object for this purpose (see [Errors](#errors), below). We can use the `#match` method to both check whether an object matches the constraint and return any errors with one method call.

```ruby
status, errors = constraint.matches?(nil)
status
#=> false
errors
#=> an instance of Stannum::Errors
errors.empty?
#=> false

status, errors = constraint.matches?('Greetings, programs!')
status
#=> true
errors
#=> an instance of Stannum::Errors
errors.empty?
#=> true
```

Finally, if we already know that an object does not match the constraint, we can check its errors using the `#errors_for` method.

```ruby
errors = constraint.errors_for(nil)
#=> an instance of Stannum::Errors
errors.empty?
#=> false
```

*Important Note:* Stannum **does not** guarantee that `#errors_for` will return an empty `Errors` object for an object that matches the constraint. Always check whether the object matches the constraint before checking the errors.

#### Negated Matching

A constraint can also be used to check if an object does not match the constraint. Each `Stannum::Constraint` defines helpers for the negated use case.

The `#does_not_match?` method is the inverse of `#matches?`. It will return false if the object matches the constraint, and will return true if the object does not match.

```ruby
constraint.does_not_match?(nil)
#=> true

constraint.does_not_match?('')
#=> true

constraint.does_not_match?('Greetings, programs!')
#=> false
```

Negated matches can also generate errors objects. Whereas the errors from a standard match will list how the object fails to match the constraint, the errors from a negated match will list how the object does match the constraint. The `#negated_match` method will both check that the object does not match the constraint and return the relevant errors, while the `#negated_errors_for` method will return the negated errors for a matching object.

<a id="constraints-errors-types-messages"></a>

#### Errors, Types and Messages

We can customize the error returned by the constraint for a non-matching object by setting the constraint type and/or message.

```ruby
constraint = Stannum::Constraint.new(
  message: 'must be even',
  type:    'example.constraints.even'
) { |i| i.even? }
```

The constraint `#type` identifies the kind of constraint. For example, a `case` or conditional statement that checks for an error of a particular variety would look at the error's type. The constraint `#message`, on the other hand, is a human-readable description of the error. A flash message or rendered might use the error's message to display the status to the user. An API response might provide both the type and the message.

The constraint type and message are used to generate the corresponding error:

```ruby
errors = constraint.errors_for(nil)
errors.count
#=> 1
errors.first.message
#=> 'must be even'
errors.first.type
#=> 'example.constraints.even'

```

The error message can also be generated automatically from the type (see [Generating Messages](#errors-generating-messages), below).

#### Constraint Subclasses

Defining a subclass of `Stannum::Constraint` allows for greater control over the predicate logic and the generated errors.

```ruby
class EvenIntegerConstraint < Stannum::Constraint
  NEGATED_TYPE = 'examples.constraints.odd'
  TYPE         = 'examples.constraints.even'

  def matches?(actual)
    actual.is_a?(Integer) && actual.even?
  end

  protected

  def update_errors_for(actual:, errors:)
    return super if actual.is_a?(Integer)

    errors.add('examples.constraints.type', type: Integer)
  end
end
```

Let's take it from the top. We start by defining `::NEGATED_TYPE` and `::TYPE` constraints. These serve two purposes: first, the constraint will use these values as the default `#type` and `#negated_type` properties, without having to pass in values to the constructor. Second, we are declaring the type of error this constraints will return to the rest of the code. This allows us to reference these values elsewhere, such as a `case` or conditional statement checking for the presense of this error.

Second, we define our `#matches?` method. This method takes one parameter (the object being matched) and returns either `true` or `false`. Our other matching methods - `#does_not_match?`, `#match`, and `#negated_match` - will delegate to this implementation unless we specifically override them.

Finally, we are defining the errors to be returned from our constraint using the `#update_errors_for` method. This method takes two keywords: `:actual`, which is the object being matched, and `:errors`, which is the `Stannum::Errors` object to which the errors for the constraint are added. If the object is an integer, then we fall back to the default behavior - `super` will add an error with a `#type` equal to the constraint's `#type` (or the `:type` passed into the constructor, if any). If the object is not an integer, then we instead display a custom error. In addition to the error `#type`, we are defining some error `#data`.

*Important Note:* We are overriding the `#update_errors_for` method, rather than the `#errors_for` method directly. This is because a contract (see [Contracts](#contracts), below) that includes this constraint will hook into `#update_errors_for` on a failure - this avoids allocating unnecessary errors objects for each constraint. For the same reason, `#update_errors_for` must be either `protected` (recommended) or `public` - marking this method as `private` will break contracts that include this constraint.

```ruby
errors = constraint.errors_for(nil)
errors.count
#=> 1
errors.first.type
#=> 'examples.constraints.type'
errors.first.data
#=> { type: Integer }

errors = constraint.errors_for('')
errors.count
#=> 1
errors.first.type
#=> 'examples.constraints.even'
errors.first.data
#=> {}
```

We can likewise define the behavior of the constraint when negated. We've already set the `::NEGATED_TYPE` constant, but we can go further and override the `#does_not_match?` and/or `#update_negated_errors_for` methods as well for full control over the behavior when performing a negated match.

<a id="contracts"></a>

### Contracts

```ruby
require 'stannum/contract'
```

A contract is a collection of constraints that validate an object and its properties. Each `Stannum::Contract` holds a set of `Stannum::Constraints`, each of which must match an object or the referenced property for that object to match the contract as a whole. Contracts also obey the Constraint interface, and can be used inside other contracts to compose complex or nested validations.

Like constraints, contracts can be created by passing a block to `Stannum::Contract.new`:

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

You can also add constraints to an existing contract using the `#add_constraint` method.

```ruby
constraint = Stannum::Constraint.new(type: 'examples.constraints.even') do |actual|
  actual.respond_to?(:even) && actual.even?
end

contract.add_constraint(constraint)

contract.matches?(5)
#=> false
contract.errors_for(99).map(&:type)
#=> ['examples.constraints.even']

contract.matches?(6)
#=> true
```

The `#add_constraint` method returns the contract, so you can chain multiple `#add_constraint` calls together.

#### Negated Matching

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

#### Property Constraints

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

#### Sanity Constraints

In some cases, before running through the full set of constraints in a contract, we want to run a quick sanity check to make sure the contract is even applicable to the object. By adding `sanity: true` when defining the constraint, you can mark a constraint as a sanity check.

```ruby
gadget_contract.add_constraint(Stannum::Constraints::Type.new(Gadget), sanity: true)
```

When matching an object, all of a contract's sanity constraints will be evaluated first. The remaining constraints will be matched against the object *only* if all of the sanity constraints match the object. This can be especially important if some of the constraints return nonsensical results or even raise exceptions when given an invalid object.

```ruby
gadget_contract.matches?(nil)
#=> false
gadget_contract.errors_for(nil).map { |err| [err.path, err.type] }
#=> [[[], 'stannum.constraints.is_not_type']]
```

Likewise, when performing a negated match, the sanity constraints will be evaluated first, and the remaining constraints will be evaluated only if all of the sanity constraints match.

<a id="array-contracts"></a>

#### Array Contracts

By default, a `Stannum::Contract` accesses an object's properties as method calls, using the `.` dot notation. When validating `Array`s and `Hash`es, this approach is less useful. Therefore, Stannum provides special contracts for operating on data structures.

A `Stannum::Contracts::ArrayContract` is used for validating sequential data, using the `#[]` method to access indexed values.

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

An `ArrayContract` will first validate that the object is an instance of `Array`. For validating Array-like objects that access indexed data using the `#[]` method, you can instead use a `Stannum::Contracts::TupleContract`.

<a id="hash-contracts"></a>

#### Hash Contracts

A `Stannum::Contracts::HashContract` is used for validating key-value data, using the `#[]` method to access values by key.

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

A `HashContract` will first validate that the object is an instance of `Hash`. For validating Hash-like objects that access key-value data using the `#[]` method, you can instead use a `Stannum::Contracts::MapContract`.

#### Contract Subclasses

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

    property :rotation_speed, Stannum::Constraints::Types::Float.new
  end
end
```

<a id="errors"></a>

### Errors

```ruby
require 'stannum/errors'
```

When a constraint or contract fails to match an object, Stannum can return the reasons for that failure in the form of an errors object. Specifically, a `Stannum::Errors` object is returned by calling `#errors_for` or `#negated_errors-for` with a failing object, or as part of the result of calling `#match` or `#negated_match`.

```ruby
contract.matches?(nil)
#=> false
contract.errors_for(nil)
#=> an instance of Stannum::Errors
status, errors = contract.match(nil)
status
#=> false
errors
#=> an instance of Stannum::Errors
```

A `Stannum::Errors` object is an `Enumerable` collection, while each error is a `Hash` with the following properties:

- `#type`: A unique value that defines what kind of error was encountered. Each error's type should be a namespaced `String`, e.g. `"stannum.constraints.invalid"`.
- `#data`: A `Hash` of additional data about the error. For example, a failed type validation will include the expected type for the value; a failed range validation might include the minimum and maximum allowable values.
- `#path`: The path of the error relative to the top-level object that was validated. The path is always an `Array`, and each item in the array is either an `Integer` or a non-empty `Symbol`. Some examples:
    - An error on the object itself will have an empty path, `[]`.
    - An error on the item at index `3`of an array would have a path of `[3]`.
    - An error on the `#name` property of an object would have a path of `[:name]`.
    - An error on the address of the first manufacturer would have a path of `[:manufacturers, 3, :address]`.
- `#message`: A human-readable description of the error. Error messages are not generated by default; either specify a message when defining the constraint, or call `#with_messages` to generate the error messages based on the error types and data. See [Generating Messages](errors-generating-messages), below.

The simplest way to access the errors in a `Stannum::Errors` object is via the `#each` method, which will yield each error in the collection to the given block. Because each `Stannum::Errors` is enumerable, you can use the standard `Enumerable` methods such as `#map`, `#reduce`, `#select`, and so on. You can also use `#count` to return the number of errors, or `#empty?` to check if there are any errors in the collection.

```ruby
errors.count
#=> 3
errors.empty?
#=> false
errors.first
#=> {
#     data: {},
#     message: nil,
#     path: [:name],
#     type: 'stannum.constraints.invalid'
#   }
errors.map(&:type)
#=> [
#     'stannum.constraints.invalid',
#     'stannum.constraints.absent',
#     'stannum.constraints.is_not_type'
#   ]
```

Usually, an errors object is generated automatically by a constraint or contract with its errors already defined. If you want to add custom errors to an errors object, use the `#add` method, which takes the error `type` as one required argument. You can also specify the `message` keyword, which sets the message of the error. Finally, any additional keywords are added to the error `data`.

```ruby
errors = Stannum::Errors.new
errors.count
#=> 0
errors.empty?
#=> true

errors.add('example.constraints.out_of_range', message: 'out of range', min: 0, max: 10)
#=> the errors object
errors.count
#=> 1
errors.empty?
#=> false
errors.first
#=> {
#     data: { min: 0, max: 10 },
#     message: 'out of range',
#     path: [],
#     type: 'example.constraints.out_of_range'
#   }
```

Conveniently, `#add` returns the errors object itself, so you can chain together multiple `#add` calls.

#### Nested Errors

To represent the properties of an object or the values in a data structure, `Stannum::Errors` can be nested together. Nested error objects are accessed using the `#[]` operator.

```ruby
errors = Stannum::Errors.new
errors[:manufacturers][0][:address].add('stannum.constraints.invalid')
errors[:manufacturers][0][:address]
#=> an instance of Stannum::Errors
errors[:manufacturers][0][:address].count
#=> 1
errors[:manufacturers][0][:address].first
#=> {
#     data: {},
#     message: nil,
#     path: [],
#     type: 'stannum.constraints.invalid'
#   }

errors.count
#=> 1
errors.first
#=> {
#     data: {},
#     message: nil,
#     path: [:manufacturers, 0, :address],
#     type: 'stannum.constraints.invalid'
#   }
```

You can also use the `#dig` method to access nested errors:

```ruby
errors.dig(:manufacturers, 0, :address).first
#=> {
#     data: {},
#     message: nil,
#     path: [],
#     type: 'stannum.constraints.invalid'
#   }
```

<a id="errors-generating-messages"></a>

#### Generating Messages

By default, errors objects do not generate messages. `Stannum::Errors` defines the `#with_messages` method to generate messages for a given errors object. If the `:force` keyword is set to true, then `#with_messages` will overwrite any messages that are already set on an error, whether from a constraint or generated by a different strategy.

```ruby
errors.first.message
#=> nil

errors = errors.with_messages.first.message
errors.first.message
#=> 'is invalid'
```

Stannum uses the strategy pattern to determine how error messages are generated. You can pass the `strategy:` keyword to `#with_messages` to force Stannum to use the specified strategy, or set the `Stannum::Messages.strategy` property to define the default for your application. The default strategy for Stannum uses an I18n-like configuration file to define messages based on the type and optionally the data for each error.

<a id="structs"></a>

### Structs

While constraints and contracts are used to validate data, structs are used to define and structure that data. Each `Stannum::Struct` contains a specific set of attributes, and each attribute has a type definition that is a `Class` or `Module` or the name of a Class or Module.

Structs are defined by creating a new class and including `Stannum::Struct`:

```ruby
class Gadget
  attribute :name,        String
  attribute :description, String,  optional: true
  attribute :quantity,    Integer, default:  0
end

gadget = Gadget.new(name: 'Self-Sealing Stem Bolt')
gadget.name
#=> 'Self-Sealing Stem Bolt'
gadget.description
#=> nil
gadget.attributes
#=> {
#     name:        'Self-Sealing Stem Bolt',
#     description: nil,
#     quantity:    0
#   }

gadget.quantity = 10
gadget.quantity
#=> 10

gadget[:description] = 'No one is sure what a self-sealing stem bolt is.'
gadget[:description]
#=> 'No one is sure what a self-sealing stem bolt is.'
```

Our `Gadget` class has three attributes: `#name`, `#description`, and `#quantity`, which we are defining using the `.attribute` class method.

We can initialize a gadget with values by passing the desired attributes to `.new`. We can read or write the attributes using either dot `.` notation or `#[]` notation. Finally, we can access all of a struct's attributes and values using the `#attributes` method.

`Stannum::Struct` defines a number of helper methods for interacting with a struct's attributes:

- `#[](attribute)`: Returns the value of the given attribute.
- `#[]=(attribute, value)`: Writes the given value to the given attribute.
- `#assign_attributes(values)`: Updates the struct's attributes using the given values. If an attribute is not given, that value is unchanged.
- `#attributes`: Returns a hash containing the attribute keys and values.
- `#attributes=(values)`: Sets the struct's attributes to the given values. If an attribute is not given, that attribute is set to `nil`.

For all of the above methods, if a given attribute is invalid or the attribute is not defined on the struct, an `ArgumentError` will be raised.

#### Attributes

A struct's attributes are defined using the `.attribute` class method, and can be accessed and enumerated using the `.attributes` class method on the struct class or via the `::Attributes` constant. Internally, each attribute is represented by a `Stannum::Attribute` instance, which stores the attribute's `:name`, `:type`, and `:attributes`.

```ruby
Gadget::Attributes
#=> an instance of Stannum::Schema
Gadget.attributes
#=> an instance of Stannum::Schema
Gadget.attributes.count
#=> 3
Gadget.attributes.keys
#=> [:name, :description, :quantity]
Gadget.attributes[:name]
#=> an instance of Stannum::Attribute
Gadget.attributes[:quantity].options
#=> { default: 0, required: true }
```

##### Default Values

Structs can define default values for attributes by passing a `:default` value to the `.attribute` call.

```ruby
class LightsCounter
  include Stannum::Struct

  attribute :count, Integer, default: 4
end

LightsCounter.new.count
#=> 4
```

##### Optional Attributes

Struct classes can also mark attributes as `optional`. When a struct is validated (see [Validation](#structs-validation), below), optional attributes will pass with a value of `nil`.

```ruby
class WhereWeAreGoing
  include Stannum::Struct

  attribute :roads, Object, optional: true
end
```

`Stannum` supports both `:optional` and `:required` as keys. Passing either `optional: true` or `required: false` will mark the attribute as optional. Attributes are required by default.

<a id="structs-validation"></a>

#### Validation

Each `Stannum::Struct` automatically generates a contract that can be used to validate instances of the struct class. The contract can be accessed using the `.contract` class method or via the `::Contract` constant.

```ruby
class Gadget
  attribute :name,        String
  attribute :description, String,  optional: true
  attribute :quantity,    Integer, default:  0
end

Gadget::Contract
#=> an instance of Stannum::Contract
Gadget.contract
#=> an instance of Stannum::Contract

gadget = Gadget.new
Gadget.contract.matches?(gadget)
#=> false
Gadget.contract.errors_for(gadget)
#=> [
#     {
#       data:    { type: String },
#       message: nil,
#       path:    [:name],
#       type:    'stannum.constraints.is_not_type'
#     }
#   ]

gadget = Gadget.new(name: 'Self-Sealing Stem Bolt')
Gadget.contract.matches?(gadget)
#=> true
```

You can also define additional constraints using the `.constraint` class method.

```ruby
class Gadget
  constraint :name, Stannum::Constraints::Presence.new

  constraint :quantity do |qty|
    qty >= 0
  end
end

gadget = Gadget.new(name: '')
Gadget.contract.matches?(gadget)
#=> false
Gadget.contract.errors_for(gadget)
#=> [
#     {
#       data:    {},
#       message: nil,
#       path:    [:name],
#       type:    'stannum.constraints.absent'
#     }
#   ]
```

The `.constraint` class method takes either an instance of `Stannum::Constraint` or a block. If given an attribute name, the constraint will be matched against the value of that attribute; otherwise, the constraint will be matched against the object itself.

<a id="builtin-constraints"></a>

### Built-In Constraints

Stannum defines a set of built-in constraints that can be used in any project.

**Absence Constraint**

The inverse of a [Presence constraint](#builtin-constraints-presence). Matches `nil`, and objects that both respond to `#empty?` and for whom `#empty?` returns true, such as empty `String`s, `Array`s and `Hash`es.

```ruby
constraint = Stannum::Constraints::Absence.new

constraint.matches?(nil)
#=> true
constraint.matches?('')
#=> true
constraint.matches?('Greetings, programs!')
#=> false
constraint.matches?(Object.new)
#=> false
```

**Anything Constraint**

Matches any object, even `nil`.

```ruby
constraint = Stannum::Constraints::Anything.new

constraint.matches?(nil)
#=> true
constraint.matches?(Object.new)
#=> true
constraint.matches?('Hello, world')
#=> true
```

**Boolean Constraint**

Matches `true` and `false`.

```ruby
constraint = Stannum::Constraints::Boolean.new

constraint.matches?(nil)
#=> false
constraint.matches?(Object.new)
#=> false
constraint.matches?(false)
#=> true
constraint.matches?(true)
#=> true
```

**Enum Constraint**

Matches any the specified values.

```ruby
constraint = Stannum::Constraints::Enum.new('red', 'blue', 'green')

constraint.matches?(nil)
#=> false
constraint.matches?('purple')
#=> false
constraint.matches?('red')
#=> true
constraint.matches?('green')
#=> true
```

**Identity Constraint**

Matches the given object.

```ruby
value      = 'Greetings, starfighter!'
constraint = Stannum::Constraints::Identity.new(value)

constraint.matches?(nil)
#=> false
constraint.matches?(value.dup)
#=> false
constraint.matches?(value)
#=> true
```

**Nothing Constraint**

Does not match any objects.

```ruby
constraint = Stannum::Constraints::Nothing.new

constraint.matches?(nil)
#=> false
constraint.matches?(Object.new)
#=> false
constraint.matches?('Hello, world')
#=> false
```

<a id="builtin-constraints-presence"></a>

**Presence Constraint**

Matches objects that are not `nil`, and that either do not respond to `#empty?` or for whom `#empty?` returns false.

```ruby
constraint = Stannum::Constraints::Presence.new

constraint.matches?(nil)
#=> false
constraint.matches?('')
#=> false
constraint.matches?('Greetings, programs!')
#=> true
constraint.matches?(Object.new)
#=> true
```

**Signature Constraint**

Matches if the object responds to all of the specified methods.

```ruby
constraint = Stannum::Constraints::Signature.new(:[], :keys)

constraint.matches?(nil)
#=> false
constraint.matches?([])
#=> false
constraint.matches?({})
#=> true
```

<a id="builtin-constraints-type"></a>

**Type Constraint**

Matches if the specified type is an ancestor of the object.

```ruby
constraint = Stannum::Constraints::Type.new(StandardError)

constraint.matches?(nil)
#=> false
constraint.matches?(Object.new)
#=> false
constraint.matches?(StandardError.new)
#=> true
constraint.matches?(ArgumentError.new)
#=> true
```

Type constraints can be `optional` by passing either `optional: true` or `required: false` to the constructor. An optional type constraint will also accept `nil` as a value.

```ruby
constraint = Stannum::Constraints::Type.new(String, optional: true)

constraint.matches?(nil)
#=> true
constraint.matches?(Object.new)
#=> false
constraint.matches?('a String')
#=> true
```

**Union Constraint**

Matches if the object matches any of the given constraints.

```ruby
constraint = Stannum::Constraints::Union.new(
  Stannum::Constraints::Type.new(String),
  Stannum::Constraints::Type.new(Symbol)
)

constraint.matches?(nil)
#=> false
constraint.matches?(Object.new)
#=> false
constraint.matches?('a String')
#=> true
constraint.matches?(:a_symbol)
#=> true
```

#### Type Constraints

Stannum also defines a set of built-in type constraints. Unless otherwise noted, these are identical to a [Type Constraint](#builtin-constraints-type) with the given Class.

```ruby
constraint = Stannum::Constraints::Types::StringType.new

constraint.matches?(nil)
#=> false
constraint.matches?(Object.new)
#=> false
constraint.matches?('a String')
#=> true
```

The following type constraints are defined:

- **ArrayType**
- **BigDecimalType**
- **DateTimeType**
- **DateType**
- **FloatType**
- **HashType**
- **IntegerType**
- **NilType**
- **ProcType**
- **StringType**
- **SymbolType**
- **TimeType**

In addition, the following type constraints have additional options or behavior.

**ArrayType Constraint**

You can specify an `item_type` for an `ArrayType` constraint. An object will only match if the object is an `Array` and all of the array's items are of the specified type or match the given constraint.

```ruby
constraint = Stannum::Constraints::Types::ArrayType.new(item_type: String)

constraint.matches?(nil)
#=> false
constraint.matches?([])
#=> true
constraint.matches?([1, 2, 3])
#=> false
constraint.matches?(['uno', 'dos', 'tres'])
#=> true
```

**HashType Constraint**

You can specify a `key_type` and/or a `value_type` for a `HashType` constraint. An object will only match if the object is a `Hash`, all of the hash's keys and/or values are of the specified type or match the given constraint.

```ruby
constraint = Stannum::Constraints::Types::HashType.new(key_type: String, value_type: Integer)

constraint.matches?(nil)
#=> false
constraint.matches?({})
#=> true
constraint.matches?({ ichi: 1 })
#=> false
constraint.matches?({ 'ichi' => 'one' })
#=> false
constraint.matches?({ 'ichi' => 1 })
```

There are predefined constraints for matching `Hash`es with common key types:

- **HashWithIndifferentKeys:** Matches keys that are either `String`s or `Symbol`s and not empty.
- **HashWithStringKeys:** Matches keys that are `String`s.
- **HashWithSymbolKeys:** Matches keys that are `Symbol`s.

<a id="signature-constraints"></a>

#### Signature Constraints

Stannum provides a small number of built-in signature constraints.

```ruby
constraint = Stannum::Constraints::Signatures::Map.new

constraint.matches?(nil)
#=> false
constraint.matches?([])
#=> false
constraint.matches?({})
#=> true
```

- **Map:** Matches objects that behave like a `Hash`. Specifically, objects responding to `#[]`, `#each`, and `#keys`.
- **Tuple:** Matches objects that behave like an `Array`. Specifically, objects responding to `#[]`, `#each`, and `#size`.

<a id="builtin-contracts"></a>

### Built-In Contracts

Stannum defines some pre-defined contracts.

**Array Contract**

Matches an instance of `Array` and defines the `.item` class method to add constraints on the array items. See also [Array Contracts](#array-contracts), above.

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
```

**Hash Contract**

Matches an instance of `Hash` and defines the `.key` class method to add constraints on the hash keys and values. See also [Hash Contracts](#hash-contracts), above.

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
```

Stannum also defines an `IndifferentHashContract` class, which will match against both string and symbol keys.

**Map Contract**

As a `HashContract`, but matches against any object which uses the `#[]` operator to access key-value data. See [Map Constraint](signature-constraints), above.

**Parameters Contract**

Matches the parameters of a method call.

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

Each `ParametersContract` defines `.argument`, `.keyword`, and `.block` class methods to define the expected method parameters.

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

The `.arguments` class method creates a constraint that matches against any arguments without an explicit `.argument` expectation. Likewise, the `.keywords` class method creates a constraint that matches against any keywords without an explicit `.keyword` expectation. The contract will automatically convert a Class into the corresponding Type constraint (see [Type Constraint](#builtin-constraints-type), above).

**Tuple Contract**

As an `ArrayContract`, but matches against any object which uses the `#[]` operator to access indexed data. See [Tuple Constraint](signature-constraints), above.
