---
breadcrumbs:
  - name: Documentation
    path: './'
---

# Constraints

Constraints provide the foundation for data validation in Stannum. Fundamentally, each `Stannum::Constraint`encapsulates a predicate - a statement that can be either true or false - that can be applied to other objects. If the statement is true about the object, that object "matches" the constraint. If the statement is false, the object does not match the constraint.

## Contents

- [Defining Constraints](#defining-constraints)
- [Matching Objects](#matching-objects)
- [Negated Matching](#negated-matching)
- [Errors, Types, And Messages](#errors-types-and-messages)
- [Constraint Subclasses](#constraint-subclasses)
- [Built-In Constraints](#built-in-constraints)

## Defining Constraints

The easiest way to define a constraint is by passing a block to `Stannum::Constraint.new`:

```ruby
constraint = Stannum::Constraint.new do |object|
  object.is_a?(String) && !object.empty?
end
```

Here, we've created a very simple constraint, which will match any non-empty string and will not match empty strings or other objects. When you define a constraint using `Stannum::Constraint.new`, the constraint will pass for an object if and only if the block returns `true` for that object. We can also pass in additional metadata about the constraint such as a type or message to display (see [Errors, Types and Messages](#errors-types-and-messages), below).

## Matching Objects

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

Knowing that an object does not match isn't always enough information - we need to know why. Stannum defines the `Stannum::Errors` object for this purpose (see [Errors](./errors)). We can use the `#match` method to both check whether an object matches the constraint and return any errors with one method call.

```ruby
status, errors = constraint.matches?(nil)
status
#=> false
errors
#=> an instance of Stannum::Errors
errors.empty?
#=> false

status, errors = constraint.match('Greetings, programs!')
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
errors.summary
#=> 'is invalid'
```

*Important Note:* Stannum **does not** guarantee that `#errors_for` will return an empty `Errors` object for an object that matches the constraint. Always check whether the object matches the constraint before checking the errors.

## Negated Matching

A constraint can also be used to check if an object does not match the constraint. Each `Stannum::Constraint` defines helpers for the negated use case.

The `#does_not_match?` method is the inverse of `#matches?`. It will return false if the object matches the constraint, and will return true if the object does not match.

```ruby
constraint.does_not_match?(nil)
#=> true

status, errors = constraint.negated_match('')
status
#=> true
errors
#=> an instance of Stannum::Errors
errors.empty?
#=> true

constraint.does_not_match?('Greetings, programs!')
#=> false
```

Negated matches can also generate errors objects. Whereas the errors from a standard match will list how the object fails to match the constraint, the errors from a negated match will list how the object does match the constraint. The `#negated_match` method will both check that the object does not match the constraint and return the relevant errors, while the `#negated_errors_for` method will return the negated errors for a matching object.

```ruby
errors = constraint.negated_errors_for('Greetings, programs!')
#=> an instance of Stannum::Errors
errors.empty?
#=> false
errors.summary
#=> 'is valid'
```

## Errors, Types and Messages

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

## Constraint Subclasses

Defining a subclass of `Stannum::Constraint` allows for greater control over the predicate logic and the generated errors.

```ruby
class EvenIntegerConstraint < Stannum::Constraint
  NEGATED_TYPE = 'examples.constraints.odd'
  TYPE         = 'examples.constraints.even'

  def errors_for(actual, errors: nil)
    return super if actual.is_a?(Integer)

    (errors || Stannum::Errors.new)
      .add('examples.constraints.type', type: Integer)
  end

  def matches?(actual)
    actual.is_a?(Integer) && actual.even?
  end
end
```

Let's take it from the top. We start by defining `::NEGATED_TYPE` and `::TYPE` constraints. These serve two purposes: first, the constraint will use these values as the default `#type` and `#negated_type` properties, without having to pass in values to the constructor. Second, we are declaring the type of error this constraints will return to the rest of the code. This allows us to reference these values elsewhere, such as a `case` or conditional statement checking for the presense of this error.

Second, we define our `#matches?` method. This method takes one parameter (the object being matched) and returns either `true` or `false`. Our other matching methods - `#does_not_match?`, `#match`, and `#negated_match` - will delegate to this implementation unless we specifically override them.

Finally, we are defining the errors to be returned from our constraint using the `#errors_for` method. This method takes one required argument `actual`, which is the object being matched. If the object is an integer, then we fall back to the default behavior: `super` will add an error with a `#type` equal to the constraint's `#type` (or the `:type` passed into the constructor, if any). If the object is not an integer, then we instead display a custom error. In addition to the error `#type`, we are defining some error `#data`. In addition, `#errors_for` can take an optional keyword `:errors`, which is either an instance of `Stannum::Errors` or `nil`. This allows the user to pass an existing errors object to `#errors_for`, which will add its own errors to the given errors object instead of creating a new one.

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

We can likewise define the behavior of the constraint when negated. We've already set the `::NEGATED_TYPE` constant, but we can go further and override the `#does_not_match?` and/or `#negated_errors_for` methods as well for full control over the behavior when performing a negated match.

## Built-In Constraints

Stannum includes a number of pre-defined constraints.

- [Boolean](./reference/stannum/constraints/boolean): A `Boolean` constraint will match either `true` or `false`.
- [Enum](./reference/stannum/constraints/enum): An `Enum` constraint matches any of the given values.
- [Equality](./reference/stannum/constraints/equality): An `Equality` constraint matches any object equal to the given value.
- [Format](./reference/stannum/constraints/format): A `Format` constraint matches any string containing the given substring or matching the given pattern.
- [Presence](./reference/stannum/constraints/presence): A `Presence` constraint matches any non-`nil` and non-`empty?` object. It's inverse is the [Absence](./reference/stannum/constraints/absence) constraint.
- [Signature](./reference/stannum/constraints/format): A `Signature` constraint matches objects that respond to the given methods.
- [Type](./reference/stannum/constraints/type): A `Type` constraint matches objects that are instances of the given class or method.
- [Uuid](./reference/stannum/constraints/format): A `Uuid` constraint matches a valid hyphen-separated UUID with either uppercase or lowercase alphanumeric characters.

Some constraints are more useful in specific situations or when building or testing advanced behavior:

- [Anything](./reference/stannum/constraints/anything): An `Anything` constraint will match all objects.
- [Delegator](./reference/stannum/constraints/delegator): A `Delegator` constraint defers its matching to another constraint.
- [Nothing](./reference/stannum/constraints/nothing): A `Nothing` constraint does not match any objects.
- [Union](./reference/stannum/constraints/union): A `Union` constraint matches any object that matches any of the given child constraints.

A full list can be found in the [Reference Documentation](./reference) in the [Constraints](./reference/stannum/constraints) namespace.

### Type Constraints

Stannum also includes a number of pre-defined [Type constraints](./reference/stannum/constraints/types), including [ArrayType](./reference/stannum/constraints/types/array-type), [HashType](./reference/stannum/constraints/types/hash-type), [IntegerType](./reference/stannum/constraints/types/integer-type), [NilType](./reference/stannum/constraints/types/nil-type), and [StringType](./reference/stannum/constraints/types/string-type).

A full list can be found in the [Reference Documentation](./reference) in the [Type Constraints](./reference/stannum/constraints/types) namespace.

{% include breadcrumbs.md %}
