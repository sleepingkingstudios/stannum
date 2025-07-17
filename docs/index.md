---
breadcrumbs:
  - name: Documentation
    path: './'
---

# Stannum

A library for defining and validating data structures.

## Documentation

This is the documentation for the [current development build](https://github.com/sleepingkingstudios/stannum) of Stannum.

- For the most recent release, see [Version 0.4]({{site.baseurl}}/versions/0.4).
- For previous releases, see the [Versions]({{site.baseurl}}/versions) page.

## Reference

Stannum defines the following core components for validating objects:

- **[Constraints](./constraints)**
  <br>
  A validator object that checks whether a given object matches the constraint.
- **[Contracts](./contracts)**
  <br>
  A collection of constraints that validate an object and its properties.
- **[Errors](./errors)**
  <br>
  A value object documenting the reasons why an object does not match a
  constraint or contract.

In addition, Stannum defines the following components for defining data objects:

- **[Entities](./entities)**
  <br>
  A structured data object with a defined, typed set of properties.
  - **[Attributes](./entities#attributes)**
    <br>
    A typed and validated property for an entity.
  - **[Associations](./entities#associations)**
    <br>
    Defining relationships between entities.
  - **[Primary Keys](./entities#primary-keys)**
    <br>
    Setting a unique identifier for the entity.
  - **[Validation](./entities#validation)**
    <br>
    Leveraging Stannum's contracts to validate entity properties.

For a full list of defined classes and objects, see [Reference](./reference).
