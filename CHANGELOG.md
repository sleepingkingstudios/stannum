# Changelog

## 0.4.0

### Constraints

- Implemented `Stannum::Constraints::Format`
- Implemented `Stannum::Constraints::Uuid`

### Entities

Implemented `Stannum::Entities::PrimaryKey`.

## 0.3.0

### Constraints

- Implemented `Stannum::Constraints::Properties::MatchProperty`
- Implemented `Stannum::Constraints::Properties::DoNotMatchProperty`

### Contracts

- Added `#concat` to `Stannum::Contracts::Builder`.

### Entities

Implemented `Stannum::Entity`, a replacement for the existing `Stannum::Struct`.

Entities are largely identical to structs, except for the constructor signature - entities require properties to be passed as keyword parameters, rather than as an attributes hash. Entities (and now Structs) are defined using composable modules.

- Implemented `Stannum::Entities::Attributes`.
- Implemented `Stannum::Entities::Constraints`.
- Implemented `Stannum::Entities::Properties`.

`Stannum::Struct` is now deprecated, and will be removed in a future release.

## 0.2.0

### Constraints

#### Parameter Constraints

- Implemented `Stannum::Constraints::Parameters::ExtraArguments`
- Implemented `Stannum::Constraints::Parameters::ExtraKeywords`

## 0.1.0

Initial version.

### Constraints

Defined `Stannum::Constraint`.

### Contracts

Defined `Stannum::Contract`.

### Errors

Defined `Stannum::Errors`.

### Structs

Defined `Stannum::Struct`.
