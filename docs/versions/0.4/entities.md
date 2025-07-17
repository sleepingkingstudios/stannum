---
breadcrumbs:
  - name: Documentation
    path: '../../'
  - name: Versions
    path: '../'
  - name: '0.4'
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
- [Associations](#associations)
  - [Defining Associations](#defining-associations)
  - [Singular Associations](#singular-associations)
  - [Plural Associations](#plural-associations)
  - [Inverse Associations](#inverse-associations)
  - [Foreign Keys](#foreign-keys)
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

## Associations

In addition to define attributes, `Stannum::Entity` classes can also define associations between entities.

```ruby
class Assembly
  include Stannum::Entity

  define_primary_key :id, Integer

  define_attribute :name, String

  define_association :many, 'parts'
end

class Part
  include Stannum::Entity

  define_primary_key :id, Integer

  define_attribute :identifier, String
  define_attribute :name,       String

  define_association :one, 'assembly'
end

assembly = Assembly.new(id: 0, name: 'Rocket Engine')
fuel_lines =
  Part.new(id: 1, name: 'Fuel Lines', identifier: 'fl')
combustion_chamber =
  Part.new(id: 2, name: 'Combustion Chamber', identifier: 'cc')
nozzle =
  Part.new(id: 3, name: 'Nozzle', identifier: 'nz')

assembly.parts << fuel_lines << combustion_chamber << nozzle
assembly.parts
#=> [
#     #<Part name="fuel_lines">,
#     #<Part name="combustion_chamber">,
#     #<Part name="nozzle">
#   ]

nozzle.assembly
#=> #<Assembly name="Rocket Engine">
```

Unlike an `ActiveRecord` association, Stannum associations do not query from a data store and must be hydrated with the association values. While inconvenient for certain use cases, this means that Stannum associations cannot result in accidental N+1 queries from missing an `include`, nor can they cause cause unexpected database calls by setting or changing association values.

In addition to the [properties](#properties) methods, `Stannum::Entity` defines a number of helper methods for interacting with a entity's associations as a whole:

- `#assign_associations(values)`: Updates the entity's associations using the given values. If an association is not given, that value is unchanged.
- `#associations`: Returns a hash containing the association keys and values.
- `#associations=(values)`: Sets the entity's associations to the given values. If an association is not given, that association is set to `nil` (for a singular association) or an empty list (for a plural association).

For all of the above methods, if a given association is invalid or the association is not defined on the entity, an `ArgumentError` will be raised.

### Defining Associations

You can define an association on an entity using the `define_association` method:

```ruby
class Author
  include Stannum::Entity

  define_association :many, 'books'
end

class Book
  include Stannum::Entity

  define_assocation :one, 'author', foreign_key: true
end
```

Each defined asociation has three parts:

- The [arity](#association-arity) of the association, either `:one` or `:many`.
- The [name or type](#association-name-and-type) of the association. This can be the name of the association, the name of the associated class, or the associated class itself.
- The association *options*, which may be empty.

#### Association Arity

Each association has an *arity* of either `:one` or `:many`.

An association with an arity of `:one` is a [singular association](#singular-associations). It represents a relationship where each entity can have either zero or one associated entities. For example, in a game about sailing ships, a ship might have exactly one captain.

An association with an arity of `:many` is a [plural association](#plural-associations). It represents a relationship where each entity can have zero, one, or many associated entities. For example, in our sailing ships game, a ship might have many crew members.

#### Association Name And Type

Each association has a name, which is used to define the association methods on the entity. The association also has a type, which is the kind of entity the association refers to. Often, the name and type will be related, but not always - a `Ship#captain` association might return an instance of the `Sailor` entity.

When defining an association, you can pass either the association name or the type. For example, to define a singular `role` association on a `User` class, which references an instance of the `Role` entity, you can do either of the following:

```ruby
define_association :one, 'role'

define_association :one, 'Role'
```

You can also pass the class directly in place of the class name, but this is not a recommended approach - it can lead to unecessary requirements around load order.

When you need to define an association where the name and type *do not* match, specify the name of the association and then pass the `:class_name` option (see [association options](#association-options), below).

```ruby
class Ship
  define_association :one, 'captain', class_name: 'Sailor'
end
```

#### Association Options

In addition to the [arity](#association-arity) and [type](#association-type), you can pass additional options to `define_association`:

- `class_name`: The `:class_name` association specifies which entity class the association refers to. Use this option when the association type cannot be automatically derived from the name, such as when the class is namespaced.
- `inverse`: The name of the [inverse association](#inverse-associations), if any. The inverse association can be skipped by passing `inverse: false`.

Singular associations can also define the [foreign key](#foreign-keys) options:

- `foreign_key`: If `true` (or if either of the below options are set), the association also defines a [foreign key](#foreign-keys) for the association.
- `foreign_key_name`: Specifies the name of the foreign key attribute. The default is the association name followed by the `"_id"` suffix.
- `foreign_key_type`: Specifies the type of the foreign key attribute. The default is the type of the entity's own primary key attribute, if any.

### Singular Associations

A singular association represents a relationship where each entity can have either zero or one associated entities.

```ruby
class Ship
  include Stannum::Entity

  define_attribute :name, String

  define_association :one, 'captain', class_name: 'Sailor'
end
```

A singular association defines reader and writer methods for the association.

```ruby
ship = Ship.new(name: 'Unsinkable II')
ship.captain
#=> nil
ship['captain']
#=> nil

ship.captain = Sailor.new(name: 'Nemo')
ship.captain
#=> #<Sailor name="Nemo">
ship['captain']
#=> #<Sailor name="Nemo">
```

If the association defines an [inverse](#inverse-associations), calling the association writer will also update the inverse association.

```ruby
ship.captain.ship
#=> #<Ship name="Unsinkable II">
```

### Plural Associations

A plural association represents a relationship where each entity can have zero, one, or many associated entities.

```ruby
class Sailor
  include Stannum::Entity

  define_attribute :name, String

  define_association :one, 'ship', inverse: 'crew'
end

class Ship
  include Stannum::Entity

  define_attribute :name, String

  define_association :many, 'crew', class_name: 'Sailor'
end
```

Instead of returning the raw association value, a plural association returns a [proxy object](./reference/stannum/associations/many/proxy). The proxy object is an `Enumerable` object that wraps the association data.

```ruby
ship = Ship.new(name: 'Unsinkable II')
ship.crew
#=> #<Stannum::Associations::Many::Proxy data=[]>
ship.crew.count
#=> 0
ship.crew.map(&:name)
#=> []

ship.crew <<
  Sailor.new(name: 'Alecto') <<
  Sailor.new(name: 'Megaera') <<
  Sailor.new(name: 'Tisyphone')
ship.crew.count
#=> 3
ship.crew.map(&:name)
#=> ["Alecto", "Megaera", "Tisyphone"]
```

You can use the proxy object to manipulate the contents of the association.

- `#add(value)`: Adds the given value to the association, or does nothing if the value is already in the association. Aliased as `#<<`, `#push`.
- `#remove(value)`: Removes the given value from the association, or does nothing if the value is not in the association.

A full list of proxy methods can be found in the [Reference Documentation](./reference) on the [Stannum::Associations::Many::Proxy](./reference/stannum/constraints) page.

If the association defines an [inverse](#inverse-associations), updating the association values will also update the inverse associations.

### Inverse Associations

An association's inverse represents the same relationship between entities, but in the opposite direction. For example, the inverse of the `Ship#crew` association is the `Sailor#ship` association.

Inverse associations are *not* automatically defined, but *are* expected by default. When you call a writer method on an association with a missing association, an `Stannum::Association::InverseAssociationError` will be raised. Unless otherwise specified, `Stannum` will first find the entity class for the association, and then look for an association on that class with the same name as the original entity class. Let's go through this step by step for the `Ship#crew` association:

- The original entity class is `Ship`.
- The associated entity class for the `#crew` association is `Sailor`.
- Therefore, the expected association will be either `Sailor#ship` or `Sailor#ships`.

You can define an association with no inverse by passing `inverse: false` when [defining the association](#association-options). You can also specify the name of the inverse relationship. For example, we need to pass `inverse: 'crew'` when defining the `Sailor#ship` association; otherwise, it will expect the inverse to be either `Ship#sailor` or `Ship#sailors`, and will raise an exception when we try and set `Sailor#ship`.

### Foreign Keys

Entity associations can also define foreign keys, attributes that identify the associated entity by storing the primary key. This is a common pattern used when associating data stored in relational databases. In the current version, foreign keys are only supported on [singular associations](#singular-associations).

To define a foreign key, add the `foreign_key: true` option when defining the association. This will automatically define a foreign key attribute and configure the association to update the foreign key value when the association value changes. If an attribute of the same name is already defined, Stannum will raise an exception.

By default, the foreign key attribute uses the name of the association with the suffix `"_id"`, and has the same type as the current entity's primary key column, if any. These can be overriden by passing `foreign_key_name:` and `oreign_key_type:` options when defining the association.

```ruby
class Base
  include Stannum::Entity

  define_primary_key :id, Integer
end

class Organization < Base
  define_attribute :name, String

  define_association :many, :users
end

class User < Base
  define_attribute :name, String

  define_association :one, :organization, foreign_key: true
end

organization = Organization.new(id: 0, name: 'Encom')
user         = User.new(id: 1, name: 'Alan Bradley', organization:)

user.organization
#=> #<Organization name="Encom">
user.organization_id
#=> 0
```

As you can see, setting or updating the association will also update the corresponding foreign key attribute. However, this binding does not go both ways: because Stannum does not have a connection to your data source, changing the foreign key value will merely null out the association.

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

Associations are not automatically validated, but you can create a constraint that validates the association value.

<!-- ## Deconstructing Entities

> @todo -->

{% include breadcrumbs.md %}
