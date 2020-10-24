# Stannum Development

## Version 0.1

- What happens to a frozen constraint? A frozen contract?
  - Should freezing a contract freeze its constraints? #deep_freeze ?

### Constraints

#### Type Constraints

- Types::BigDecimalType
- Types::BooleanType
- Types::FloatType
- Types::IntegerType

### Contracts

- Refactor #include to #concat (avoids collision when implementing DSL).

#### ::Builder

- Implement #concat(contract):
  ```ruby
  contract = Stannum::Contract.new do
    concat(OtherContract)
  end
  ```

### Documentation

- Should provide a one-line short description.
- Should provide a one+ paragraph short description.
- Should document what errors look like in various circumstances.
- Should provide examples of passing and failing objects.
- Should document the methods.

### Refactoring

- Refactor Constraints::Methods to Constraints::Signature ?
  - Refactor Map, Tuple constraints to Constraints::Signatures ?
- Refactor Type constraints to include Type suffix ?
  - e.g. Array => ArrayType (avoid collision with core class!)
- Harmonize HashContract, TupleContract.
  - define MapContract, TupleContract
    - uses Signature sanity constraint
    - defines a #type_constraint inner reader
  - define HashContract < MapContract, ArrayContract < TupleContract
    - uses Type sanity constraint
    - overrides #type_constraint inner reader
- Refactor Stannum::Structs::Attribute to Stannum::Attribute.
- Refactor Stannum::Structs::Attributes to Stannum::Schema.

### Standardization

- Always return a `Stannum::Errors` from `match`.
- Refactor `#errors_for` to always check `#matches`.

## Future Versions

### Constraints

- Constraints::Always
  - #does_not_match? and #matches? always return true
- Constraints::Equality
  - asserts actual == expected
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

#### Type Constraints

- .instance method (caches instance by params (if any))
  - a large application does not need 50 Type::String objects
- Types::Boolean
- Types::Array
  - add support for allowing/disallowing empty arrays (default to allowed)
- Types::Hash
  - add support for allowing/disallowing empty hashes (default to allowed)
- Types::String
  - add support for allowing/disallowing empty strings (default to allowed)
- Types::Symbol
  - add support for allowing/disallowing empty symbols (default to allowed)

### Contracts

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

### Errors

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

### RSpec

- MatchConstraint matcher (#match_constraint macro)
- Matcher mixin - use a constraint in place of an RSpec matcher!

### Support

- Stannum::Support::Validations
  - raise exception on invalid params
  - #validate_integer
  - #validate_name
