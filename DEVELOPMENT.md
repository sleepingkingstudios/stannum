# Stannum Development

- What happens to a frozen constraint? A frozen contract?
  - Should freezing a contract freeze its constraints? #deep_freeze ?

## Documentation Standards

- Should provide a one-line short description.
- Should provide a one+ paragraph short description.
- Should document what errors look like in various circumstances.
- Should provide examples of passing and failing objects.
- Should document the methods.

## Development Notes

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

### Contract

- Refactor #include to #compose/#concat (avoids collision when implementing DSL).

#### ::Builder

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

### Standardization

- Always return a `Stannum::Errors` from `match`.
- Refactor `#errors_for` to always check `#matches`.
- Each constraint should define the `::TYPE` and `::NEGATED_TYPE` constants,
  and the `#type` and `#negated_type` readers.
- Each constraint should define `#options` (default to empty hash).
  - Treat `type`, `negated_type` as options. Defaults to TYPE, NEGATED_TYPE
  - Implement 'should implement the Constraint methods' shared examples
    - Defines negated_type, options, type
    - Extract implementations from 'implement Constraint interface' examples
- Use terse contract class/file names:
  - Stannum::Contracts::IndifferentHash instead of IndifferentHashContract.

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

### Type Constraints

- .instance method (caches instance by params (if any))
  - a large application does not need 50 Type::String objects
- Types::Array
- Types::ArrayOf(type [class or constraint])
- Types::Boolean
- Types::Float
- Types::Hash
- Types::IndifferentHash
- Types::Integer
- Types::Nil
- Types::String
  - add support for allowing/disallowing empty strings
- Types::Symbol
  - add support for allowing/disallowing empty symbols

## Contracts

### ParametersContract

- actual => { arguments: [], block: true, keywords: {} }

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

- Refactor Stannum::Structs::Attribute to Stannum::Attribute.
- Refactor Stannum::Structs::Attributes to Stannum::Schema.
