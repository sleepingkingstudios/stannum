# Stannum Development

## Future Versions

### Pre-Defined Constraints

- Constraints::Always
  - #does_not_match? and #matches? always return true
- Constraints::Anything
  - #matches? always returns true
- Constraints::Never
  - #does_not_match? and #matches? always return false
- Constraints::Nothing
  - #matches? always returns false
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

- add_constraint :fail_fast keyword
  - all keywords with :fail_fast run first
  - if there are any failures, non-fail-fast constraints are ignored

### ArgumentsContract

### MapContract

- fail_fast by property?
  - e.g. add_constraint(fail_fast: :name)
  - only skips non-fail-fast constraints on :name

### TupleContract

## Errors

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
