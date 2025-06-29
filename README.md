# Stannum

A library for defining and validating data structures.

<blockquote>
  Read The
  <a href="https://www.sleepingkingstudios.com/stannum" target="_blank">
    Documentation
  </a>
</blockquote>

Stannum provides a framework-independent toolkit for defining structured data entities and validations. It provides a middle ground between unstructured data (raw `Hash`es, `Structs`, or libraries like `Hashie`) and full frameworks like `ActiveModel`.

It defines the following objects:

- [Constraints](http://sleepingkingstudios.github.io/stannum/constraints): A validator object that responds to `#match`, `#matches?` and `#errors_for` for a given object.
- [Contracts](http://sleepingkingstudios.github.io/stannum/contracts): A collection of constraints about an object or its properties. Obeys the `Constraint` interface.
- [Errors](http://sleepingkingstudios.github.io/stannum/errors): Data object for storing validation errors. Supports arbitrary nesting of errors.
- [Entities](http://sleepingkingstudios.github.io/stannum/entities): Defines a mutable data object with a specified set of typed attributes.

## Why Stannum?

Stannum is not tied to any framework. You can create constraints and contracts to validate Ruby objects and Entities, data structures such as Arrays, Hashes, and Sets, and even framework objects such as `ActiveRecord::Model`s and `Mongoid::Document`s.

Still, most projects and applications use one framework to handle their data. Why use Stannum constraints?

- **Composability:** Because Stannum contracts are their own objects, they can be combined together. Reuse validation logic without duplicating code or defining abstract ancestor classes .
- **Polymorphism:** Your data validation is separate from your model definitions. This gives you two major advantages over the traditional approach:
    - You can use the same contract to validate different objects. Do you have a shared concern that cuts across multiple domain objects, such as attaching images, having comments, or creating an audit trail? You can write one contract for the concern and apply that same contract to each applicable model or object.
    - You can use different contracts to validate the same object in different contexts. Need different validations for a regular user versus an admin? Need to handle published articles more strictly than drafts? Need to provide custom validations for each step in your state machine? Stannum has you covered, and because contracts are composable, you can pull in the constraints you need without duplicating your logic.
- **Separation of Concerns:** Your data validation is independent from your entities. This means that you can use the same tools to validate anything from controller parameters to models to configuration files.

### Compatibility

Stannum is tested against Ruby (MRI) 3.1 through 3.4.

### Documentation

Code documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

The full documentation is available via [GitHub Pages](http://sleepingkingstudios.github.io/stannum), and includes the code documentation as well as a deeper explanation of Stannum's features and design philosophy. It also includes documentation for prior versions of the gem.

To generate documentation locally, see the [SleepingKingStudios::Docs](https://github.com/sleepingkingstudios/sleeping_king_studios-docs) gem.

### License

Copyright (c) 2019-2025 Rob Smith

Stannum is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/stannum.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/stannum/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/stannum/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Stannum` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/stannum/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

## Getting Started
Let's take a look at using Stannum to model a problem domain. Consider the following case study: we are implementing an ecommerce application. We want to ensure that our Order object is valid through each stage of our ordering process. For the sake of simplicity, let's say our process has three steps:

- A customer creates an order.
- The customer is billed for the order.
- The order is shipped to the customer.

### Defining Entities

Our first step is to define some entities to represent our data.

```ruby
class Customer
  include Stannum::Entity

  define_primary_key :id, Integer

  define_attribute :email,   String
  define_attribute :address, String

  define_association :many, :orders
end
```

Our `Customer` class represents a user who can create an order in our system. We define an `#id` primary key, attributes `#email` and `#address`, and a plural association to our `Order` entity.

```ruby
class Payment
  include Stannum::Entity

  define_primary_key :id, Integer

  define_attribute :amount, BigDecimal

  define_association :one, :order, foreign_key: true
end
```

Our `Payment` class represents a payment submitted by our customer for an order. We again define an `#id` primary key, as well as an `#amount` attribute and a singular association to an `Order`. Note that we are specifying a foreign key for the `#order` association, which automatically creates an `#order_id` attribute.

```ruby
class Order
  include Stannum::Entity

  define_primary_key :id, Integer

  define_attribute :amount, BigDecimal

  define_association :one, :customer, foreign_key: true
  define_association :one, :payment

  constraint :customer, Stannum::Constraints::Presence.new
end
```

Our core class for this workflow is the `Order` entity. We define our `#id` and `#amount`, and associations to the `Customer` and `Payment` entities - again, by passing `foreign_key: true` to our `#customer` association, we also define a `#customer_id` attribute. Finally, we are defining an additional constraint. When validating the `Order` using the default contract, we will require the `#customer` association to be populated - an `Order` must always have an associated `Customer`. However, we are *not* requiring the presence of a `Payment`, since that requirement is not applicable to the entire `Order` lifecycle.

### Defining Validators

Actually implementing the business logic for orders is outside the scope of Stannum - for a structured approach to defining your business logic, take a look at the [Cuprum](https://www.sleepingkingstudios.com/cuprum/) gem.

However, that doesn't mean we're finished. One of the challenges in implementing a multi-step process like our ordering flow is validation. Specifically, this kind of workflow requires *contextual* validation - an `Order` object that is valid for one part of the flow may not be valid for others. Rather than defining conditional logic in our `Order` class, let's instead apply the concept of a Validator: an object that is responsible for validating an entity or data structure *in a particular context*.

Let's start with our first step, order creation. Creating an order requires a valid `#id`, a valid `#amount` (can be zero at this point in the workflow), and an associated `#customer`. Fortunately, we already have a contract defined for these requirements: the existing `Order::Contract`, which validates the entity's attributes and any additional `constraint`s defined on the entity.

Here's how we could use that in our business logic:

```ruby
customer = Customer.new(
  id:      0,
  email:   'user@example.com',
  address: '123 Example St'
)
order = Order.new(id: 1)

Order::Contract.matches?(order)
#=> false
errors = Order::Contract.errors_for(order)
#=> an instance of Stannum::Errors
errors.summary
#=> "amount: is not a BigDecimal, customer: is nil or empty"

order.amount   = BigDecimal('0.0')
order.customer = customer

Order::Contract.matches?(order)
#=> true
```

If our contract `#matches?` the order, we proceed with the creation logic. Otherwise, we return an error message, possibly using the errors `#summary`.

Now we move on to validating that an order is ready for billing. Our validation logic gets more complicated here: in addition to requiring a valid order (the same validations as above), we need to make sure that the billable amount is greater than zero.

One common approach is to add conditional validation to the `Order` class itself. For example, defining a `#status` attribute asserting that the `#amount` is greater than zero if the status matches a value. However, as new cases and conditions are added, this approach quickly becomes difficult to read and reason about. Instead, we're going to define a validator object.

```ruby
module Orders
  module Contracts
    IS_BILLABLE = Stannum::Contract.new do
      concat(Order::Contract)

      property :amount,
        message: 'must be greater than zero',
        type:    'orders.constraints.greater_than_zero' \
      do |value|
        value.is_a?(Numeric) && value > 0
      end
      property :payment, Stannum::Constraints::Types::NilType.new
    end
  end
end
```

Our validator is an instance of `Stannum::Contract`, and our first step is to `concat` the existing `Order::Contract`. This means that all of the constraints in the `Order::Contract` will also be applied when matching an order with the `IS_BILLABLE` contract. This means we don't need to duplicate our existing constraints.

Second, we are adding a custom `constraint` on the `#amount` attribute. Notice that the first check inside the block checks that the value is `Numeric`; otherwise, comparing a `nil` value would raise an exception, rather than failing the validation. We are also defining a custom `message` and `type` for the constraint. The `message` is intended to be a human-readable representation of the error, while the `type` is intended for machines.

Finally, we validate that the `#payment` association is nil, since we don't want to accidentally bill the same order twice. Here we can see why a validator object is so powerful - we obviously can't add this kind of constraint directly to `Order`, since orders later in the workflow will clearly not match. However, since our `IS_BILLABLE` contract applies only to this specific context, we can make the validation logic as specific as we want.

Our final step is to ship the order to the customer. Again, to determine if the order is ready to be shipped, we define a validator object:

```ruby
module Orders
  module Contracts
    IS_SHIPPABLE = Stannum::Contract.new do
      concat(Order::Contract)

      property :payment, Stannum::Constraints::Presence.new

      property :customer, Stannum::Contract.new {
        property :address, Stannum::Constraints::Presence.new
      }
    end
  end
end
```

Again, we define a custom `Stannum::Contract` and `concat` the existing `Order::Contract`, and we add a constraint that the `#payment` association needs to be populated - we don't want to ship an order that hasn't been paid for yet. Next, we define a nested contract to assert that the `#customer` association has a present `#address` attribute. You can define complex validation logic easily by composing together multiple constraints and contracts.

Here is how we would use the `IS_BILLABLE` and `IS_SHIPPABLE` contracts in our business logic:

```ruby
customer = Customer.new(
  id:      0,
  email:   'user@example.com',
  address: '123 Example St'
)
order = Order.new(id: 1, customer:)

Orders::Contracts::IS_BILLABLE.matches?(order)
#=> false
errors = Orders::Contracts::IS_BILLABLE.errors_for(order)
errors.summary
#=> "amount: is not a BigDecimal, amount: must be greater than zero"

order.amount = BigDecimal('100.0')
Orders::Contracts::IS_BILLABLE.matches?(order)
#=> true

Orders::Contracts::IS_SHIPPABLE.matches?(order)
#=> false
errors = Orders::Contracts::IS_SHIPPABLE.errors_for(order)
errors.summary
#=> "payment: is nil or empty"

order.payment = Payment.new(id: 2, amount: order.amount)
Orders::Contracts::IS_SHIPPABLE.matches?(order)
#=> true
```

As we define our `BillOrder` and `ShipOrder` classes, we will be able to use our `IS_BILLABLE` and `IS_SHIPPABLE` contracts to quickly identify orders that are invalid for that context.

### Validating Other Data

In addition to using them with entities, `Stannum` constraints and contracts can be used to validate almost any sort of data. For example, consider our ordering workflow. Perhaps we make a API call to a company that actually ships the order to the customer. We want to ensure that the API response contains the expected data. We can define a contract to validate the returned JSON body:

```ruby
SUCCESS_RESPONSE_CONTRACT = Stannum::Contract.new do
  property :status, Stannum::Constraints::Identity.new(200)

  property :body, Stannum::Contracts::HashContract.new {
    key 'ok', Stannum::Constraints::Identity.new(true)

    key 'shipping_confirmation',
      Stannum::Constraint.new(
        message: 'be a string with length 24',
        type:    'orders.constraints.valid_shipping_confirmation'
      ) { |value|
        value.is_a?(String) && value.size == 24
      }
  }
end
```

We can then validate the API response by calling `SUCCESS_RESPONSE_CONTRACT.matches?(response)`.
