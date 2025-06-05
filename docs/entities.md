---
breadcrumbs:
  - name: Documentation
    path: './'
---

# Entities

Entities are used to define and structure that data. Each `Stannum::Entity` contains a specific set of attributes, and each attribute has a type definition that is a `Class` or `Module` or the name of a Class or Module.

## Contents

- [Defining Entities](#defining-entities)
- [Properties](#properties)
- [Attributes](#attributes)
  - [Attribute Methods](#attribute-methods)
  - [Default Values](#default-values)
  - [Optional Attributes](#optional-attributes)
  - [Primary Keys](#primary-keys)
- [Validation](#validation)

## Defining Entities

Entities are defined by creating a new class and including `Stannum::Entity`:

```ruby
require 'stannum'

class Gadget
  include Stannum::Entity

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

We can initialize a gadget with values by passing the desired attributes to `.new`. We can read or write the attributes using either dot `.` notation or `#[]` notation. Finally, we can access all of a entity's attributes and values using the `#attributes` method.

`Stannum::Entity` defines a number of helper methods for interacting with a entity's attributes:

- `#[](attribute)`: Returns the value of the given attribute.
- `#[]=(attribute, value)`: Writes the given value to the given attribute.
- `#assign_attributes(values)`: Updates the entity's attributes using the given values. If an attribute is not given, that value is unchanged.
- `#attributes`: Returns a hash containing the attribute keys and values.
- `#attributes=(values)`: Sets the entity's attributes to the given values. If an attribute is not given, that attribute is set to `nil`.

For all of the above methods, if a given attribute is invalid or the attribute is not defined on the entity, an `ArgumentError` will be raised.

## Properties

An entity's `#properties` represent all of the data associated with an entity, including the entity's [attributes](#attributes) and [associations](#associations). When an entity is initialized, the keys and values passed to the constructor are used to initialize the entity's properties.

`Stannum::Entity` defines a number of helper methods for interacting with a entity's properties:

- `#[](property)`: Returns the value of the given property. The property name can be either a `String` or a `Symbol`.
- `#[]=(property, value)`: Writes the given value to the given property.
- `#assign_properties(values)`: Updates the entity's properties using the given values. If a property is not given, that value is unchanged.
- `#properties`: Returns a hash containing the property keys and values.
- `#properties=(values)`: Sets the entity's properties to the given values. If an attribute is not given, that property is set to `nil`.

For all of the above methods, if a given property is invalid or the property is not defined on the entity, an `ArgumentError` will be raised.

## Attributes

A entity's attributes are defined using the `.attribute` class method, and can be accessed and enumerated using the `.attributes` class method on the entity class or via the `::Attributes` constant. Internally, each attribute is represented by a `Stannum::Attribute` instance, which stores the attribute's `:name`, `:type`, and `:attributes`.

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

In addition to the [properties](#properties) methods, `Stannum::Entity` defines a number of helper methods for interacting with a entity's attributes as a whole:

- `#assign_attributes(values)`: Updates the entity's attributes using the given values. If an attribute is not given, that value is unchanged.
- `#attributes`: Returns a hash containing the attribute keys and values.
- `#attributes=(values)`: Sets the entity's attributes to the given values. If an attribute is not given, that attribute is set to `nil`.

For all of the above methods, if a given attribute is invalid or the attribute is not defined on the entity, an `ArgumentError` will be raised.

### Attribute Methods

Each attribute automatically defines reader and writer methods on the entity:

```ruby
gadget = Gadget.new(name: 'Self-Sealing Stem Bolt')
gadget.name
#=> 'Self-Sealing Stem Bolt'

gadget.name = 'Can of Headlight Fluid'
gadget.name
#=> 'Can of Headlight Fluid'
```

Attributes can also be accessed and updated using the `#[]` and `#[]=` methods:

```ruby
gadget = Gadget.new(name: 'Self-Sealing Stem Bolt')
gadget[:name]
#=> 'Self-Sealing Stem Bolt'

gadget[:name] = 'Can of Headlight Fluid'
#=> 'Can of Headlight Fluid'
```

Internally, the attribute methods are defined on the entity class's `::Attributes` module, allowing you to redefine the methods and use `super` to reference the original definitions.

```ruby
class Gadget
  def name
    value = super

    return value if value.size < 10

    "#{value[..10]}..."
  end
end

gadget = Gadget.new(name: 'Self-Sealing Stem Bolt')
gadget.name
#=> 'Self-Sealin...'
```

The `#[]` and `#[]` methods can be used to directly get or set the attribute value.

### Default Values

Entities can define default values for attributes by passing a `:default` value to the `.attribute` call.

```ruby
class LightsCounter
  include Stannum::Entity

  attribute :count, Integer, default: 4
end

LightsCounter.new.count
#=> 4
```

Defaults can also be defined as a `Proc`. If the default block takes no arguments, then the block will be called with no parameters. If the default block takes an argument, then the block will be called with the current entity. This allows you to define default values that depend on other attributes.

```ruby
class Employee
  include Stannum::Entity

  AccessCard = Struct.new(:employee_id, :full_name)

  attribute :employee_id, String, default: -> { SecureRandom.uuid }
  attribute :full_name,   String, default: lambda { |employee|
    "#{employee.first_name} #{employee.last_name}"
  }
  attribute :first_name,  String, default: 'Jane'
  attribute :last_name,   String, default: 'Doe'
  attribute :access_card, AccessCard, default: lambda { |employee|
    AccessCard.new(employee.employee_id, employee.full_name)
  }
end

Employee.new.access_card.full_name
#=> 'Jane Doe'
```

Attribute defaults are always applied in the following order:

1. Attribute values defined by the user or already set on the entity.
2. Default attributes that are not `Proc`s.
3. Default attribute blocks, in the order they are defined.

In the example above, the `employee_id`, `first_name` and `last_name` are generated first. Then, the `full_name` attribute is generated, using the values of `#first_name` and `#last_name`. Finally, the `#access_card` is generated, using the values of `#employee_id` and `#full_name`.

Default values that are defined as `Proc`s are always executed when generating the default value. If you need to define a default value that is itself a `Proc` or `lambda`, you can do so by defining the `Proc` and wrapping it another `Proc`.

### Optional Attributes

Entity classes can also mark attributes as `optional`. When an entity is validated (see [Validation](#entities-validation), below), optional attributes will pass with a value of `nil`.

```ruby
class WhereWeAreGoing
  include Stannum::Entity

  attribute :roads, Object, optional: true
end
```

`Stannum` supports both `:optional` and `:required` as keys. Passing either `optional: true` or `required: false` will mark the attribute as optional. Attributes are required by default.

### Primary Keys

An entity can define a primary key attribute using the `define_primary_key` class method. This takes the same name and format parameters and options as defining any other attribute.

```ruby
class Record
  include Stannum::Entity

  define_primary_key :id, Integer
end

class Document
  include Stannum::Entity

  define_primary_key :uuid, String

  constraint :uuid, Stannum::Constraints::Uuid.new
end
```

The primary key attribute can be accessed from the entity class.

```ruby
attribute = Record.primary_key
attribute.class        #=> Stannum::Attribute
attribute.primary_key? #=> true
attribute.name         #=> 'id'
attribute.type         #=> Integer

Record.primary_key?     #=> true
Record.primary_key_name #=> 'id'
Record.primary_key_type #=> Integer
```

In addition to the attribute reader and writer, the entity also defines several helper methods for primary keys.

```ruby
record = Record.new
record.id                #=> nil
record.primary_key?      #=> false
record.primary_key_name  #=> 'id'
record.primary_key_type  #=> Integer
record.primary_key_value #=> nil

record = Record.new(id: 0)
record.id                #=> 0
record.primary_key?      #=> true
record.primary_key_value #=> 0
```

## Validation

Each `Stannum::Entity` automatically generates a contract that can be used to validate instances of the entity class. The contract can be accessed using the `.contract` class method or via the `::Contract` constant.

```ruby
class Widget
  include Stannum::Entity

  attribute :name,        String
  attribute :description, String,  optional: true
  attribute :quantity,    Integer, default:  0
end

Widget::Contract
#=> an instance of Stannum::Contract
Widget.contract
#=> an instance of Stannum::Contract

widget = Widget.new
Widget.contract.matches?(widget)
#=> false
Widget.contract.errors_for(widget)
#=> [
#     {
#       data:    { type: String },
#       message: nil,
#       path:    [:name],
#       type:    'stannum.constraints.is_not_type'
#     }
#   ]

widget = Widget.new(name: 'Self-Sealing Stem Bolt')
Widget.contract.matches?(widget)
#=> true
```

You can also define additional constraints using the `.constraint` class method.

```ruby
class Widget
  constraint :name, Stannum::Constraints::Presence.new

  constraint :quantity do |qty|
    qty >= 0
  end
end

widget = Widget.new(name: '')
Widget.contract.matches?(widget)
#=> false
Widget.contract.errors_for(widget)
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

{% include breadcrumbs.md %}
