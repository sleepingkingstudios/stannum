# Stannum

A library for defining and validating data structures.

<blockquote>
  Read The
  <a href="https://www.sleepingkingstudios.com/stannum" target="_blank">
    Documentation
  </a>
</blockquote>

Stannum provides a framework-independent toolkit for defining structured data entities and validations. It provides a middle ground between unstructured data (raw `Hash`es, `Structs`, or libraries like `Hashie`) and full frameworks like `ActiveModel`.

It defines the following objects:

- [Constraints](http://sleepingkingstudios.github.io/stannum/constraints): A validator object that responds to `#match`, `#matches?` and `#errors_for` for a given object.
- [Contracts](http://sleepingkingstudios.github.io/stannum/contracts): A collection of constraints about an object or its properties. Obeys the `Constraint` interface.
- [Errors](http://sleepingkingstudios.github.io/stannum/errors): Data object for storing validation errors. Supports arbitrary nesting of errors.
- [Entities](http://sleepingkingstudios.github.io/stannum/entities): Defines a mutable data object with a specified set of typed attributes.

### Why Stannum?

Stannum is not tied to any framework. You can create constraints and contracts to validate Ruby objects and Entities, data structures such as Arrays, Hashes, and Sets, and even framework objects such as `ActiveRecord::Model`s and `Mongoid::Document`s.

Still, most projects and applications use one framework to handle their data. Why use Stannum constraints?

- **Composability:** Because Stannum contracts are their own objects, they can be combined together. Reuse validation logic without duplicating code or defining abstract ancestor classes .
- **Polymorphism:** Your data validation is separate from your model definitions. This gives you two major advantages over the traditional approach:
    - You can use the same contract to validate different objects. Do you have a shared concern that cuts across multiple domain objects, such as attaching images, having comments, or creating an audit trail? You can write one contract for the concern and apply that same contract to each applicable model or object.
    - You can use different contracts to validate the same object in different contexts. Need different validations for a regular user versus an admin? Need to handle published articles more strictly than drafts? Need to provide custom validations for each step in your state machine? Stannum has you covered, and because contracts are composable, you can pull in the constraints you need without duplicating your logic.
- **Separation of Concerns:** Your data validation is independent from your entities. This means that you can use the same tools to validate anything from controller parameters to models to configuration files.

### Compatibility

Stannum is tested against Ruby (MRI) 3.1 through 3.4.

### Documentation

Code documentation is generated using [YARD](https://yardoc.org/), and can be generated locally using the `yard` gem.

The full documentation is available via [GitHub Pages](http://sleepingkingstudios.github.io/stannum), and includes the code documentation as well as a deeper explanation of Stannum's features and design philosophy. It also includes documentation for prior versions of the gem.

To generate documentation locally, see the [SleepingKingStudios::Docs](https://github.com/sleepingkingstudios/sleeping_king_studios-docs) gem.

### License

Copyright (c) 2019-2025 Rob Smith

Stannum is released under the [MIT License](https://opensource.org/licenses/MIT).

### Contribute

The canonical repository for this gem is located at https://github.com/sleepingkingstudios/stannum.

To report a bug or submit a feature request, please use the [Issue Tracker](https://github.com/sleepingkingstudios/stannum/issues).

To contribute code, please fork the repository, make the desired updates, and then provide a [Pull Request](https://github.com/sleepingkingstudios/stannum/pulls). Pull requests must include appropriate tests for consideration, and all code must be properly formatted.

### Code of Conduct

Please note that the `Stannum` project is released with a [Contributor Code of Conduct](https://github.com/sleepingkingstudios/stannum/blob/master/CODE_OF_CONDUCT.md). By contributing to this project, you agree to abide by its terms.
