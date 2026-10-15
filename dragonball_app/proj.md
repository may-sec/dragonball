# Advanced Dart Type System — Dragon Ball Explorer

A practical guide to Dart 3+ language features through the architecture of a modern Flutter application using Riverpod, repositories, immutable models, asynchronous state, and explicit error handling.

## 1. How Dart's Type System Fits the Application

A useful mental model for the project is:

```text
Flutter Presentation
    │
    ├── Widgets and Hooks
    ├── Riverpod Providers and Controllers
    └── AsyncValue<T>
             │
             ▼
Application / Domain
    │
    ├── Character and Planet entities
    ├── Repository contracts
    ├── Value objects
    ├── Result<T, Failure>
    └── Sealed Failure hierarchy
             ▲
             │ implements
Data Layer
    │
    ├── API DTOs
    ├── HTTP data sources
    ├── JSON parsing
    └── Repository implementations
```

Dart's type-system features help make these boundaries explicit:

| Requirement | Useful Dart construct |
|---|---|
| Prevent arbitrary inheritance of a model | `final class` |
| Define a repository contract | `abstract interface class` |
| Provide a reusable implementation base | `abstract base class` |
| Define a closed set of error types | `sealed class` |
| Define fixed categories | `enum` |
| Represent immutable application state | Classes with `final` fields, immutable collections, and controlled constructors |
| Create lightweight compound return values | Records |
| Create a strongly typed identifier | `extension type` |
| Add methods to existing types | Extensions |
| Name complex types or callback signatures | `typedef` |
| Share behavior across unrelated classes | `mixin` or `mixin class`, where appropriate |

The important principle is to select a construct because it expresses a real design constraint, not merely because it is a newer Dart feature.

## 2. Dart Class Modifiers — Practical Matrix

| Declaration | Instantiate directly? | Extend outside its library? | Implement outside its library? | Use with `with`? | Best project use |
|---|---|---|---|---|---|
| `class` | Yes, unless abstract | Yes | Yes | No, unless declared as a mixin class | Open, general-purpose classes |
| `base class` | Yes, unless abstract | Yes, with subtype restrictions | No | No | Controlled implementation hierarchies |
| `interface class` | Yes, unless abstract | No | Yes | No | Public API contracts |
| `final class` | Yes, unless abstract | No | No | No | Concrete models and implementations |
| `sealed class` | No | No | No | No | Closed state and failure hierarchies |
| `abstract class` | No | Yes | Yes | No | Extensible abstract behavior |
| `abstract base class` | No | Yes, with subtype restrictions | No | No | Controlled abstract implementation bases |
| `abstract interface class` | No | No | Yes | No | Repository and service contracts |
| `abstract final class` | No | No | No | No | Static namespaces and utility containers |
| `mixin class` | Yes, if its constructors allow it | Yes | Yes | Yes | Behavior reusable as a class or mixin |
| `base mixin class` | Yes, if its constructors allow it | Yes, with subtype restrictions | No | Yes | Reusable behavior with controlled implementation |

### Rules to remember

- `abstract` prevents direct instantiation; it does not by itself restrict external inheritance.
- `interface` permits implementation but prevents extending the class outside its defining library.
- `base` prevents external implementation. Subclasses must preserve the inheritance restrictions with an appropriate modifier.
- `final` closes the class to external extension and implementation.
- `sealed` defines a closed subtype hierarchy. Its direct subtypes must be in the same library, and it cannot be instantiated directly.
- `mixin class` permits both ordinary class use and mixin use.
- `abstract final class` is useful for static-only namespaces, but it does not turn arbitrary methods into compile-time constants.

The phrase *same library* is important: it is not necessarily the same physical file. Dart libraries can contain multiple files through `part` and `part of`.

## 3. `final class` — Concrete Domain Entities

A character model is a good example of a type whose implementation you want to control.

```dart
final class Character {
  const Character({
    required this.id,
    required this.name,
    required this.race,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String race;
  final String imageUrl;
}
```

Why use `final class`?

- It prevents other packages from subclassing or implementing `Character`.
- Its `final` fields prevent reassignment after construction.
- The `const` constructor allows compile-time instances when the arguments permit it.

**Important:** `final class` does not make an object deeply immutable automatically. A final field can still refer to a mutable list or map. Prefer immutable collection types or defensive copies where appropriate.

For an ordinary API model, `final class` is a good default when extension is not part of the intended public API.

## 4. `abstract interface class` — Repository Contracts

The domain layer should describe what data operations are available without depending on how HTTP requests are made.

```dart
abstract interface class CharacterRepository {
  Future<Result<List<Character>, Failure>> getCharacters({
    int page = 1,
  });

  Future<Result<Character, Failure>> getCharacterById(int id);
}
```

The implementation belongs in the data layer:

```dart
final class ApiCharacterRepository
    implements CharacterRepository {
  ApiCharacterRepository(this._dataSource);

  final CharacterRemoteDataSource _dataSource;

  @override
  Future<Result<List<Character>, Failure>> getCharacters({
    int page = 1,
  }) async {
    // Fetch, map, and convert errors into Result values.
    throw UnimplementedError();
  }

  @override
  Future<Result<Character, Failure>> getCharacterById(
    int id,
  ) async {
    throw UnimplementedError();
  }
}
```

The `UnimplementedError` calls are placeholders, not production behavior.

This design lets Riverpod inject the repository contract while the concrete implementation can change from an HTTP API to a test fake or another data source.

```text
Character screen
       │
       ▼
Character provider
       │
       ▼
CharacterRepository
       ▲
       │ implements
ApiCharacterRepository
       │
       ▼
HTTP data source
```

**Recommendation:** use `abstract interface class` for repository contracts when the interface is intentionally public and independently implementable.

## 5. `sealed class` — Result and Failure Modeling

A sealed hierarchy is useful when the application needs a finite set of known alternatives.

For example, a simplified failure hierarchy:

```dart
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
```

These direct subclasses must remain in the same Dart library as `Failure`. You can use multiple source files in that library if you organize them with `part` directives.

A consumer can use an exhaustive switch:

```dart
String describeFailure(Failure failure) {
  return switch (failure) {
    NetworkFailure() => 'Check your internet connection.',
    ServerFailure() => 'The server could not complete the request.',
    ParsingFailure() => 'The response could not be processed.',
    NotFoundFailure() => 'The requested resource was not found.',
  };
}
```

If another permitted subtype is added to this sealed hierarchy, the compiler can identify switches that no longer handle every case.

### Why this matters for Flutter

It makes error handling explicit. Instead of scattering arbitrary strings throughout widgets, the application can represent known failure categories and translate them into appropriate UI messages.

Do not use `sealed` merely to obtain switch syntax. Use it when the alternatives are intentionally closed and controlled.

## 6. `Result<T, E>` — Representing Operation Outcomes

A result type makes success and failure explicit in a method's return type.

A simplified generic implementation:

```dart
sealed class Result<T, E> {
  const Result();
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;
}

final class Error<T, E> extends Result<T, E> {
  const Error(this.failure);

  final E failure;
}
```

A repository can return:

```dart
Future<Result<List<Character>, Failure>> getCharacters();
```

Its caller must handle the alternatives:

```dart
switch (result) {
  case Success(value: final characters):
    // Use the loaded characters.
    break;

  case Error(failure: final failure):
    // Handle the repository failure.
    break;
}
```

This example assumes the project uses the `Success` and `Error` variants shown above. If the existing code has different names or constructors, preserve the existing API instead of duplicating the type.

### `Result` versus `AsyncValue`

These types solve related but different problems.

| Type | Purpose |
|---|---|
| `Result<T, Failure>` | Represents the outcome of a repository or domain operation |
| `AsyncValue<T>` | Represents asynchronous state exposed by Riverpod, including loading, data, and error |
| `Failure` | Describes a known failure category |
| Dart exception | Represents an exceptional control flow or unexpected operation failure |

A repository can return `Result`, while a Riverpod provider exposes `AsyncValue`. If a provider deliberately throws when a repository returns a failure, `AsyncValue` can represent that failure through its error state. That is a design choice; it should be applied consistently.

## 7. `enum` — Fixed Categories and Modes

Use an enum when the alternatives are known and finite.

```dart
enum PlanetStatus {
  active,
  destroyed,
  unknown,
}
```

For example, a UI filter can store a `PlanetStatus` rather than arbitrary strings.

```dart
PlanetStatus selectedStatus = PlanetStatus.active;
```

Enums can also have fields, methods, and enhanced constructors:

```dart
enum CharacterGender {
  male('Male'),
  female('Female'),
  unknown('Unknown');

  const CharacterGender(this.label);

  final String label;
}
```

Use the enum's `name` or an explicit mapping when communicating with the API. Do not assume the API's serialized strings always match Dart enum identifiers.

**Project rule:** use enums for application-controlled categories. For API data that can contain new or unexpected values, parsing should include a safe fallback or preserve the raw value when necessary.

## 8. `abstract final class` — Static Namespaces

An endpoint namespace can group constant paths without allowing instances or subclasses:

```dart
abstract final class ApiEndpoints {
  static const String characters = '/characters';
  static const String planets = '/planets';

  static String characterById(int id) => '/characters/$id';
}
```

Usage:

```dart
final path = ApiEndpoints.characterById(42);
```

This is useful for endpoint definitions, static configuration helpers, and other namespaces.

Keep environment-specific configuration separate from endpoint paths. The base URL should come from the project's configuration mechanism, such as `String.fromEnvironment`, rather than being duplicated throughout the repository.

## 9. `mixin` — Reusable Behavior

A mixin shares behavior across classes without requiring a common concrete superclass.

```dart
mixin DebugLogging {
  void logDebug(String message) {
    print('[DEBUG] $message');
  }
}

final class CharacterRepositoryDebugger with DebugLogging {
  void inspect() {
    logDebug('Inspecting character repository');
  }
}
```

A mixin can use an `on` constraint to require a compatible host type:

```dart
mixin CharacterSelectionMixin on ChangeNotifier {
  int? selectedCharacterId;

  void selectCharacter(int id) {
    selectedCharacterId = id;
    notifyListeners();
  }
}
```

The host must satisfy the `on ChangeNotifier` constraint.

In a Riverpod-first application, use mixins sparingly. Prefer a normal class or a Riverpod controller when behavior represents a service, repository, or independent state-management responsibility.

For Flutter framework observer mixins, such as lifecycle observation, use the mixin required by the relevant framework API.

## 10. `extension type` — Strongly Typed Identifiers

Dart 3.3 introduced extension types, which can provide a distinct static type over an existing representation.

```dart
extension type const CharacterId(int value) {}

extension type const PlanetId(int value) {}
```

The intention is to prevent accidentally mixing identifiers:

```dart
void loadCharacter(CharacterId id) {
  // Load a character.
}

void loadPlanet(PlanetId id) {
  // Load a planet.
}

void example() {
  loadCharacter(CharacterId(10));
  loadPlanet(PlanetId(10));

  // loadCharacter(PlanetId(10)); // Static type error.
}
```

The underlying representation is still an `int`; extension types are not ordinary heap wrapper objects.

### When should you use them?

Consider extension types when identifiers appear frequently across many domain operations and accidental mixing is a realistic risk.

For a small learning project with simple integer IDs, ordinary `int` fields are perfectly reasonable. Extension types are an optional strengthening of the domain model, not a requirement.

They also do not replace runtime validation. If an ID must be positive, validate it at the relevant input boundary.

## 11. Records — Lightweight Compound Values

Records let a function return multiple values without declaring a dedicated class.

```dart
(String name, int id) characterSummary(Character character) {
  return (character.name, character.id);
}
```

Use positional records:

```dart
final (name, id) = characterSummary(character);
```

Or named records:

```dart
({String name, int id}) characterSummaryNamed(
  Character character,
) {
  return (name: character.name, id: character.id);
}

final summary = characterSummaryNamed(character);
print(summary.name);
```

Records have structural types and value equality.

### When to use records

Good examples include:

- Returning a small pair of values from a helper.
- Returning calculated display data.
- Passing a temporary grouping of related values between local functions.

Prefer a named class for a meaningful domain concept, a value object with validation, or a structure that needs methods and stable semantics.

Do not replace `Result<T, Failure>` with a record such as `(T?, Failure?)`: that representation can allow invalid states in which both values are present or both are absent.

## 12. `extension` — Convenience Without Modifying a Type

An extension adds methods or getters to an existing type through static dispatch.

```dart
extension CharacterNameFormatting on String {
  String get titleCaseFirst {
    if (isEmpty) return this;

    return '${this[0].toUpperCase()}'
        '${substring(1)}';
  }
}
```

Usage:

```dart
final displayName = 'goku'.titleCaseFirst;
```

In Flutter, extensions are often useful for presentation helpers, date formatting, and simple conversions.

Keep domain rules in domain classes or services when those rules need to be validated, tested independently, or shared by multiple application layers.

An extension does not modify the original type and does not provide runtime polymorphism.

## 13. `typedef` — Readable Type Aliases

A typedef gives a name to an existing type.

```dart
typedef JsonMap = Map<String, dynamic>;

typedef CharacterParser = Character Function(JsonMap json);
```

Usage:

```dart
Character parseCharacter(JsonMap json) {
  // Parse and validate the supplied JSON.
  throw UnimplementedError();
}

final CharacterParser parser = parseCharacter;
```

A typedef is a type alias, not a new nominal type. `typedef UserId = int` does not prevent passing an ordinary `int` where `UserId` is expected.

Use extension types or dedicated classes when you need stronger type separation.

## 14. Construct Matrix — Types Beyond Classes

| Construct | Runtime model | Instantiation | Main purpose |
|---|---|---|---|
| `class` | Ordinary object type | Depends on whether it is abstract and has an accessible constructor | General domain and infrastructure objects |
| `enum` | Fixed enum instances | Select an existing enum value | Finite categories |
| `mixin` | Reusable behavior applied to a class | Cannot instantiate as a standalone mixin | Cross-cutting behavior |
| `extension type` | Erased representation at runtime | Construct through its representation | Stronger static typing over an existing type |
| `extension` | Static dispatch | No separate extension object | Convenience methods and getters |
| `Record` | Structural value type | Record literal | Lightweight compound values |
| `typedef` | Type alias | Depends on the aliased type | Readable names for existing types |

The phrase *zero-cost abstraction* is a useful description of extension types, but it should not be interpreted as a blanket guarantee that every program has identical performance across every compiler and platform.

## 15. Where Each Construct Belongs in Dragon Ball Explorer

| Project location | Recommended construct | Reason |
|---|---|---|
| `domain/entities/character.dart` | `final class Character` | Controlled, immutable-by-design entity |
| `domain/entities/planet.dart` | `final class Planet` | Controlled entity representation |
| `domain/repositories/character_repository.dart` | `abstract interface class CharacterRepository` | Defines the data contract |
| `data/repositories/api_character_repository.dart` | `final class ApiCharacterRepository implements CharacterRepository` | Concrete infrastructure implementation |
| `core/errors/failure.dart` | `sealed class Failure` and final subtypes | Closed failure hierarchy |
| `core/result/result.dart` | `sealed class Result<T, E>` and final variants | Explicit success/failure outcomes |
| Filter definitions | `enum` | Finite application-controlled choices |
| Endpoint definitions | `abstract final class ApiEndpoints` | Static endpoint namespace |
| Small helper returns | Records | Avoid unnecessary temporary classes |
| Domain identifiers | Extension types, if useful | Prevent accidental ID mixing |
| Formatting helpers | Extensions | Add convenience without changing original types |
| Callback signatures | `typedef` | Improve readability |
| Reusable framework behavior | Mixins, when appropriate | Share behavior without unnecessary inheritance |

## 16. Recommended Design Rules

1. **Default to `final class` for concrete models** when inheritance is not part of the intended API.
2. **Use `abstract interface class` for repository contracts** when external implementations and test fakes should be permitted.
3. **Use `sealed` for genuinely closed alternatives**, such as a finite set of failures or result variants.
4. **Use exhaustive switches** to handle known variants and make missing cases visible to the compiler.
5. **Keep data parsing at the data boundary.** Convert API DTOs to domain entities rather than leaking raw JSON maps throughout the application.
6. **Do not confuse `final` references with deep immutability.** Protect mutable collections and nested objects as needed.
7. **Use `Result` and `AsyncValue` for their distinct responsibilities.** Document where errors are returned and where exceptions are thrown.
8. **Avoid overengineering.** Records, extension types, mixin classes, and elaborate inheritance hierarchies should solve a concrete problem.
9. **Keep repository contracts independent of Flutter and HTTP implementation details.**
10. **Treat API values as untrusted input.** Static typing does not replace JSON validation, parsing checks, or runtime constraints.

## 17. Final Mental Model

Think of Dart's type system as a set of tools for expressing design decisions:

- **Classes** model objects.
- **Class modifiers** constrain inheritance and implementation.
- **Interfaces** define contracts.
- **Sealed hierarchies** define closed alternatives.
- **Enums** represent fixed choices.
- **Records** group lightweight values.
- **Extension types** distinguish values sharing the same underlying representation.
- **Extensions** add convenient APIs.
- **Typedefs** name existing types.
- **Mixins** share behavior.

For Dragon Ball Explorer, the highest-value features to master first are `final class`, `abstract interface class`, `sealed class`, exhaustive switches, enums, immutable state, and generic `Result<T, E>` types. These directly support maintainable repositories, predictable error handling, and Riverpod-driven UI. Learn extension types and advanced mixin patterns after those foundations are solid.
