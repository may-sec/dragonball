Dart 3 introduced class modifiers that control whether a class can be **instantiated**, **extended**, **implemented**, or **mixed in**, both inside its defining library and by outside packages.

### Dart Class Modifiers Matrix

| Class Declaration | Can Instantiate (`new` / `()`)? | Can Extend (`extends`)? | Can Implement (`implements`)? | Can Mix In (`with`)? | Exhaustive `switch`? | Primary Use Case |
| --- | --- | --- | --- | --- | --- | --- |
| **`class`** (Standard) | Yes | Yes | Yes | No | No | Default open class; no restrictions anywhere. |
| **`base class`** | Yes | Yes | Inside library only | No | No | Guarantees inheritance hierarchy; prevents external `implements` so new members can be added safely. |
| **`interface class`** | Yes | Inside library only | Yes | No | No | Pure API contract; allows consumers to mock/implement but never reuse concrete base implementation. |
| **`final class`** | Yes | Inside library only | Inside library only | No | No | Completely closed implementation; prevents all external subclassing and interface imitation. |
| **`sealed class`** | No *(Implicitly abstract)* | Inside library only | Inside library only | No | **Yes** | Algebraic data types / state unions (e.g., `Result`, `Failure`, `AuthState`); forces exhaustive pattern matching. |
| **`abstract class`** | No | Yes | Yes | No | No | Classical base class; partially implemented or interface-only contract. |
| **`abstract base class`** | No | Yes | Inside library only | No | No | Base class requiring derivation, but preventing third parties from breaking encapsulation via `implements`. |
| **`abstract interface class`** | No | Inside library only | Yes | No | No | Pure interface (equivalent to Java/TypeScript `interface`). No concrete instantiation, only implementation. |
| **`abstract final class`** | No | No *(Nowhere)* | No *(Nowhere)* | No | No | Static namespace for constants, helper functions, and endpoint URLs (e.g., `ApiEndpoints`). |
| **`mixin class`** | Yes | Yes | Yes | Yes | No | Can be instantiated, extended, or used as a mixin (`with`). Cannot have `extends` clause or generative constructors. |
| **`base mixin class`** | Yes | Yes | Inside library only | Yes | No | A mixin class that forbids external `implements`. |

---

### Key Behavioral Rules

* **Library Boundary Restriction:** "Inside library only" means subclasses or implementations are only permitted within the same file or parts belonging to that library. Outside packages importing the file cannot extend or implement it.
* **Inheritance Contagion (`base`, `final`, `interface`):** When extending or implementing a `base` or `final` class, the child class must explicitly be declared as `base`, `final`, or `sealed` to prevent accidentally breaking the parent's restrictions.
* **Exhaustiveness (`sealed`):** Only `sealed` classes trigger compile-time exhaustiveness checking in Dart 3 `switch` statements and switch expressions without needing a `default` case.



Dart has a structured type system composed of several foundational type declarations, language constructs, and modifiers. Beyond basic classes and enums, Dart provides dedicated mechanisms for multiple inheritance, zero-cost type safety wrappers, anonymous data shapes, and compile-time metadata.

---

### Dart Type Declarations & Constructs Matrix

| Construct | Syntax Example | Memory / Runtime Nature | Can Instantiate? | Key Capabilities & Restrictions | Primary Use Case |
| --- | --- | --- | --- | --- | --- |
| **`class`** | `class User {}` | Full Heap Object | Yes | Supports inheritance, fields, methods, constructors. | General-purpose object-oriented modeling. |
| **`enum`** | `enum Status { ok, err }` | Canonical Heap Instances | No *(fixed instances)* | Fixed compile-time instances. Can declare fields, methods, interfaces, and enhanced constructors. | Fixed sets of constants (e.g., HTTP status, theme modes, directions). |
| **`mixin`** | `mixin Flying on Animal {}` | Code reuse unit *(no standalone identity)* | No | Plugs reusable methods/properties into classes via `with`. Cannot have generative constructors or `extends` clauses. Can constrain host with `on`. | Reusable cross-cutting behaviors (e.g., `WidgetsBindingObserver`, logging, serialization mixins). |
| **`extension type`** *(Dart 3.3+)* | `extension type Id(int _) {}` | Zero-cost abstraction *(erased at runtime to representation type)* | Yes *(wraps representation)* | Replaces the legacy `inline class`. Compile-time wrapper around a single backing representation. Adds specialized API without heap allocation overhead. | Type-safe primitive IDs (e.g., `UserId(int)` vs `PostId(int)`), zero-cost JS interop bindings. |
| **`extension`** | `extension on String {}` | Static dispatch *(sugar over static helper functions)* | No | Adds methods and getters to existing types without modifying their source code or creating subclasses. | String utilities (e.g., `str.capitalize()`), Date formatting, custom responsive context extensions (`context.screenHeight`). |
| **`Record`** *(Dart 3.0+)* | `(int, String) pair = (1, 'a');` | Anonymous immutable value type | Yes *(literal)* | Structural typing with structural equality (`==` compares field values). Supports positional and named fields. Destructured via patterns. | Returning multiple values from a function without declaring throwaway classes (e.g., `(charResult, planetResult)`). |
| **`typedef`** | `typedef IntList = List<int>;` | Type alias *(pure compile-time symbol)* | Follows aliased type | Creates semantic aliases for complex types, function signatures, or nested generics. | Function callbacks (`typedef JsonParser<T> = T Function(Map<String, dynamic>);`), complex map aliases. |

---

### Behavioral Deep Dive

#### 1. `extension type` vs. `class`

A standard wrapper class introduces heap allocation and garbage collection overhead:

```dart
// Regular class: Allocates a new heap object holding an int reference
class UserId {
  final int value;
  const UserId(this.value);
}

// Extension type: Completely erased at runtime; compiled directly as a primitive int!
extension type const UserId(int id) {
  bool get isValid => id > 0;
}

```

At runtime, `UserId` **is** an `int`. There is zero memory penalty, yet the compiler stops you from accidentally passing a `PostId` where a `UserId` is expected.

---

#### 2. `mixin` vs. `class`

Mixins provide horizontal code sharing without creating deep inheritance hierarchies:

```dart
mixin AutoLogger {
  void log(String message) => print('[LOG]: $message');
}

// Host classes inherit behaviors via 'with'
class AuthRepository with AutoLogger {
  void login() => log('Logging user in');
}

```

* Use `on` to constrain a mixin to specific base types:
```dart
mixin TickerProviderMixin on State<MyWidget> {} // Can only be mixed into State classes

```



---

#### 3. `Record` vs. `class`

Instead of writing an entire class just to bundle two or three values:

```dart
// No boilerplate class needed:
(String name, {int age, bool isAdmin}) fetchUserData() {
  return ('Alex', age: 28, isAdmin: true);
}

void main() {
  final (name, :age, :isAdmin) = fetchUserData(); // Pattern destructuring
  print('$name is $age years old.');
}

```

Records compare by **value**, meaning `('a', 1) == ('a', 1)` evaluates to `true` out of the box.

---

#### 4. `extension` Methods

Allows extending third-party libraries and primitive types without inheritance:

```dart
extension StringCasing on String {
  String toCapitalized() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}

void main() {
  print('dragonBall'.toCapitalized()); // "Dragonball"
}

```

---

### Type Categories

```
All Dart Types (Object?)
  │
  ├── Nominal Reference Types (Heap Objects)
  │     ├── class (standard, base, interface, final, sealed, abstract)
  │     ├── enum (fixed canonical constant objects)
  │     └── mixin class (dual-nature mixin and instantiable class)
  │
  ├── Structural Types
  │     └── Record (anonymous, immutable, field-value equality)
  │
  ├── Zero-Cost Abstractions (Compile-Time Only)
  │     ├── extension type (erased to underlying primitive/object at runtime)
  │     └── typedef (type alias symbol)
  │
  └── Static Dispatch Augmentations
        └── extension (syntactic sugar adding methods to existing types)

```