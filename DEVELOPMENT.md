# Stannum Development

## Future Versions

### Attributes

### Constraints

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

### Structs
