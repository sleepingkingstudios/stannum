# Stannum Development

## Development Notes

### Contract

- Refactor #include to #compose (avoids collision when implementing DSL).

#### ::Builder

- Define specialized add_x_constraint methods
  - HashContract#add_key_constraint
  - PropertyContract#add_property_constraint
  - TupleContract#add_index_constraint
  - Refactor builders to leverage ^ ?
- Implement #compose(contract):
  ```ruby
  contract = Stannum::Contract.new do
    compose OtherContract
  end
  ```

#### DSL

- Define a DSL for adding constraints to a contract at the class level:
  ```ruby
  class CustomContract < HashContract
    compose    OtherContract
    constraint SomeConstraint
    property   :property_name, PropertyConstraint
    key        :key,           KeyConstraint
  end
  ```
- Must be heritable.
- Each class defines list of tuples [method_name, \*args, \*\*kwargs, &block]
  - Enumerable over ancestors!
- Passed to Builder ahead of the block.
  - Builder executes each method.
- Revise integration specs!

### Contracts::IndifferentHashContract

- Requires Constraints::Hashes::IndifferentKey
  - sets key_type
  - indifferent lookup for #map_value

### Contracts::PropertyContract::Builder

- Refactor from Contract::Builder.

### Standardization

- Always return a `Stannum::Errors` from `match`.
- Refactor `#errors_for` to always check `#matches`.
- Each constraint should define the `::TYPE` and `::NEGATED_TYPE` constants,
  and the `#type` and `#negated_type` readers.
- Each constraint should define `#options` (default to empty hash).
  - Treat `type`, `negated_type` as options? Override default types?

### Sanity Constraints

#### Property-specific Sanity Constraints

NOT SUPPORTED DIRECTLY

- Instead of adding multiple constraints for the property, add one contract for
  the property which contains the individual constraints. If any of the
  constraints are sanity constraints, the contract will short-circuit
  accordingly. Probably.
- Integration test this!

### Testing Constraints and Contracts

Constraint testing should be done in the context of the `#match` and `#negated_match` methods to avoid duplication. This tests both the status and the error(s).

## Future Versions

### Pre-Defined Constraints

- Constraints::Always
  - #does_not_match? and #matches? always return true
- Constraints::Never
  - #does_not_match? and #matches? always return false
- Constraints::Numeric
  - asserts actual is numeric value
  - options for integer, greater/less than
- Constraints::Range
  - asserts actual in range
  - initialize with range or params
    - max and/or min, gt/gte and/or lt/lte
- Constraints::Size
  - options for :is, :max, :min - delegate to Constraints::Range?

- Type::Lazy - takes a class or module name as a String or Symbol; only
  evaluates when the constraint is first checked?
- Type::Optional - allows nil value

### Type Constraints

- .instance method (caches instance by params (if any))
  - a large application does not need 50 Type::String objects
- Types::Array
- Types::ArrayOf(type [class or constraint])
- Types::Boolean
- Types::Float
- Types::Hash
- Types::HashOf(keyType, valueType)
- Types::Integer
- Types::Nil
- Types::String
- Types::Symbol

## Contracts

### ParametersContract

## Errors

- clean up error types
- #generate_message(error)
  - creates default string based on :type
- #generate_messages
  - for each error:
    - if error.message present, no change
    - set message to generate_message(error)
- #include?(type OR hash)
  - if type, call include?(type: type)
  - errors.any? { |actual| actual >= expected }

## RSpec

- MatchConstraint matcher (#match_constraint macro)
- Matcher mixin - use a constraint in place of an RSpec matcher!

## Structs

```
class Person
  # Defines :==, :[], :[]=, :inspect, :to_h, :to_s
  # Sets Person::Contract to a new MapContract
  include Stannum::Struct

  # Define attributes.
  # Creates reader, writer methods via @attributes[]
  # Creates a Type constraint
  # attribute :attr_name, AttrType (or "AttrType")
  attribute :name, String
  attribute :residence, "Residence"

  # Define constraints.
  constraint CustomPersonConstraint.new
  constraint { |person| !person.can_drink? if person.age < 21 }
  constraint :name, CustomNameConstraint.new
  constraint(:residence) { |residence| residence.location != 'Phantom Zone' }
end
```

### ::Contract

- automatically add a type constraint to ::Contract
  - handles case with another (non-subclass) struct with matching attributes
  - use :fail_fast option?
- add :fail_fast option to attribute constraints
  - if the value is not the expected type, do not run custom constraints
- automatically add type::Contract if type is a Struct class
  - support contract: false to override this behavior

### Constraints

- support type:, negated_type: keywords for anonymous constraints

```
class Administrator
  attribute :role, String

  constraint(type: 'must have a role') { |role| !role.empty? }
  constraint(:role, type: 'must be an Admin') { |role| role == 'Admin' }
end
```

- support :if, :unless keywords

### Inheritance

What happens if you extend a Module with Struct, then include that module in a class?

Implement Struct::Factory
- (replaces class << self methods on Struct)
- takes a class that inherits from Struct
- defines the ::Attributes constant
  - if superclass also is a Struct, include the Superclass attributes
- defines the ::Contract constant
  - figure out contract inheritance (a mess)

Child classes must:
  - inherit Class Methods
  - define their own ::Attributes and ::Contract
    - include their own ::Attributes
    - reference their own #attributes and #contract
  - inherit defined Attributes
  - inherit defined constraints

### Struct::Attribute

- :optional option
  - include optional? predicate
- :required option
  - include required? predicate
  - inverse of :optional - error if contradictory options

### Struct::Attributes

- inheritance - #each references #parent ?
- multiple inheritance - support `include OtherStruct::Attributes` ?
