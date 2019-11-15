# Stannum Development

## Future Versions

### Attributes

### Constraints

- Constraints::Always
  - #does_not_match? and #matches? always return true
- Constraints::Anything
  - #matches? always returns true
- Constraints::Never
  - #does_not_match? and #matches? always return false
- Constraints::Nothing
  - #matches? always returns false
- Constraints::Nil
  - asserts actual.nil?
- Constraints::Numeric
  - asserts actual is numeric value
  - options for integer, greater/less than
- Constraints::Range
  - asserts actual in range
- Constraints::Predicate
  - takes block, e.g. Constraints::Predicate.new(&:persisted?)
  - asserts block.call(actual)
- Constraints::Type
  - asserts that actual is_a? expected

### Contracts

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

#### Details

- add :details to error hashes, default to {}
  - e.g. add(:outside_range, details: { min: 0, max: 10 })

#### Nesting

- add :path to error hashes, default to []
- add @children Hash to #initialize
  - default value is self.class.new
  - handle custom subclasses (add tests!)
  - delegate :[], :[]= to @children
- update #each to call @children.each { |child| child.each { |err| yield err } }
  - should yield each child's errors
- update #size to add @children.reduce { |sum, child| sum + child.size }
  - should include each child's size

### RSpec

- MatchConstraint matcher (#match_constraint macro)
- Matcher mixin - use a constraint in place of an RSpec matcher!

### Structs
