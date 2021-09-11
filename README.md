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

@todo

<a id="errors"></a>

### Errors

@todo

#### Nesting Errors

@todo

<a id="errors-generating-messages"></a>

#### Generating Messages

@todo

<a id="structs"></a>

### Structs

@todo

### Builtin Constraints

@todo

### Builtin Contracts

@todo
