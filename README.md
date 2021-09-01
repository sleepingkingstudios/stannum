# Stannum

A library for defining and validating data structures.

Stannum defines the following objects:

- [Constraints](#constraints): A validator object that responds to `#match`, `#matches?` and `#errors_for` for a given object.
- [Contracts](#contracts): A collection of constraints about an object or its properties. Obeys the `Constraint` interface.
- [Errors](#errors): Data object for storing validation errors. Supports arbitrary nesting of errors.
- [Structs](#structs): Defines a mutable data object with a specified set of typed attributes.

## About

@todo

### Why Stannum?

@todo

- Not tied to any framework - can create constraints/contracts for POROs, Structs, AR models, etc.
- Separation of concerns - data definition separate from validation.
  - Can have multiple contracts on the same data for different contexts.
  - Can use the same contract to validate different data types.
- Alternatives?

### Compatibility

Stannum is tested against Ruby (MRI) 2.6 through 3.0.

### Documentation

Documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

### License

Copyright (c) 2019-2021 Rob Smith

Stannum is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/stannum.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/stannum/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/stannum/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Stannum` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/stannum/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.

<!-- ## Getting Started  -->

## Reference

### Constraints

@todo

### Contracts

@todo

### Structs

@todo
