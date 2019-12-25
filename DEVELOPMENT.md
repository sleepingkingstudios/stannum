# Stannum Development

## Future Versions

### Attributes

### Constraints

#### Pre-Defined Constraints

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

#### Type Constraints

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

### Contracts

#### ArgumentsContract

#### HashContract

- #access_property accesses property via #[]
  - if not, skip property constraints entirely?
- constructor option strict: [true, false (default)]
  - if false, object must respond to :[]
  - if true, object must be a Hash or subclass instance
- constructor option keys: [:any (default), :indifferent, :string, :symbol]
  - if :any, on #initialize extend with ::Any module
    - no change to #access_property
    - #valid_property? always returns true
  - if :indifferent, on #initialize extend with ::Indifferent module
    - #access_property fetches by String, then Symbol
    - no change to #valid_property?
  - if :string
    - no change to #access_property
    - #valid_property? only allows String properties
  - if :symbol
    - no change to #access_property
    - #valid_property? only allows Symbol properties

#### TupleContract

### Errors

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

### Structs
