# Step 1 — Create the Flutter Project & Entry Point

### 1. Objective

Scaffold a clean Flutter project (`dragonball_learning`), verify the toolchain on an emulator or device, and replace the default counter template in `lib/main.dart` with a minimal Material root (`MaterialApp` + `Scaffold`) that mounts `DragonBallApp`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Root application widget** | `MaterialApp` | `CupertinoApp` or raw `WidgetsApp` | `MaterialApp` configures Material 3 theming, `Navigator` routing, `Localizations`, and default text/ink behaviors out of the box across Android, iOS, Web, and Desktop—whereas `WidgetsApp` renders black screens with raw yellow-underlined text until you configure everything manually. |
| **Screen skeleton** | `Scaffold` (`appBar` + `body`) | Returning a bare `Center(child: Text(...))` directly under `MaterialApp` | `Scaffold` establishes proper Material surface elevation, safe-area inset handling, and standard `AppBar` layout structure from the very first commit. |
| **Root widget type** | `StatelessWidget` (`const DragonBallApp({super.key})`) | Keeping the generated `StatefulWidget` counter template | The root app shell owns no mutable state at Step 1; a `const` `StatelessWidget` keeps the entry point minimal and allows Flutter to skip unnecessary root rebuilds. |

---

### 3. Initial Setup & `lib/main.dart`

#### A. Scaffold & Verify the Project

```bash
flutter create dragonball_learning
cd dragonball_learning
flutter run

```

#### B. Replace `lib/main.dart` with a Clean Entry Point

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const DragonBallApp());
}

class DragonBallApp extends StatelessWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dragon Ball Universe',
      home: Scaffold(
        appBar: AppBar(title: const Text('Dragon Ball Universe')),
        body: const Center(
          child: Text('Welcome to Dragon Ball Universe'),
        ),
      ),
    );
  }
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **`void main()` → `runApp(...)`:** `main()` is the Dart VM's entry point. `runApp()` inflates the root `Widget` into an `Element` tree, attaches it to Flutter's rendering pipeline, and schedules the initial frame.
* **`const DragonBallApp({super.key})`:** Forwarding `super.key` lets Flutter identify and preserve the widget's position in the element tree across hot reloads and parent updates, while `const` canonicalizes the instance at compile time.
* **`debugShowCheckedModeBanner: false`:** Hides the diagonal `"DEBUG"` ribbon in the top-right corner so it never overlaps `AppBar` action buttons (like the settings gear or favorite heart you add in later steps).

---

### 5. Initial Widget Tree

```text
main()
 └── runApp(const DragonBallApp())
      └── MaterialApp (Navigator, Theme, MediaQuery)
           └── Scaffold (Surface, SafeArea, Layout Slots)
                ├── AppBar ('Dragon Ball Universe')
                └── Center ──▶ Text('Welcome to Dragon Ball Universe')

```

---

All **20 steps** (1 → 20 and 10 → 1) are now documented in the exact same concise, architectural format! Where would you like to take the project or your documentation next?












# Step 2 — Build a Static Homepage (`GridView.builder`)

### 1. Objective

Extract the home screen out of `lib/main.dart` into `lib/screens/home_screen.dart` and render a 2-column scrollable character grid (`GridView.builder`) backed by a static dummy list—establishing the visual card proportions and Material 3 theme before connecting a live API.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Grid layout widget** | `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount` | `GridView.count(children: [...])` or nested `Column` + `Row`s | `GridView.builder` instantiates and recycles items lazily as they enter the viewport. `GridView.count` builds every child upfront in memory regardless of scroll position. |
| **Card corner clipping** | `Card(clipBehavior: Clip.antiAlias, ...)` | Leaving `clipBehavior` at its default (`Clip.none`) | Without `Clip.antiAlias`, a full-bleed top image container bleeds sharp 90° corners outside the `Card`'s rounded Material border. |
| **Screen organization** | Dedicated `lib/screens/home_screen.dart` file | Keeping `Scaffold` inline inside `lib/main.dart` | Separates app-level configuration (`MaterialApp`, `ThemeData`) from screen-level UI early so navigation and state remain clean as the project grows. |

---

### 3. Delta Changes

#### A. Create `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List> characters = const [
    {'name': 'Goku', 'race': 'Saiyan'},
    {'name': 'Vegeta', 'race': 'Saiyan'},
    {'name': 'Piccolo', 'race': 'Namekian'},
    {'name': 'Frieza', 'race': 'Frieza Race'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dragon Ball Universe')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: characters.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, index) {
          final character = characters[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.orange.shade100,
                    child: const Icon(Icons.person, size: 80),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(character['race']!),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

```

#### B. Update `lib/main.dart`

Point `MaterialApp.home` to `HomeScreen` and configure a Material 3 `ColorScheme`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  useMaterial3: true,
),
home: const HomeScreen(),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `childAspectRatio: 0.70`?** `GridView` tiles don't size themselves from their children—their dimensions are strictly dictated by the `gridDelegate`. `0.70` (width / height) gives portrait-oriented cards tall enough to showcase full-body character artwork above the name and race labels.
* **Why `Expanded` wraps the image container inside the card's `Column`:** The bottom `Padding` block takes up its natural text height first, and `Expanded` hands 100% of the remaining vertical height inside the fixed-aspect tile to the image area—preventing any bottom overflow regardless of screen width.
* **Why `crossAxisAlignment: CrossAxisAlignment.stretch` on the card's `Column`:** Forces the placeholder `Container` to fill the full card width instead of shrinking to wrap the `80px` `Icon`.

---

### 5. Widget Tree Blueprint

```text
DragonBallApp (MaterialApp + Material 3 ColorScheme)
 └── HomeScreen (Scaffold)
      ├── AppBar ('Dragon Ball Universe')
      └── GridView.builder (crossAxisCount: 2, childAspectRatio: 0.70)
           └── Card (clipBehavior: Clip.antiAlias)
                └── Column (stretch)
                     ├── Expanded ──▶ Image Placeholder Container
                     └── Padding  ──▶ Name (Bold) + Race

```

---

Say **1** whenever you're ready for the final step (**Step 1**)!









# Step 3 — Create the `Character` Model

### 1. Objective

Replace untyped `Map<String, String>` entries in `HomeScreen` with a dedicated, strongly typed `Character` data model in `lib/models/character.dart` so the Dart compiler catches missing fields and typos at compile time instead of crashing at runtime.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Data representation** | Immutable `Character` class with `final` fields and a `const` constructor | Keeping `List>` (`character['name']!`) | Maps have zero IDE autocomplete, silently return `null` on key typos (`character['nmae']`), and force bang operators (`!`) everywhere. A typed class guarantees every field exists at compile time. |
| **Mutability** | All fields marked `final` + `const` constructor | Mutable fields (`String name;`) | Model objects represent snapshot data from an API—making them immutable prevents accidental state mutation across widgets and allows compile-time `const` instances for static/test lists. |

---

### 3. Delta Changes

#### A. Create `lib/models/character.dart`

```dart
class Character {
  final int id;
  final String name;
  final String race;
  final String gender;

  const Character({
    required this.id,
    required this.name,
    required this.race,
    required this.gender,
  });
}

```

#### B. Update `HomeScreen` to use `List<Character>` (`lib/screens/home_screen.dart`)

```dart
final List<Character> characters = const [
  Character(id: 1, name: 'Goku', race: 'Saiyan', gender: 'Male'),
  Character(id: 2, name: 'Vegeta', race: 'Saiyan', gender: 'Male'),
  Character(id: 3, name: 'Piccolo', race: 'Namekian', gender: 'Male'),
  Character(id: 4, name: 'Frieza', race: 'Frieza Race', gender: 'Male'),
];

// Inside GridView.builder's itemBuilder:
Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
Text(character.race),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `required` on every named parameter?** Named parameters (`{required this.id, ...}`) make call sites self-documenting (`Character(id: 1, name: 'Goku', ...)` instead of positional `Character(1, 'Goku', 'Saiyan', 'Male')` where swapping two `String` arguments compiles silently with wrong data).
* **Why `const` constructor matters:** Because every field in `Character` is `final`, marking the constructor `const` lets Dart canonicalize identical `Character` literals at compile time—reusing a single memory allocation across rebuilds.

---

### 5. Structural Upgrade

```text
Before (Step 2): Map<String, String> ──▶ character['name']! (runtime crash risk, no autocomplete)
After  (Step 3): Character           ──▶ character.name     (compile-time safe, full IDE support)

```

---

Say **2** whenever you're ready for **Step 2**!










# Step 4 — Make the First API Request

### 1. Objective

Add the official `http` package to `pubspec.yaml` and execute an asynchronous HTTP `GET` request against `[https://dragonball-api.com/api/characters](https://dragonball-api.com/api/characters)` to verify live network connectivity and inspect the raw response status and JSON payload.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **HTTP client package** | Official `http` package (`flutter pub add http`) | `dart:io` `HttpClient` or `dio` | `dart:io`'s `HttpClient` is verbose and throws `Unsupported operation` on Flutter Web; `dio` adds heavy interceptor/form-data machinery we don't need for straightforward REST `GET` requests. `http` is lightweight, multi-platform, and maintained by the Dart team. |
| **Execution model** | `async` / `await` returning `Future<http.Response>` | Synchronous blocking network calls (not possible in Dart) or nested `.then()` callbacks | `async` / `await` reads top-to-bottom like synchronous code while yielding execution back to Flutter's single-threaded event loop so the UI stays responsive at 60/120fps. |

---

### 3. Delta Changes

#### A. Install the `http` Package

```bash
flutter pub add http

```

*(Updates `pubspec.yaml` under `dependencies:` and downloads the package into `.dart_tool/package_config.json`.)*

#### B. Execute the First `GET` Request

```dart
import 'package:http/http.dart' as http;

Future<void> testFetchCharacters() async {
  final uri = Uri.parse('https://dragonball-api.com/api/characters');
  final response = await http.get(uri);

  debugPrint('Status Code: ${response.statusCode}');
  debugPrint('Body: ${response.body}');
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `Uri.parse(...)` instead of passing a raw `String`?** `http.get()` accepts a `Uri` object rather than a plain `String` so scheme (`https`), host (`dragonball-api.com`), path (`/api/characters`), and query parameters are validated and properly URL-encoded before hitting the wire.
* **Why `response.body` is a raw `String`:** At the HTTP transport layer, the server sends raw UTF-8 bytes (`response.bodyBytes`), which `http` decodes into a JSON-formatted `String` (`response.body`)—it does not yet know anything about `Character` objects until Step 6 runs `jsonDecode()`.
* **Android / macOS Network Permissions Note:** While Android debug builds include `INTERNET` permission by default, release `AndroidManifest.xml` (and macOS `DebugProfile.entitlements` / `Release.entitlements`) require `android.permission.INTERNET` / `com.apple.security.network.client` for outbound HTTPS calls.

---

### 5. Request Lifecycle

```text
Uri.parse('https://dragonball-api.com/api/characters')
       │
       ▼
await http.get(uri)  ──(Event loop stays free while waiting on network)──▶ Dragon Ball REST API
                                                                                  │
  http.Response (statusCode: 200, body: '{"items":[...]}')  ◀─────────────────────┘

```

---

Say **3** whenever you're ready for **Step 3**!









# Step 5 — Create a Separate API Service

### 1. Objective

Move network logic (`Uri.parse`, `http.get`, and HTTP status code validation) out of UI widgets and into a dedicated `DragonBallApi` service class in `lib/services/dragon_ball_api.dart`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Where HTTP calls live** | Dedicated `DragonBallApi` class inside `lib/services/` | Calling `http.get()` directly inside `HomeScreen` | Keeps URLs, endpoints, and HTTP status checks in one place—so adding `/planets` or `/characters/$id` later doesn't clutter widget code or duplicate error checks across screens. |
| **Non-200 status handling** | Check `if (response.statusCode != 200) throw Exception(...)` | Returning `response` regardless of status code | `http.get()` does **not** throw on `404` or `500` responses—it resolves normally with an error body. Checking `statusCode != 200` surfaces server failures immediately instead of letting JSON parsing fail with cryptic errors later. |
| **Base URL storage** | `static const _baseurl = '[https://dragonball-api.com/api](https://dragonball-api.com/api)';` | Repeating the full URL string inside every method | Single source of truth if the API domain or version prefix ever changes, and `static const` allocates it once at compile time. |

---

### 3. Delta Changes

#### Create `lib/services/dragon_ball_api.dart`

```dart
import 'package:http/http.dart' as http;

class DragonBallApi {
  static const _baseurl = 'https://dragonball-api.com/api';

  Future<http.Response> fetchCharacters() async {
    final uri = Uri.parse('$_baseurl/characters');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Characters Status Code: ${response.statusCode}');
    }

    return response;
  }
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `import 'package:http/http.dart' as http;`?** Using the `as http` prefix namespaces top-level functions (`http.get`, `http.post`, `http.Response`) so they never collide with Flutter's own classes or your custom service methods.
* **Why `static const _baseurl` starts with `_`?** In Dart, a leading underscore makes the field library-private—external screens can call `api.fetchCharacters()`, but cannot reach in and mutate or couple directly to `_baseurl`.
* **Why return `Future<http.Response>` first before adding JSON parsing (Step 6)?** Separating transport (`DragonBallApi` fetching raw bytes) from serialization (`Character.fromJson` in Step 6) lets you test that the network layer and HTTP status checks work cleanly before introducing JSON decoding.

---

### 5. Responsibility Boundary

```text
UI Layer (HomeScreen)                    Service Layer (DragonBallApi)
 ├── Calls api.fetchCharacters()   ───▶   ├── Builds Uri ('$_baseurl/characters')
 └── Receives Future<Response>     ◀───   ├── Executes await http.get(uri)
                                          └── Validates response.statusCode == 200

```

---

Say **4** whenever you're ready for **Step 4**!












# Step 6 — Parse JSON into `Character` Objects

### 1. Objective

Decode the raw JSON string returned by `DragonBallApi` into strongly typed `List<Character>` objects using `jsonDecode()` and a null-safe `factory Character.fromJson` constructor.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **JSON deserialization** | Manual `factory Character.fromJson(Map<String, dynamic>)` | `json_serializable` / `freezed` code generation | Zero `build_runner` watch processes or generated `.g.dart` boilerplate for a small set of models, while keeping full control over fallback logic. |
| **Reading JSON string fields** | Local helper `readString(key, fallback: ...)` checking `value == null` | Direct cast `json['race'] as String` | Public REST APIs frequently omit fields or return `null` for unknown attributes; `as String` throws a fatal runtime `TypeError` on `null`, whereas `readString` degrades gracefully. |
| **Parsing numeric IDs** | `(json['id'] as num).toInt()` | `json['id'] as int` | JSON has only one number type; depending on the backend serializer, an integer ID can arrive as `1` or `1.0`—casting via `num` handles both safely. |

---

### 3. Delta Changes

#### A. Expand `Character` and Add `fromJson` (`lib/models/character.dart`)

```dart
class Character {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String image;
  final String affiliation;

  const Character({
    required this.id,
    required this.name,
    required this.ki,
    required this.maxKi,
    required this.race,
    required this.gender,
    required this.description,
    required this.image,
    required this.affiliation,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];

      if (value == null) {
        return fallback;
      }

      return value.toString();
    }

    return Character(
      id: (json['id'] as num).toInt(),
      name: readString('name', fallback: 'Unknown'),
      ki: readString('ki', fallback: 'Unknown'),
      maxKi: readString('maxKi', fallback: 'Unknown'),
      race: readString('race', fallback: 'Unknown'),
      gender: readString('gender', fallback: 'Unknown'),
      description: readString('description'),
      image: readString('image'),
      affiliation: readString('affiliation', fallback: 'Unknown'),
    );
  }
}

```

#### B. Return `Future<List<Character>>` from `DragonBallApi` (`lib/services/dragon_ball_api.dart`)

```dart
import 'dart:convert';
import 'package:dragonball_learning/models/character.dart';
import 'package:http/http.dart' as http;

// Inside DragonBallApi:
Future<List<Character>> fetchCharacters() async {
  final uri = Uri.parse('$_baseurl/characters');
  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception('Failed to load Characters Status Code: ${response.statusCode}');
  }

  final decodedData = jsonDecode(response.body);
  final items = decodedData['items'] as List;

  return items.map((item) => Character.fromJson(item)).toList();
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why a `factory` constructor instead of a normal constructor?** A standard Dart constructor must immediately initialize `final` fields before its body runs. A `factory` constructor acts like a static method that can run parsing logic, declare local helper functions (`readString`), validate inputs, and then return a newly constructed `Character`.
* **Why `decodedData['items'] as List`?** The Dragon Ball API wraps paginated responses in an envelope object (`{"items": [...], "meta": {...}, "links": {...}}`) rather than returning a top-level JSON array—so we extract `'items'` first before mapping each element.
* **Why `.toList()` at the end of `.map(...)`?** `Iterable.map()` is lazy in Dart; calling `.toList()` materializes the `Character` objects immediately inside `fetchCharacters()` instead of re-running `fromJson` every time the UI iterates over the list.

---

### 5. Data Flow

```text
response.body (Raw JSON String)
       │
       ▼  jsonDecode()
Map<String, dynamic> (Envelope: { "items": [...], "meta": {...} })
       │
       ▼  decodedData['items'] as List
List<dynamic> (Raw JSON Maps)
       │
       ▼  items.map((item) => Character.fromJson(item)).toList()
List<Character> (Strongly Typed Objects)

```

---

Say **5** whenever you're ready for **Step 5**!










Got it—I'll drop the README entry block going forward. Here is **Step 7** in the exact same concise format.

---

# Step 7 — Display Real API Data (`FutureBuilder`)

### 1. Objective

Replace the hardcoded `List<Character>` in `HomeScreen` with live data fetched from `DragonBallApi.fetchCharacters()`, using `FutureBuilder` to bridge asynchronous network results into Flutter's synchronous `build()` method.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Managing async UI states** | `FutureBuilder<List<Character>>` | Manual `_isLoading`, `_error`, and `_characters` flags updated via `setState()` in `initState()` | Eliminates three separate state variables that can accidentally fall out of sync (e.g., forgetting `_isLoading = false` inside a `catch` block). |
| **Where the `Future` is created** | Stored in `late Future<List<Character>> _charactersFuture` inside `initState()` | Calling `future: _api.fetchCharacters()` directly inside `build()` | Flutter calls `build()` frequently (on rotations, theme changes, keyboard popups, or parent rebuilds). Creating the `Future` inside `build()` would re-fire an HTTP request on every single rebuild. |

---

### 3. Delta Changes (`lib/screens/home_screen.dart`)

#### A. Convert `HomeScreen` to `StatefulWidget` and cache the `Future` in `initState()`

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DragonBallApi _api = DragonBallApi();
  late Future<List<Character>> _charactersFuture;

  @override
  void initState() {
    super.initState();
    _charactersFuture = _api.fetchCharacters();
  }

```

#### B. Wrap the Grid inside `FutureBuilder<List<Character>>`

```dart
body: FutureBuilder<List<Character>>(
  future: _charactersFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final characters = snapshot.data!;

    return GridView.builder(
      // ... existing gridDelegate & itemBuilder using `characters` ...
    );
  },
)

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `StatelessWidget` couldn't hold `_charactersFuture`:** A `StatelessWidget` is recreated from scratch every time its parent rebuilds—it has no persistent `State` object across rebuilds to hold onto an in-flight `Future`. Converting to `StatefulWidget` gives `_charactersFuture` a stable home in `_HomeScreenState`.
* **Why `late` is used on `late Future<List<Character>> _charactersFuture`:** Dart's null safety requires non-nullable fields to be initialized before the constructor finishes, or marked `late` when initialized in `initState()` (which always runs before the first `build()`).

---

### 5. Data Flow

```text
HomeScreen mounted
       │
       ▼
  initState() ──▶ _charactersFuture = _api.fetchCharacters() (runs ONCE)
       │
       ▼
    build() ───▶ FutureBuilder(future: _charactersFuture)
                      │
                      ├── AsyncSnapshot (waiting) ──▶ CircularProgressIndicator
                      ├── AsyncSnapshot (error)   ──▶ Error Text
                      └── AsyncSnapshot (data)    ──▶ GridView.builder(snapshot.data!)

```

---

Say **6** whenever you're ready for **Step 6**!








Here is **Step 8** again, kept strictly focused on the exact code delta, engineering reasoning, and the README entry.

---

# Step 8 — Handle Loading, Errors, Empty States & Retry

### 1. Objective

Harden `HomeScreen`'s `FutureBuilder` so every possible network outcome—in-flight loading, failed request (with a working **Retry** button), empty list, and valid data—renders an intentional UI state instead of crashing on `snapshot.data!`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **How Retry triggers a new fetch** | Reassign `_charactersFuture = _api.fetchCharacters()` inside `setState()` | Calling `_api.fetchCharacters()` inside `onPressed` without `setState()` | `FutureBuilder` only subscribes to a new `Future` when `build()` runs with a new `future` instance—without `setState()`, the UI stays stuck on the error screen forever. |
| **Where errors are handled** | Let `DragonBallApi` throw an `Exception`, and catch it via `snapshot.hasError` in `FutureBuilder` | Catching errors inside `DragonBallApi` and returning an empty `[]` list | Returning `[]` on error hides network failures behind `"No characters found."` and denies the user a **Retry** button. |
| **Order of snapshot checks** | `waiting` → `hasError` → `!hasData || data!.isEmpty` → `data!` | Calling `snapshot.data!` before checking `hasError` or `isEmpty` | Accessing `snapshot.data!` when `hasError` is true throws a fatal `Null check operator used on a null value` crash. |

---

### 3. Delta Changes (`lib/screens/home_screen.dart`)

#### A. Add `_retryFetchCharacters()` inside `_HomeScreenState`

```dart
void _retryFetchCharacters() {
  setState(() {
    _charactersFuture = _api.fetchCharacters();
  });
}

```

#### B. Ordered `AsyncSnapshot` Guards inside `FutureBuilder.builder`

```dart
// 1. Loading state
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

// 2. Error state
if (snapshot.hasError) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Unable to load characters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(snapshot.error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _retryFetchCharacters,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

// 3. Empty state
if (!snapshot.hasData || snapshot.data!.isEmpty) {
  return const Center(
    child: Text('No characters found.', style: TextStyle(fontSize: 18)),
  );
}

// 4. Success state
final characters = snapshot.data!;

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `mainAxisSize: MainAxisSize.min` on the error `Column`?** By default, `Column` expands to fill all available vertical height (`MainAxisSize.max`), which pushes its children to the top edge instead of letting `Center` center them vertically. `MainAxisSize.min` shrinks the `Column` to wrap its children tightly so `Center` centers the entire error block on screen.
* **Why `snapshot.connectionState == ConnectionState.waiting` matters during Retry:** When `_retryFetchCharacters()` assigns a brand-new `Future` inside `setState()`, `FutureBuilder` resets `connectionState` back to `ConnectionState.waiting`—immediately swapping the error screen back to the `CircularProgressIndicator` while the retry request runs.

---

### 5. Snapshot State Machine

```text
_charactersFuture
       │
       ▼
  FutureBuilder
       ├── connectionState == waiting ──▶ CircularProgressIndicator
       ├── snapshot.hasError          ──▶ Error UI + Retry ─▶ setState(_charactersFuture = new fetch)
       ├── !hasData || data!.isEmpty  ──▶ 'No characters found.'
       └── Success                    ──▶ GridView.builder(characters)

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 8 — Handle Loading, Errors, Empty States & Retry

### Delta (`lib/screens/home_screen.dart`)
- Added `_retryFetchCharacters()` reassigning `_charactersFuture` inside `setState()`.
- Structured `FutureBuilder` into four explicit branches: `waiting` (spinner), `hasError` (error message + `ElevatedButton.icon` retry), empty check (`!hasData || data!.isEmpty`), and success (`GridView.builder`).

### Chosen vs. Alternatives
- **Chosen:** Throwing exceptions from `DragonBallApi` and branching on `AsyncSnapshot` states with `setState` retry.
- **Alternatives:** Returning `[]` on error inside the service (masks offline failures as empty results) or retrying without `setState()` (UI never updates).

### Learned
- Reassigning the `Future` inside `setState()` forces `FutureBuilder` to subscribe to the new request and transition back to `ConnectionState.waiting`.
- `mainAxisSize: MainAxisSize.min` is required on a `Column` inside `Center` so the block centers vertically.

```

---

Say **7** whenever you're ready to move down to **Step 7**!









# Step 9 — Create a Reusable `CharacterCard` Widget

### 1. Objective

Extract the character card UI out of `HomeScreen`'s `GridView.builder` into a standalone, reusable `CharacterCard` widget—and upgrade the placeholder icon to real network images with graceful fallback handling.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **How to extract the card** | Standalone `StatelessWidget` class (`CharacterCard`) in `lib/widgets/character_card.dart` | Private helper method `Widget _buildCard(Character c)` inside `_HomeScreenState` | A private helper method is locked inside one screen and cannot be reused by Favorites or Explore. A separate `StatelessWidget` class is reusable across screens and gives Flutter its own `Element` boundary in the widget tree. |
| **Constructor parameter** | Pass the full model (`required this.character`) | Pass individual fields (`name`, `race`, `image`) | Passing the `Character` object keeps the constructor clean and means adding a favorite heart or tap navigation later doesn't require changing constructor signatures everywhere. |
| **Broken image handling** | `Image.network(..., errorBuilder: ...)` | Leaving `errorBuilder` unset | Without `errorBuilder`, any 404 or dead image URL throws an uncaught `NetworkImageLoadException` in debug mode and leaves a blank broken space in release builds. |

---

### 3. Delta Changes

#### A. Create `lib/widgets/character_card.dart`

```dart
import 'package:dragonball_learning/models/character.dart';
import 'package:flutter/material.dart';

class CharacterCard extends StatelessWidget {
  final Character character;

  const CharacterCard({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              character.image,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 48));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  character.race,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

```

#### B. Simplify `GridView.builder` in `lib/screens/home_screen.dart`

Replace the inline `Card(...)` inside `itemBuilder` with:

```dart
itemBuilder: (context, index) {
  final character = characters[index];
  return CharacterCard(character: character);
},

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `maxLines: 1` + `overflow: TextOverflow.ellipsis`?** Grid cells have a fixed aspect ratio (`0.70`), meaning vertical height is strictly bounded. If a character has a long name or race (like `"Majin Buu (Pure Evil)"`), a 2-line wrap would push the bottom `Text` past the card's bottom edge and trigger a `RenderFlex overflowed` error. `ellipsis` truncates cleanly with `...`.
* **Why `width: double.infinity` + `fit: BoxFit.cover`?** `BoxFit.cover` scales the image uniformly so it fills both width and height of the `Expanded` box without distorting proportions, cropping excess edges rather than leaving empty sidebars.
* **Why `StatelessWidget` here?** `CharacterCard` receives an immutable `Character` and renders it deterministically—it owns no changing internal state of its own.

---

### 5. Responsibility Split

```text
HomeScreen (Data & States)                CharacterCard (Presentation)
 ├── Fetches _charactersFuture             ├── Receives final Character
 ├── Handles Loading / Error / Empty       ├── Renders Image.network + errorBuilder
 └── GridView.builder ───────────────────▶ └── Displays truncated name & race

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 9 — Create a Reusable `CharacterCard` Widget

### Delta
- **`lib/widgets/character_card.dart`:** Extracted card UI into `CharacterCard({required this.character})` and replaced the placeholder icon with `Image.network` + `errorBuilder`.
- **`lib/screens/home_screen.dart`:** Simplified `GridView.builder`'s `itemBuilder` to return `CharacterCard(character: characters[index])`.

### Chosen vs. Alternatives
- **Chosen:** Standalone `StatelessWidget` accepting `Character`. Reusable across screens and isolates card layout from screen fetching logic.
- **Alternatives:** Private helper method `_buildCard()` inside `_HomeScreenState` (locked to one screen) or passing individual string fields instead of the `Character` object.

### Learned
- `maxLines: 1` with `TextOverflow.ellipsis` prevents long text from overflowing fixed-height grid cards.
- `Image.network(..., errorBuilder: ...)` catches broken image URLs gracefully with a fallback icon.

```

---

Say **8** (or **next**) whenever you're ready for **Step 8**!









# Step 10 — Create Character Details Screen and Navigation

### 1. Objective

Build `CharacterDetailsScreen` to display a character's full profile (larger image, stats, and long description) and wire `CharacterCard` so tapping any card pushes that screen onto the navigation stack.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Passing data to Details** | Pass the existing `Character` object directly via constructor (`CharacterDetailsScreen(character: character)`) | Pass only `character.id` and fetch `GET /characters/$id` again, or use untyped named routes (`pushNamed`) | Zero loading delay (we already fetched all base fields on the home screen), saves bandwidth, and gives compile-time type safety. |
| **Scrollable layout** | `SingleChildScrollView` + `Column` | Plain `Column` without scrolling | Character descriptions vary wildly in length; a plain `Column` throws a yellow-and-black `RenderFlex overflowed` error on smaller screens. |
| **Tap feedback** | `InkWell` wrapping the `Card`'s inner `Column` | `GestureDetector` | `InkWell` provides native Material ripple feedback on tap, and placing it *inside* `Card` (with `clipBehavior: Clip.antiAlias`) keeps the ripple clipped neatly to the card's rounded corners. |

---

### 3. Delta Changes

#### A. Create `lib/screens/character_details_screen.dart`

```dart
import 'package:dragonball_learning/models/character.dart';
import 'package:flutter/material.dart';

class CharacterDetailsScreen extends StatelessWidget {
  final Character character;
  const CharacterDetailsScreen({super.key, required this.character});

  Widget _detailrow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.network(
                character.image,
                height: 300,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 300,
                    child: Icon(Icons.broken_image_outlined, size: 64),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Text(character.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 30),
            _detailrow("id", character.id.toString()),
            _detailrow("ki", character.ki),
            _detailrow("maxKi", character.maxKi),
            _detailrow("race", character.race),
            _detailrow("gender", character.gender),
            _detailrow("affiliation", character.affiliation),
            const SizedBox(height: 30),
            const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(character.description, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

```

#### B. Make `CharacterCard` Tappable (`lib/widgets/character_card.dart`)

Wrap the existing `Column` inside `InkWell`:

```dart
child: InkWell(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CharacterDetailsScreen(character: character),
      ),
    );
  },
  child: Column(
    // ... existing image and text children ...
  ),
),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `fit: BoxFit.contain` on the details image vs. `BoxFit.cover` on the card?** On `CharacterDetailsScreen`, the goal is inspecting the full character artwork without cropping off hair, aura, or boots—`BoxFit.contain` scales the entire image inside `height: 300` without trimming edges.
* **Why `SizedBox(width: 110)` + `Expanded` inside `_detailrow`?** Giving the label column a fixed width (`110`) aligns every value column vertically into a clean two-column table, while `Expanded` ensures long affiliation names wrap onto a second line instead of overflowing horizontally.
* **Why `MaterialPageRoute<void>`?** The `<void>` generic tells Dart this pushed route doesn't return a result value when popped (unlike a selection dialog that might return `<bool>`).

---

### 5. Navigation Flow

```text
HomeScreen
    │
    ▼
CharacterCard ──(InkWell onTap)──▶ Navigator.of(context).push()
                                            │
                                            ▼
                                    MaterialPageRoute<void>
                                            │
                                            ▼
                            CharacterDetailsScreen(character: character)
                                            │
                              (AppBar Back Button ─▶ Navigator.pop)

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 10 — Create Character Details Screen and Navigation

### Delta
- **`lib/screens/character_details_screen.dart`:** Built `CharacterDetailsScreen({required this.character})` with `SingleChildScrollView`, `BoxFit.contain` hero image, reusable `_detailrow(title, value)` stat rows, and full description.
- **`lib/widgets/character_card.dart`:** Wrapped the card's inner `Column` in `InkWell` calling `Navigator.of(context).push(MaterialPageRoute<void>(...))`.

### Chosen vs. Alternatives
- **Chosen:** Passing the already-loaded `Character` object directly via constructor into `MaterialPageRoute`. Zero network delay and compile-time type safety.
- **Alternatives:** Passing only `character.id` and re-fetching from the API (adds unnecessary loading latency) or untyped named routes (`pushNamed`).

### Learned
- `Navigator.of(context).push()` pushes a new route onto the navigation stack and automatically gives `AppBar` a back button.
- `InkWell` inside a clipped `Card` provides Material ripple feedback constrained to the card's rounded corners.
- `SingleChildScrollView` prevents vertical `RenderFlex` overflow when descriptions are long.

```

---

Say **9** (or **next**) whenever you're ready for **Step 9**!










# Step 11 — Search & In-Memory Filtering

### 1. Objective

Add a live search bar to `HomeScreen` that filters characters by name instantaneously as you type—using `TextEditingController` and `setState`—without triggering new network requests on every keystroke.

---

### 2. Chosen vs. Alternatives

| Approach | How it works | Trade-offs & Verdict |
| --- | --- | --- |
| **A. API Search (`GET /characters?name=goku`)** | Fires a new HTTP request on every keystroke (usually paired with a debounce timer). | **Rejected:** Adds network latency on every query, wastes API rate limits, and breaks offline even when we already downloaded the dataset. |
| **B. In-Memory Filtering (`setState` + `.where()`)** | Keeps `_charactersFuture` cached in `_HomeScreenState`, tracks `_searchQuery` in state, and filters the resolved list synchronously inside `build()`. | **Chosen:** 0ms instant filtering, works offline once loaded, and keeps state local before we introduce Riverpod in Step 13. |

---

### 3. Delta Changes (`lib/screens/home_screen.dart`)

#### A. Add controller & query state inside `_HomeScreenState`

```dart
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';

@override
void dispose() {
  _searchController.dispose(); // Releases native text-input channel listeners
  super.dispose();
}

```

#### B. Wrap `FutureBuilder` inside `Column` + `Expanded` and filter `snapshot.data!`

*(Keep your existing loading, error, and `GridView.builder` setup—only add the `TextField` above `Expanded` and swap `characters` for `filtered`.)*

```dart
body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    ),
    Expanded(
      child: FutureBuilder<List<Character>>(
        future: _charactersFuture,
        builder: (context, snapshot) {
          // ... keep existing waiting & hasError guards ...

          final query = _searchQuery.trim().toLowerCase();
          final filtered = (snapshot.data ?? [])
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No characters found.'));
          }

          // Pass `filtered` (instead of `characters`) to your existing GridView.builder
        },
      ),
    ),
  ],
),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `initState` caching pays off here:** Because `_charactersFuture` was initialized in `initState()` (Step 7) instead of `build()`, calling `setState(() => _searchQuery = value)` re-runs `build()` against the **already-completed** `Future`—zero extra HTTP calls.
* **Why `Expanded` is mandatory:** `Column` passes unbounded vertical height to its children, while `GridView` tries to expand infinitely. `Expanded` constrains `FutureBuilder` (and `GridView`) to the remaining screen height below the `TextField`.
* **Why `.trim().toLowerCase()`:** Mobile keyboards auto-capitalize first letters (`"Goku"`) and often append trailing spaces (`"Goku "`). Normalizing both sides prevents missed matches.
* **Why `dispose()` is mandatory:** `TextEditingController` attaches listeners to Flutter's platform text channel; failing to dispose it leaks memory when the route is popped.

---

### 5. Data Flow

```text
User types "gok"
       │
       ▼
TextField.onChanged ──▶ setState(() => _searchQuery = "gok")
                                │
                                ▼
                       HomeScreen.build()
                                │
        ┌───────────────────────┴───────────────────────┐
        ▼                                               ▼
_charactersFuture (cached in RAM)               _searchQuery ("gok")
        │                                               │
        └───────────────────────┬───────────────────────┘
                                ▼
             snapshot.data!.where(name match) ──▶ GridView.builder(filtered)

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 11 — Search & In-Memory Filtering

### Delta (`lib/screens/home_screen.dart`)
- Added `_searchController` (cleaned up in `dispose()`) and `_searchQuery` state.
- Placed a `TextField` with a conditional clear (`suffixIcon`) button above `Expanded(child: FutureBuilder(...))`.
- Filtered `snapshot.data!` synchronously using `.where((c) => c.name.toLowerCase().contains(query))` before passing to `GridView.builder`.

### Chosen vs. Alternatives
- **Chosen:** In-memory `.where()` filtering on the cached `_charactersFuture` list (0ms latency, works offline once loaded).
- **Alternative:** Remote API search (`?name=...`) per keystroke (adds network lag and redundant requests).

### Learned
- `TextEditingController` must be disposed in `dispose()` to prevent memory leaks.
- `GridView` inside a `Column` requires `Expanded` to receive bounded height constraints.
- Caching `_charactersFuture` in `initState()` allows `setState()` to re-filter data without re-fetching from the API.

```

---

### 7. Practice Questions

1. Why does `_searchController.clear()` alone **not** refresh the grid unless you also call `setState(() => _searchQuery = '')`?
2. What layout error occurs if you place `FutureBuilder` (returning `GridView.builder`) directly inside `Column` without `Expanded`?

Add this to `HomeScreen`, test searching `"goku"` and clearing with `X`, and tell me when you're ready for **Step 12 — Favorites & Local Persistence**!






Sure—let's revisit **Step 12 — Favorites & Local Persistence** in complete, crystal-clear detail (without Riverpod yet, so you see the pure `setState` + `SharedPreferences` version first and understand *why* it feels clunky before Step 13 replaces it).

---

# Step 12 — Favorites & Local Persistence (`Set<int>` + `SharedPreferences`)

### 1. Objective

Let users tap a heart icon on any `CharacterCard` to favorite/unfavorite a character, and save those favorite IDs on the device using `SharedPreferences` so they remain saved after closing and reopening the app.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **In-memory collection** | `Set<int>` | `List<int>` | `Set.contains(id)` is **O(1)** (instant lookup) instead of O(n), and a `Set` mathematically prevents duplicate IDs. |
| **Local storage** | `shared_preferences` (`getStringList` / `setStringList`) | SQLite (`sqflite`) or Hive | Storing a small set of integer IDs is simple key-value data—setting up SQL tables and migrations would be overkill. |
| **When to read from disk** | `await SharedPreferences.getInstance()` inside `main()` **before** `runApp()` | Calling `SharedPreferences.getInstance()` inside `HomeScreen.initState()` | Reading inside `initState()` causes hearts to render empty on frame 1 and then flicker red a split-second later. Pre-loading in `main()` makes favorites ready on frame 1. |

---

### 3. Install Package

```bash
flutter pub add shared_preferences

```

---

### 4. Exact Delta Across Your 3 Files

#### File 1: `lib/main.dart` (Load `prefs` before `runApp()`)

```dart
import 'package:dragonball_learning/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Required whenever calling async platform plugins before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  runApp(DragonBallApp(prefs: prefs));
}

class DragonBallApp extends StatelessWidget {
  final SharedPreferences prefs;

  const DragonBallApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Dragon Ball Universe",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(prefs: prefs),
    );
  }
}

```

#### File 2: `lib/screens/home_screen.dart` (Restore, toggle, and save `Set<int>`)

1. Accept `final SharedPreferences prefs;` on `HomeScreen`.
2. Inside `_HomeScreenState`, add `_favoriteIds`, restore in `initState()`, and add `_toggleFavorite`:

```dart
static const _favoritesKey = 'favorite_ids';
late Set<int> _favoriteIds;

@override
void initState() {
  super.initState();
  _charactersFuture = _api.fetchCharacters();

  // Restore List<String> from disk -> Set<int> in memory
  final saved = widget.prefs.getStringList(_favoritesKey) ?? [];
  _favoriteIds = {
    for (final id in saved)
      if (int.tryParse(id) case final parsed?) parsed,
  };
}

void _toggleFavorite(int characterId) {
  // Create a new Set copy so state remains immutable
  final updated = {..._favoriteIds};
  if (!updated.add(characterId)) {
    updated.remove(characterId); // Was already in set -> remove it
  }

  setState(() {
    _favoriteIds = updated;
  });

  // Save Set<int> -> List<String> on disk
  widget.prefs.setStringList(
    _favoritesKey,
    [for (final id in updated) '$id'],
  );
}

```

3. Inside `GridView.builder`'s `itemBuilder`, pass the state and callback to `CharacterCard`:

```dart
return CharacterCard(
  character: character,
  isFavorite: _favoriteIds.contains(character.id),
  onToggleFavorite: () => _toggleFavorite(character.id),
);

```

#### File 3: `lib/widgets/character_card.dart` (Overlay heart icon with `Stack`)

1. Add two new `final` fields to `CharacterCard`:

```dart
final bool isFavorite;
final VoidCallback onToggleFavorite;

```

2. Replace the `Expanded(child: Image.network(...))` block with a `Stack` so the heart button floats in the top-right corner over the image:

```dart
Expanded(
  child: Stack(
    children: [
      Positioned.fill(
        child: Image.network(
          character.image,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, size: 48));
          },
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.redAccent : null,
          ),
          onPressed: onToggleFavorite,
        ),
      ),
    ],
  ),
),

```

---

### 5. Why Each Detail Matters

* **Why `WidgetsFlutterBinding.ensureInitialized()`?** `SharedPreferences` communicates with native Android/iOS code over a platform channel. Calling it before `runApp()` without initializing the binding throws a runtime binding error.
* **Why `if (!updated.add(characterId)) updated.remove(characterId);`?** `Set.add(value)` returns `true` if the item was added, and `false` if it was already in the set—making toggle logic a clean 2-line operation.
* **Why `int.tryParse` instead of `int.parse`?** If stored data ever gets corrupted, `int.tryParse` safely skips bad entries instead of crashing the app at startup.
* **The Architectural Friction Notice:** Look at how `prefs` had to pass through `main()` → `DragonBallApp` → `HomeScreen`, and `isFavorite` + `onToggleFavorite` had to pass down into `CharacterCard`. If we also want a heart icon on `CharacterDetailsScreen`, we'd have to pass them there too. **Remember this exact pain—Step 13 solves it with Riverpod.**

---

### 6. Data Flow

```text
App Launch ─▶ WidgetsFlutterBinding.ensureInitialized() ─▶ SharedPreferences.getInstance()
                                                                    │
Tap Heart ─▶ _toggleFavorite(id) ──┬──▶ setState(() => _favoriteIds = updated) ─▶ Card rebuilds
                                   └──▶ prefs.setStringList('favorite_ids', ...) ─▶ Saved to disk

```

---

### 7. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 12 — Favorites & Local Persistence

### Delta
- **`lib/main.dart`:** Initialized `WidgetsFlutterBinding` and awaited `SharedPreferences.getInstance()` before `runApp()`.
- **`lib/screens/home_screen.dart`:** Restored `Set<int> _favoriteIds` in `initState()` and added `_toggleFavorite(id)` to update state and write `List<String>` back to disk.
- **`lib/widgets/character_card.dart`:** Layered a heart `IconButton` in the top-right corner of the image using `Stack` + `Positioned`.

### Chosen vs. Alternatives
- **Chosen:** `Set<int>` + `SharedPreferences` loaded before `runApp()` (O(1) lookups, zero startup icon flicker).
- **Alternatives:** `List<int>` (O(n) lookups, allows duplicates) or async loading in `initState()` (causes hearts to flicker on launch).

### Learned
- `WidgetsFlutterBinding.ensureInitialized()` is required before calling async platform plugins prior to `runApp()`.
- `Set.add()` returns `false` if an element already exists, making toggle logic concise.
- Passing `prefs` and callbacks through multiple widget constructors ("prop-drilling") becomes hard to scale across multiple screens.

```

---

Let me know if any part of Step 12 needs clarification, or say **next** whenever you're ready to move on!











# Step 13 — Introduce Riverpod (Dependency Injection & State)

### 1. Objective

Eliminate passing `prefs`, `isFavorite`, and `onToggleFavorite` down multiple widget layers by introducing `flutter_riverpod`—injecting `SharedPreferences` at the root via `ProviderScope` overrides and migrating `Favorites` into a dedicated `Notifier`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **State management** | `flutter_riverpod` (`Notifier` + `NotifierProvider`) | Prop-drilling via constructors or `InheritedWidget` by hand | Allows any widget (`CharacterCard`, `CharacterDetailsScreen`, `FavoritesTab`) to read/toggle favorites directly with zero constructor boilerplate. |
| **Provider style** | `Notifier<Set<int>>` + `NotifierProvider` | Legacy `StateProvider` or `ChangeNotifierProvider` | `Notifier` keeps state immutable (`state = updated`) and encapsulates persistence logic cleanly inside methods. |
| **Granular rebuilds** | `ref.watch(favoritesProvider.select((ids) => ids.contains(id)))` | `ref.watch(favoritesProvider).contains(id)` | Watching the whole `Set<int>` rebuilds **every visible card** when 1 heart changes; `.select(...)` rebuilds **only the 1 card** whose boolean changed. |

---

### 3. Install Dependency

```bash
flutter pub add flutter_riverpod

```

---

### 4. Delta Changes

#### A. Inject `SharedPreferences` in `lib/main.dart`

Create a provider placeholder (in `lib/settings.dart` or `lib/providers.dart`) and override it in `ProviderScope` with the `prefs` instance loaded before `runApp()`:

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Set this in main().'),
);

```

In `lib/main.dart`, wrap the root widget in `ProviderScope` and remove `prefs` from `DragonBallApp`:

```dart
runApp(
  ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const DragonBallApp(),
  ),
);

```

#### B. Move `Favorites` logic into `lib/providers.dart`

```dart
class Favorites extends Notifier<Set<int>> {
  static const _storageKey = 'favorite_ids';

  @override
  Set<int> build() {
    final saved =
        ref.read(sharedPreferencesProvider).getStringList(_storageKey) ?? [];

    return {
      for (final text in saved)
        if (int.tryParse(text) case final id?) id,
    };
  }

  void toggle(int id) {
    final updated = {...state};
    if (!updated.add(id)) updated.remove(id);
    state = updated;

    ref.read(sharedPreferencesProvider).setStringList(
      _storageKey,
      [for (final saved in updated) '$saved'],
    );
  }
}

final favoritesProvider = NotifierProvider<Favorites, Set<int>>(Favorites.new);

```

#### C. Extract self-contained `FavoriteButton` (`ConsumerWidget`)

Now `CharacterCard` no longer needs `isFavorite` or `onToggleFavorite` parameters—and you can drop the exact same `FavoriteButton(character.id)` into `CharacterDetailsScreen`'s `AppBar` actions too:

```dart
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton(this.characterId, {super.key});

  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((ids) => ids.contains(characterId)),
    );

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.redAccent : null,
      ),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(characterId),
    );
  }
}

```

---

### 5. Engineering Insights (Why Each Piece Exists)

* **Why `throw UnimplementedError('Set this in main().')`?** Because `SharedPreferences.getInstance()` is `async`, while `Provider` creation is synchronous. Throwing `UnimplementedError` turns a missing `ProviderScope` override into an immediate, unmistakable crash instead of silently using uninitialized state.
* **`ref.watch` vs. `ref.read` rule:**
* Use `ref.watch(...)` **inside `build()**` so Flutter subscribes the widget to state updates.
* Use `ref.read(...)` **inside callbacks (`onPressed`)** to trigger an action once without subscribing to rebuilds.


* **Why `CharacterCard` stays a `StatelessWidget`:** Even though `FavoriteButton` inside it is a `ConsumerWidget`, `CharacterCard` itself doesn't call `ref.watch`—so tapping the heart doesn't rebuild the card's image or text layout.

---

### 6. Data Flow

```text
main() ─▶ ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)])
                                              │
                                              ▼
                                      Favorites (Notifier)
                                       ├── build() reads initial Set<int>
                                       └── toggle(id) updates state + writes disk
                                              │
                 ┌────────────────────────────┴────────────────────────────┐
                 ▼ (.select(contains(id)))                                 ▼ (.select(contains(id)))
     FavoriteButton on CharacterCard                           FavoriteButton on Details AppBar

```

---

### 7. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 13 — Introduce Riverpod (Dependency Injection & State)

### Delta
- **Added `flutter_riverpod`** and wrapped the root app in `ProviderScope` (`lib/main.dart`).
- **Dependency Injection:** Defined `sharedPreferencesProvider` (throwing `UnimplementedError` by default) and injected the pre-loaded `prefs` instance via `overrides`.
- **State Migration (`lib/providers.dart`):** Moved `Set<int>` favorites and `SharedPreferences` persistence into `Favorites extends Notifier<Set<int>>`.
- **UI Cleanup:** Created `FavoriteButton extends ConsumerWidget` using `favoritesProvider.select(...)` and removed favorite prop-drilling from `HomeScreen` and `CharacterCard`.

### Chosen vs. Alternatives
- **Chosen:** Riverpod `Notifier` + `ProviderScope` override + `.select()` subscription. Rebuilds only the single `FavoriteButton` whose boolean changed.
- **Alternatives:** Constructor prop-drilling across screens or legacy `ChangeNotifierProvider` (mutable state, rebuilds wider widget subtrees).

### Learned
- `ref.watch` subscribes to state inside `build()`; `ref.read` performs one-off actions inside callbacks like `onPressed`.
- `ProviderScope` overrides solve bridging `async` startup initialization (`SharedPreferences`) into synchronous providers.
- `.select()` narrows rebuild scope to a derived boolean instead of the entire collection.

```

---

### 8. Practice Questions

1. What happens if you accidentally call `ref.watch(favoritesProvider.notifier).toggle(id)` inside `onPressed` instead of `ref.read`?
2. Why does adding `FavoriteButton(character.id)` to `CharacterDetailsScreen`'s `AppBar` automatically stay in sync with `HomeScreen` when you navigate back?

Wire up `ProviderScope`, `Favorites`, and `FavoriteButton`, and verify that toggling a heart inside `CharacterDetailsScreen` updates the card on `HomeScreen` when you hit back! Reply **next** when you're ready for **Step 14 — Migrate API & Search into Riverpod**.









# Step 14 — Migrate API & Search into Riverpod (`FutureProvider`, Derived `Provider`s & `AsyncList<T>`)

### 1. Objective

Move API fetching and search state out of `HomeScreen`'s local `StatefulWidget` into Riverpod—so data is fetched once, cached across tabs, filtered reactively via derived synchronous providers, and rendered cleanly using a reusable `AsyncList<T>` widget.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Async API caching** | `FutureProvider<List<Character>>` (`charactersProvider`) | `FutureBuilder` inside `HomeScreen` | `FutureBuilder` dies when a screen unmounts; `FutureProvider` caches the resolved list in memory so multiple screens/tabs share it without re-fetching. |
| **Search filtering** | Derived synchronous `Provider<AsyncValue<List<Character>>>` (`visibleCharactersProvider`) | Filtering inside `build()` with `setState` | Automatically recomputes whenever **either** `charactersProvider` or `searchTextProvider` updates, and exposes a single `AsyncValue` to the UI. |
| **Refresh mechanism** | `ref.invalidate(charactersProvider)` + `await ref.read(charactersProvider.future)` | Reassigning `_charactersFuture = _api.fetchCharacters()` | `ref.invalidate` marks the provider dirty, re-runs the fetch, and keeps `RefreshIndicator` spinning until the new future settles. |
| **Loading / Error / Empty UI** | Generic `AsyncList<T>` widget wrapping `AsyncValue.when(...)` | Repeating `loading` / `error` / `empty` branches on every tab | Eliminates boilerplate across Characters, Planets, Favorites, and Explore tabs. |

---

### 3. Delta Changes

#### A. Add API, Search & Derived Providers in `lib/providers.dart`

```dart
// 1. Single shared HTTP client + API service
final apiProvider = Provider<DragonBallApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return DragonBallApi(client);
});

// 2. Cached async character list (fetched once per launch)
final charactersProvider = FutureProvider<List<Character>>(
  (ref) => ref.watch(apiProvider).fetchCharacters(),
);

// 3. Pull-to-refresh & Retry helper
Future<void> reloadCharacters(WidgetRef ref) async {
  ref.invalidate(charactersProvider);
  try {
    await ref.read(charactersProvider.future);
  } catch (_) {
    // AsyncValue.when() displays the error UI itself
  }
}

// 4. Shared search query state
class SearchText extends Notifier<String> {
  @override
  String build() => '';
  void change(String value) => state = value;
}

final searchTextProvider = NotifierProvider<SearchText, String>(SearchText.new);

// 5. Derived filtered list (recomputes automatically when API data or search changes)
final visibleCharactersProvider = Provider<AsyncValue<List<Character>>>((ref) {
  final search = ref.watch(searchTextProvider).trim().toLowerCase();

  return ref.watch(charactersProvider).whenData((all) => [
        for (final character in all)
          if (character.name.toLowerCase().contains(search)) character,
      ]);
});

```

*(Update `DragonBallApi` in `lib/services/dragon_ball_api.dart` to accept `DragonBallApi(this._client)` so `apiProvider` manages the `http.Client` lifecycle.)*

#### B. Create Generic `AsyncList<T>` in `lib/widgets.dart`

```dart
class AsyncList<T> extends StatelessWidget {
  const AsyncList({
    super.key,
    required this.value,
    required this.onRefresh,
    required this.emptyText,
    required this.builder,
  });

  final AsyncValue<List<T>> value;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final Widget Function(List<T> items) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      ),
      data: (items) => items.isEmpty
          ? Center(child: Text(emptyText, textAlign: TextAlign.center))
          : RefreshIndicator(onRefresh: onRefresh, child: builder(items)),
    );
  }
}

```

#### C. Simplify `lib/screens/home_screen.dart`

* `HomeScreen` no longer needs `_api`, `_charactersFuture`, or `_searchQuery` state!
* `TextField.onChanged` calls `ref.read(searchTextProvider.notifier).change(text)`.
* The body renders `AsyncList` watching `visibleCharactersProvider`:

```dart
Expanded(
  child: AsyncList(
    value: ref.watch(visibleCharactersProvider),
    onRefresh: () => reloadCharacters(ref),
    emptyText: 'No characters found.',
    builder: (items) => GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even on short lists
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.70,
      ),
      itemBuilder: (_, index) => CharacterCard(character: items[index]),
    ),
  ),
)

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `.whenData(...)` inside `visibleCharactersProvider`?** `charactersProvider` has type `AsyncValue<List<Character>>` (it could be loading, error, or data). `.whenData((all) => ...)` lets you transform the inner `List<Character>` **only** when data is available, while automatically passing `AsyncLoading` and `AsyncError` states straight through untouched.
* **Why `physics: const AlwaysScrollableScrollPhysics()`?** When a user searches `"Goku"` and only 1 card matches, the grid isn't tall enough to scroll—which normally disables `RefreshIndicator` pull-to-refresh. `AlwaysScrollableScrollPhysics()` keeps pull-to-refresh active even on 1-item lists.
* **Why `ref.onDispose(client.close)`?** Creating one `http.Client` in `apiProvider` reuses TCP/TLS connections across requests (faster than `http.get()` creating a new socket per call) and closes sockets cleanly if the provider container is disposed.

---

### 5. Data Flow

```text
apiProvider (http.Client) ──▶ charactersProvider (FutureProvider - cached)
                                        │
searchTextProvider (Notifier<String>) ──┼──▶ visibleCharactersProvider (.whenData filter)
                                                        │
                                                        ▼
                                            AsyncList<Character>
                                             ├── loading ─▶ Spinner
                                             ├── error   ─▶ Retry (ref.invalidate)
                                             └── data    ─▶ RefreshIndicator + GridView

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 14 — Migrate API & Search into Riverpod

### Delta
- **`lib/providers.dart`:** Added `apiProvider` (with `ref.onDispose(client.close)`), `charactersProvider` (`FutureProvider`), `searchTextProvider` (`Notifier<String>`), `visibleCharactersProvider` (derived `Provider` using `.whenData`), and `reloadCharacters` (`ref.invalidate`).
- **`lib/widgets.dart`:** Created reusable `AsyncList<T>` wrapping `AsyncValue.when(...)` and `RefreshIndicator`.
- **`lib/screens/home_screen.dart`:** Replaced manual `FutureBuilder` and `_searchQuery` state with `AsyncList(value: ref.watch(visibleCharactersProvider))`.

### Chosen vs. Alternatives
- **Chosen:** `FutureProvider` + derived `Provider`s + `AsyncList<T>` (fetches once, caches across screens, eliminates duplicated loading/error/empty UI).
- **Alternative:** Keeping `FutureBuilder` per screen (re-fetches data on navigation and duplicates snapshot branching).

### Learned
- `AsyncValue.whenData()` transforms resolved data while forwarding `loading` and `error` states automatically.
- `ref.invalidate()` resets a `FutureProvider` to re-run its fetch; awaiting `provider.future` keeps `RefreshIndicator` active until completion.
- `AlwaysScrollableScrollPhysics()` ensures pull-to-refresh works even when filtered results fit on a single screen.

```

---

### 7. Practice Questions

1. Why does `reloadCharacters` wrap `await ref.read(charactersProvider.future)` inside a `try / catch (_)` block?
2. What happens if `charactersProvider` is currently in an `AsyncError` state when `visibleCharactersProvider` runs `.whenData(...)`?












# Step 15 — Planets, Bottom Navigation & Splash Screen Pre-Fetch

### 1. Objective

Expand the single-screen app into a 4-tab experience (**Characters**, **Planets**, **Explore**, **Favorites**) using Material 3 `NavigationBar` + `IndexedStack` so scroll positions and search queries survive tab switches, and add a `SplashScreen` that warms both `charactersProvider` and `planetsProvider` in parallel on launch.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Tab body switching** | `IndexedStack(index: _index, children: [...])` | `body: tabs[_index]` or `TabBarView` | `tabs[_index]` destroys unmounted tabs (losing scroll position on every switch); `TabBarView` captures horizontal swipes that conflict with horizontal chip lists in Step 16. `IndexedStack` keeps all 4 tabs mounted and preserves scroll state. |
| **Shared search box visibility** | `Visibility(visible: _index != _exploreIndex, maintainState: true)` | Conditionally omitting `_SearchBox()` with `if (_index != 2)` | `maintainState: true` preserves the `TextField`'s internal `TextEditingController` text when visiting Explore and coming back. |
| **Startup pre-loading** | `SplashScreen` awaiting `Future.wait([charactersProvider.future, planetsProvider.future, delayed(900ms)]).timeout(8s)` | Jumping straight to `HomeScreen` | Pre-warms both API endpoints concurrently during the brand transition; if offline or slow (>8s), it still navigates to `HomeScreen`, where `AsyncList` already has its own `Retry` button. |
| **Planet details UX** | `showModalBottomSheet` inside `PlanetCard` | Full-screen `Navigator.push` route | Planets only have 4 fields (image, name, `isDestroyed`, description)—a modal bottom sheet avoids an unnecessary full-page navigation stack push. |

---

### 3. Delta Changes

#### A. Add `Planet` Model (`lib/models.dart`) & Endpoint (`lib/api.dart`)

```dart
class Planet {
  const Planet({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
    this.isDestroyed = false,
  });

  final int id;
  final String name;
  final String image;
  final String description;
  final bool isDestroyed;

  factory Planet.fromJson(Map<String, dynamic> json) => Planet(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: _text(json['name']),
        image: _text(json['image']),
        description: _text(json['description']),
        isDestroyed: json['isDestroyed'] == true,
      );
}

```

In `DragonBallApi`, add `fetchPlanets()` calling `/planets` using the exact same JSON `items` parsing pattern as characters.

#### B. Add Planet & Favorite Derived Providers (`lib/providers.dart`)

```dart
final planetsProvider = FutureProvider<List<Planet>>(
  (ref) => ref.watch(apiProvider).fetchPlanets(),
);

final visiblePlanetsProvider = Provider<AsyncValue<List<Planet>>>((ref) {
  final search = ref.watch(searchTextProvider).trim().toLowerCase();
  return ref.watch(planetsProvider).whenData((all) => [
        for (final planet in all)
          if (planet.name.toLowerCase().contains(search)) planet,
      ]);
});

// Chains off visibleCharactersProvider so Favorites also respects the top search bar!
final favoriteCharactersProvider = Provider<AsyncValue<List<Character>>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  return ref.watch(visibleCharactersProvider).whenData((characters) => [
        for (final character in characters)
          if (favoriteIds.contains(character.id)) character,
      ]);
});

```

#### C. Create `PlanetCard` (`lib/widgets.dart`)

Tapping a `PlanetCard` opens a `SafeArea` + `SingleChildScrollView` modal bottom sheet:

```dart
void _showDetails(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 200, width: double.infinity, child: Image.network(planet.image, fit: BoxFit.contain)),
            const SizedBox(height: 12),
            Text(planet.name, style: Theme.of(context).textTheme.titleLarge),
            Text(planet.isDestroyed ? 'Destroyed' : 'Still exists'),
            const SizedBox(height: 8),
            Text(planet.description),
          ],
        ),
      ),
    ),
  );
}

```

#### D. Upgrade `HomeScreen` to 4 Tabs (`lib/home_screen.dart`)

```dart
body: Column(
  children: [
    Visibility(
      visible: _index != _exploreIndex, // Explore has its own search box in Step 16
      maintainState: true,
      child: const _SearchBox(),
    ),
    Expanded(
      child: IndexedStack(
        index: _index,
        children: const [
          _CharactersTab(),   // watches visibleCharactersProvider
          _PlanetsTab(),      // watches visiblePlanetsProvider
          Placeholder(),      // Replaced by ExploreScreen in Step 16
          _FavoritesTab(),    // watches favoriteCharactersProvider
        ],
      ),
    ),
  ],
),
bottomNavigationBar: NavigationBar(
  selectedIndex: _index,
  onDestinationSelected: (index) => setState(() => _index = index),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.people_outline), label: 'Characters'),
    NavigationDestination(icon: Icon(Icons.public), label: 'Planets'),
    NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
    NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorites'),
  ],
),

```

#### E. Create `SplashScreen` (`lib/splash_screen.dart`) & Point `main.dart` `home:` to It

```dart
Future<void> _loadThenGoHome() async {
  try {
    await Future.wait<Object?>([
      ref.read(charactersProvider.future),
      ref.read(planetsProvider.future),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]).timeout(const Duration(seconds: 8));
  } catch (_) {
    // Offline or slow: HomeScreen's AsyncList handles errors & Retry.
  }

  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `favoriteCharactersProvider` watches `visibleCharactersProvider` instead of `charactersProvider`:** Chaining derived providers forms a clean Directed Acyclic Graph (DAG). Because `visibleCharactersProvider` already applies `searchTextProvider`, the Favorites tab gets live search filtering automatically without duplicating `.contains(search)` logic.
* **Why `if (!mounted) return;` after `await`:** If the user closes or backgrounds the app during the 8-second timeout, `context` is no longer mounted in the widget tree. Guarding with `mounted` prevents `Looking up a deactivated widget's ancestor is unsafe` crashes.
* **Why `pushReplacement` instead of `push`:** Replaces `SplashScreen` at the bottom of the navigation stack so pressing Android's system Back button on `HomeScreen` exits the app instead of returning to the splash spinner.

---

### 5. Architecture & Data Flow

```text
SplashScreen ─▶ Future.wait([charactersProvider, planetsProvider, 900ms]).timeout(8s)
                     │
                     ▼ (pushReplacement + FadeTransition)
                HomeScreen
                 ├── Visibility(maintainState: true) ─▶ _SearchBox ─▶ searchTextProvider
                 └── IndexedStack
                      ├── [0] _CharactersTab ─▶ visibleCharactersProvider
                      ├── [1] _PlanetsTab    ─▶ visiblePlanetsProvider ─▶ PlanetCard (BottomSheet)
                      ├── [2] ExploreScreen  ─▶ (Step 16)
                      └── [3] _FavoritesTab  ─▶ favoriteCharactersProvider

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 15 — Planets, Bottom Navigation & Splash Pre-Fetch

### Delta
- **`lib/models.dart` & `lib/api.dart`:** Added `Planet` model (`isDestroyed == true` safe boolean parsing) and `fetchPlanets()`.
- **`lib/providers.dart`:** Added `planetsProvider`, `visiblePlanetsProvider`, and `favoriteCharactersProvider` (derived from `visibleCharactersProvider` + `favoritesProvider`).
- **`lib/widgets.dart`:** Added `PlanetCard` opening a `showModalBottomSheet` detail view.
- **`lib/home_screen.dart`:** Replaced single body with `NavigationBar` + `IndexedStack` (4 tabs) and `Visibility(maintainState: true)` for the shared search bar.
- **`lib/splash_screen.dart`:** Added parallel pre-fetching via `Future.wait(...).timeout(8s)` and `Navigator.pushReplacement` fade transition.

### Chosen vs. Alternatives
- **Chosen:** `IndexedStack` + `Visibility(maintainState: true)` + `SplashScreen` parallel `Future.wait`. Preserves scroll offset and search text across tab switches while pre-warming data concurrently.
- **Alternatives:** Conditional tab swapping (destroys scroll state per switch) or sequential `await` calls on startup (doubles initial load latency).

### Learned
- Chaining derived providers (`charactersProvider` ─▶ `visibleCharactersProvider` ─▶ `favoriteCharactersProvider`) avoids duplicating filter logic.
- Always check `if (!mounted) return;` before using `BuildContext` after an `await`.
- `pushReplacement` prevents users from navigating back to a splash screen.

```

---

### 7. Practice Questions

1. Why did `Planet.fromJson` check `json['isDestroyed'] == true` instead of `json['isDestroyed'] as bool`?
2. What is the performance trade-off of `IndexedStack` if an app has 15 heavy tabs instead of 4?















# Step 16 — Explore Screen & Ki Power Parser (`ki_parser.dart`, `explore_providers.dart`, `explore_screen.dart`)

### 1. Objective

Build the **Explore** tab where users can group characters by **Race** or **Affiliation** (with live counts like `Saiyan · 12`), search independently, toggle Grid vs. List layouts, and sort by **Strongest first**—powered by a defensive regex Ki parser (`parseKi`) that converts messy API strings (`"60.000.000"`, `"90 Septillion"`, `"∞"`) into comparable `double` values.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Parsing power levels** | Regex + scale-exponent lookup (`parseKi`) returning `double?` | `double.tryParse(character.ki)` | The API stores Ki as `"60.000.000"` (European thousand dots), `"90 Septillion"`, and `"∞"`. `double.tryParse` returns `null` on all three. |
| **Explore filter state** | Immutable `ExploreSelection` inside `ExploreSelectionNotifier` (`explore_providers.dart`) | Local `setState` variables inside `ExploreScreen` | Keeps grouping, sorting, and query logic in pure testable Dart providers (`exploreGroupsProvider`, `exploreVisibleProvider`) rather than inside `build()`. |
| **Grid vs. List toggle** | Local `bool _showGrid = true` inside `_ExploreScreenState` | A global Riverpod provider | Only `ExploreScreen` cares whether it renders as a grid or list—ephemeral single-widget UI state belongs in `setState`, not global providers. |
| **Resetting group on mode switch** | `setMode` passes `clearGroup: true` in `copyWith` | Leaving `group` untouched when switching from `Race` to `Affiliation` | `"Saiyan"` is a valid Race, not an Affiliation—leaving it selected when switching to Affiliation would produce 0 results. |

---

### 3. New Files & Delta Changes

#### A. Create `lib/ki_parser.dart` (Pure Functional Parsing)

```dart
import 'dart:math' as math;

const Map<String, int> _scaleWords = {
  'thousand': 3,
  'million': 6,
  'billion': 9,
  'trillion': 12,
  'quadrillion': 15,
  'quintillion': 18,
  'sextillion': 21,
  'septillion': 24,
  'octillion': 27,
  'nonillion': 30,
  'decillion': 33,
  'undecillion': 36,
  'duodecillion': 39,
};

const Set<String> _infiniteWords = {'infinite', 'infinity', 'unlimited', '∞'};

final RegExp _numberAndWord = RegExp(r'^([\d.,]+)\s*([a-z]+)?$');
final RegExp _plainInteger = RegExp(r'^\d+$');
final RegExp _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');
final RegExp _singleDecimal = RegExp(r'^\d+[.,]\d+$');

/// Returns null when the text cannot be understood safely.
double? parseKi(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return null;
  if (_infiniteWords.contains(text)) return double.infinity;

  final match = _numberAndWord.firstMatch(text);
  if (match == null) return null;

  final number = match.group(1)!;
  final word = match.group(2);

  if (word != null) {
    final exponent = _scaleWords[word];
    final base = double.tryParse(number.replaceAll(',', ''));
    if (exponent == null || base == null) return null;
    return base * math.pow(10, exponent).toDouble();
  }

  if (_plainInteger.hasMatch(number)) return double.tryParse(number);
  if (_grouped.hasMatch(number)) {
    return double.tryParse(number.replaceAll(RegExp(r'[.,]'), ''));
  }
  if (_singleDecimal.hasMatch(number)) {
    return double.tryParse(number.replaceAll(',', '.'));
  }
  return null; // Ambiguous strings like "12.34.5" return null rather than guessing
}

double powerOf(String ki, String maxKi) =>
    math.max(parseKi(ki) ?? 0, parseKi(maxKi) ?? 0);

```

#### B. Create `lib/explore_providers.dart` (Grouping, Filtering & Sorting)

1. **Enums & Selection Model:** `ExploreMode` (`all`, `race`, `affiliation`), `ExploreSort` (`nameAsc`, `nameDesc`, `strongestFirst`), and `ExploreSelection` with `copyWith(..., bool clearGroup = false)` (needed because standard `group ?? this.group` cannot reset a nullable field back to `null`).
2. **Dynamic Group Counts (`exploreGroupsProvider`):**

```dart
typedef GroupCount = ({String label, int count}); // Dart 3 record type

final exploreGroupsProvider = Provider<List<GroupCount>>((ref) {
  final mode = ref.watch(exploreSelectionProvider.select((s) => s.mode));
  if (mode == ExploreMode.all) return const [];

  final all = ref.watch(charactersProvider).asData?.value ?? const [];
  final counts = <String, int>{};

  for (final character in all) {
    final group = mode == ExploreMode.race ? character.race : character.affiliation;
    if (group.isNotEmpty) counts[group] = (counts[group] ?? 0) + 1;
  }

  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value)); // Most populated group first

  return [for (final entry in entries) (label: entry.key, count: entry.value)];
});

```

3. **Filtered & Sorted Output (`exploreVisibleProvider`):** Combines `selection.group`, `selection.query`, and `selection.sort` (using `powerOf(b.ki, b.maxKi).compareTo(powerOf(a.ki, a.maxKi))` for `strongestFirst`).

#### C. Create `lib/explore_screen.dart` & Wire into `HomeScreen`

* Replaces `Placeholder()` at index `2` of `IndexedStack` in `HomeScreen`.
* Renders:
1. Dedicated `TextField` (`_search` controller disposed in `dispose()`).
2. Mode `ChoiceChip`s (`All`, `Race`, `Affiliation`), `PopupMenuButton<ExploreSort>`, and Grid/List toggle `IconButton`.
3. Horizontal `ListView` of `_GroupChip`s (`All`, `Saiyan · 12`, `Android · 5`, ...) when `groups.isNotEmpty`.
4. `AsyncList` switching between `CardGrid` and `ListView.builder` (`ListTile` with thumbnail `leading`, `title`, `subtitle`, and `FavoriteButton` `trailing`).



---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `clearGroup: true` in `copyWith`?** In Dart, `String? group` inside `copyWith({String? group})` uses `group: group ?? this.group`. If you pass `copyWith(group: null)`, `null ?? this.group` keeps the old non-null value! Adding an explicit `bool clearGroup = false` flag solves nullable resets cleanly.
* **Why `double.infinity` works seamlessly in `List.sort`:** Dart's `double.infinity.compareTo(1e24)` returns `1` (greater than any finite number) and `double.infinity.compareTo(double.infinity)` returns `0`—so characters with `"∞"` Ki naturally sort to the very top without special-case `if` branches.
* **Why `ref.watch(exploreSelectionProvider.select((s) => s.mode))` in `exploreGroupsProvider`:** Typing in the Explore search box updates `selection.query`, not `selection.mode`. Using `.select((s) => s.mode)` prevents recalculating group counts on every search keystroke.

---

### 5. Data Flow

```text
charactersProvider ──┬──▶ exploreGroupsProvider (selects mode only) ──▶ Horizontal _GroupChips ("Saiyan · 12")
                     │
exploreSelection ────┴──▶ exploreVisibleProvider (filter group + query ─▶ sort via powerOf)
                                     │
                                     ▼
                          AsyncList<Character>
                           ├── _showGrid == true  ──▶ CardGrid(CharacterCard)
                           └── _showGrid == false ──▶ ListView.builder(ListTile + FavoriteButton)

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 16 — Explore Screen & Ki Power Parser

### Delta
- **`lib/ki_parser.dart`:** Built regex-based `parseKi()` and `powerOf()` to convert `"60.000.000"`, `"90 Septillion"`, and `"∞"` into comparable `double` values (`double.infinity` for infinite).
- **`lib/explore_providers.dart`:** Added `ExploreSelectionNotifier` (with `clearGroup` flag in `copyWith`), `exploreGroupsProvider` (returning Dart 3 records `({String label, int count})`), and `exploreVisibleProvider` (filter + sort).
- **`lib/explore_screen.dart` & `lib/home_screen.dart`:** Replaced the Explore tab placeholder with mode chips, horizontal group chips, sort menu, and a Grid/List toggle (`setState`).

### Chosen vs. Alternatives
- **Chosen:** Regex + scale-exponent `parseKi` + derived Riverpod providers + local `_showGrid` `setState`.
- **Alternatives:** `double.tryParse()` alone (fails on `"90 Septillion"` and `"60.000.000"`) or putting `_showGrid` in global Riverpod state (unnecessary for single-screen UI state).

### Learned
- Nullable fields in Dart `copyWith` require an explicit `clearX` boolean flag to reset back to `null`.
- Separating shared domain state (Riverpod) from ephemeral widget state (`_showGrid` in `setState`) keeps providers clean.

```

---

### 7. Practice Questions

1. Why does `parseKi("60.000.000")` match `_grouped` instead of `_singleDecimal`, and what would happen if `"60.000"` (1 thousand-group) was parsed by `_singleDecimal` vs `_grouped`?
2. Why did we keep `_showGrid` inside `_ExploreScreenState` instead of adding `showGrid` to `ExploreSelection`?







# Step 17 — Advanced Character Details & Full-Screen Image Viewer

### 1. Objective

Enrich `CharacterScreen` so that base stats appear immediately on tap while `originPlanet` and `transformations` stream in asynchronously from `/characters/$id` via `FutureProvider.family`—and let users tap the character or any transformation to inspect them in a swipeable, pinch-to-zoom `FullScreenImageViewer`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Fetching per-character extras** | Progressive rendering: show existing `Character` fields immediately (0ms), while `characterExtrasProvider(id)` loads `/characters/$id` below | Blocking navigation until `/characters/$id` finishes, or pre-fetching all 58 detail endpoints on startup | Blocking adds a spinner before every screen transition; pre-fetching all endpoints causes an N+1 request storm on launch. Progressive rendering gives instant UI + lazy caching per ID. |
| **Parameterized provider** | `FutureProvider.family<CharacterExtras, int>` | Manual `FutureBuilder` inside `CharacterScreen` | `.family` caches each character's extras in memory by `id`—opening Goku, going back, and reopening Goku skips the second network call. |
| **Full-screen zoom & swipe** | `PageView.builder` + `InteractiveViewer(minScale: 1, maxScale: 4)` | Single-image dialog or external gallery package | Built-in Flutter widgets support horizontal swiping between base form and transformations (`PageView`) plus native pinch-to-zoom (`InteractiveViewer`) with zero extra dependencies. |

---

### 3. New Files & Delta Changes

#### A. Add `Transformation` & `CharacterExtras` Models (`lib/models.dart`)

```dart
class Transformation {
  const Transformation({required this.name, required this.image, this.ki = ''});

  final String name;
  final String image;
  final String ki;

  factory Transformation.fromJson(Map<String, dynamic> json) => Transformation(
        name: _text(json['name']),
        image: _text(json['image']),
        ki: _text(json['ki']),
      );
}

class CharacterExtras {
  const CharacterExtras({this.originPlanet, this.transformations = const []});

  final Planet? originPlanet;
  final List<Transformation> transformations;

  factory CharacterExtras.fromJson(Map<String, dynamic> json) {
    final planet = json['originPlanet'];
    final forms = json['transformations'];

    return CharacterExtras(
      originPlanet:
          planet is Map<String, dynamic> ? Planet.fromJson(planet) : null,
      transformations: forms is List
          ? [
              for (final form in forms)
                if (form is Map<String, dynamic>) Transformation.fromJson(form),
            ]
          : const [],
    );
  }
}

```

*(In `DragonBallApi`, add `fetchCharacterExtras(int id)` calling `/characters/$id` and parsing `CharacterExtras.fromJson`.)*

#### B. Add Parameterized Provider (`lib/providers.dart`)

```dart
final characterExtrasProvider = FutureProvider.family<CharacterExtras, int>(
  (ref, id) => ref.watch(apiProvider).fetchCharacterExtras(id),
);

```

#### C. Create `lib/full_screen_image_viewer.dart`

```dart
class ViewerImage {
  const ViewerImage({required this.url, required this.title});
  final String url;
  final String title;
}

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0);

  final List<ViewerImage> images;
  final int initialIndex;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

```

Inside `_FullScreenImageViewerState`:

* Create `late final PageController _pages = PageController(initialPage: widget.initialIndex);` and dispose it in `dispose()`.
* Build a black `Scaffold` with a `Stack`:
1. `PageView.builder` rendering `InteractiveViewer(minScale: 1, maxScale: 4, child: SizedBox.expand(child: Image.network(images[page].url, fit: BoxFit.contain)))`.
2. Top-left `IconButton.filledTonal` close button (`Navigator.of(context).pop()`).
3. Bottom caption showing `'${images[_index].title}  (${_index + 1}/${images.length})'` when `images.length > 1`.



#### D. Upgrade `CharacterScreen` (`lib/character_screen.dart`)

1. Convert `CharacterDetailsScreen` to `ConsumerWidget` (`CharacterScreen`) with `FavoriteButton(character.id)` in `AppBar.actions`.
2. Watch `final extras = ref.watch(characterExtrasProvider(character.id));`.
3. Helper `_openViewer(context, forms, index)` builds `[ViewerImage(url: character.image, title: character.name), for (final form in forms) ViewerImage(url: form.image, title: form.name)]`—so index `0` is the base character, and transformation `i` opens at `i + 1`.
4. Render `extras.when(...)` below the description:
* `loading`: `CircularProgressIndicator`
* `error`: `SizedBox.shrink()` (gracefully hides extras if the secondary call fails, rather than hiding the base stats already visible!)
* `data`: `originPlanet!.name` (if non-null) + horizontal `ListView.separated` (`height: 170`) of `_TransformationTile`s.



---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `error: (_, __) => const SizedBox.shrink()` on `extras`?** The user is already looking at the character's image, Ki, race, and description. Replacing the whole screen with a full-screen error message just because `/characters/$id` failed would degrade UX—silently collapsing the optional extras section preserves the primary content.
* **Why `PageController` must be disposed:** Just like `TextEditingController`, `PageController` attaches scroll-position listeners to `PageView` and must call `_pages.dispose()` in `dispose()`.
* **Why `assert(images.length > 0)` in the constructor:** Catches programmer bugs immediately during development if someone opens the viewer with an empty list before `images[_index]` ever throws a `RangeError`.

---

### 5. Data Flow

```text
Tap CharacterCard ─▶ Navigator.push(CharacterScreen(character))
                          │
                          ├── Instant UI (0ms): image, chips (race/gender/affiliation), Ki, description
                          │
                          └── Async: ref.watch(characterExtrasProvider(character.id))
                                      ├── loading ─▶ Spinner below description
                                      ├── error   ─▶ SizedBox.shrink()
                                      └── data    ─▶ Origin Planet + Horizontal Transformations List
                                                           │
                                                           ▼ (Tap base image [0] or form [index + 1])
                                                FullScreenImageViewer (PageView + InteractiveViewer)

```

---

### 6. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 17 — Advanced Character Details & Full-Screen Image Viewer

### Delta
- **`lib/models.dart` & `lib/api.dart`:** Added `Transformation`, `CharacterExtras` (safe `is Map` / `is List` guards), and `fetchCharacterExtras(id)`.
- **`lib/providers.dart`:** Added `characterExtrasProvider = FutureProvider.family<CharacterExtras, int>(...)` to fetch and cache per-character details by ID.
- **`lib/full_screen_image_viewer.dart`:** Built swipeable `PageView.builder` + pinch-to-zoom `InteractiveViewer` gallery (`PageController` disposed in `dispose()`).
- **`lib/character_screen.dart`:** Upgraded details screen to `ConsumerWidget` with `FavoriteButton` in `AppBar`, progressive `extras.when(...)` rendering, and unified viewer indexing (`0` = base character, `index + 1` = transformation).

### Chosen vs. Alternatives
- **Chosen:** Progressive rendering via `FutureProvider.family` + built-in `PageView` & `InteractiveViewer`. Instant screen transitions, per-ID caching, and zero external gallery dependencies.
- **Alternatives:** Pre-fetching all character details at startup (N+1 API storm) or blocking navigation until `/characters/$id` resolves (adds spinner delay to every tap).

### Learned
- `FutureProvider.family` parameterizes and caches async requests by argument (`id`).
- Graceful degradation (`error: (_, __) => const SizedBox.shrink()`) keeps primary content usable when secondary endpoints fail.

```

---

### 7. Practice Questions

1. Why is `index + 1` passed to `_openViewer(context, details.transformations, index + 1)` when tapping a transformation tile?
2. What happens if a character in the API has `originPlanet: null` and `transformations: []`? How does `CharacterExtras.fromJson` handle both safely?










# Step 18 — Production API Resilience & Disk Image Caching

### 1. Objective

Upgrade `DragonBallApi` from a basic single-page GET into a resilient production network layer—with **concurrent pagination** (`Future.wait`), **15s timeouts**, **1x automatic retries** on transient failures, **typed `ApiException` errors**, and **stopwatch debug logging**—while replacing `Image.network` with `CachedNetworkImage` + `memCacheWidth` decode sizing so images cache to disk and never blow up mobile RAM.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Fetching all pages** | Fetch Page 1 (`limit=10`), read `meta.totalPages`, then `Future.wait` pages `2..N` concurrently | Sequential `while (nextPage)` loop or `limit=100` hack | Sequential loops create a slow N-step waterfall; `Future.wait` cuts total latency down to **2 round-trips** regardless of page count. |
| **Transient error recovery** | Retry loop (`attempt <= 2` with `600ms` backoff) **only** for network drops, timeouts, and `statusCode >= 500` | Retrying all errors (including `404` or `badData`) or never retrying | Retrying `404` or malformed JSON wastes time; retrying a `502`/`503` or brief cellular drop recovers silently. |
| **Image caching & memory** | `CachedNetworkImage` + custom `CacheManager` (14-day TTL, 300 objects) + `memCacheWidth` | Raw `Image.network` | Raw `Image.network` re-downloads images on every app restart and decodes full 2000px PNGs into 150px grid cells (burning ~16MB RAM per card!). `memCacheWidth` downscales during decode. |
| **Image download logging** | Subclass `http.BaseClient` (`_LoggingClient`) passed to `HttpFileService` | Guessing whether images hit disk cache or network | Intercepting `send()` logs `→ IMG` only on cache misses—proving your disk cache works when nothing prints on the second launch. |

---

### 3. Install Dependencies

```bash
flutter pub add cached_network_image flutter_cache_manager

```

---

### 4. Delta Changes

#### A. Upgrade `lib/api.dart` (Typed Errors, Timeout, Retry & Concurrent Pagination)

1. **Typed Error Classification (`ApiException`):**

```dart
enum ApiErrorKind { noConnection, timeout, server, badData }

class ApiException implements Exception {
  const ApiException(this.kind, this.message, [this.statusCode]);
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String friendlyError(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Try again.';

```

2. **Timeout + 1x Retry Loop (`_getJson` & `_getJsonOnce`):**

* `_getJsonOnce` attaches `.timeout(const Duration(seconds: 15))`, catches `TimeoutException` and `http.ClientException`, maps HTTP status codes (`404`, `429`, `>= 500`), and logs `→ GET` / `← 200 • 142ms • 4.2 KB` inside `if (kDebugMode)`.
* `_getJson` wraps `_getJsonOnce`:

```dart
for (var attempt = 1;; attempt++) {
  try {
    return await _getJsonOnce(path, query);
  } on ApiException catch (error) {
    final isTemporary = error.kind != ApiErrorKind.badData &&
        (error.statusCode == null || error.statusCode! >= 500);

    if (attempt >= 2 || !isTemporary) rethrow;
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }
}

```

3. **Concurrent Pagination (`_fetchAllPages`):**

```dart
Future<List<T>> _fetchAllPages<T>(
  String path,
  T Function(Map<String, dynamic>) fromJson,
) async {
  Future> readPage(int page) async {
    final json = await _getJson(path, {'page': '$page', 'limit': '10'});
    return _parse(() => json as Map<String, dynamic>);
  }

  final first = await readPage(1);
  final totalPages = _parse(
    () => ((first['meta']?['totalPages'] as num?)?.toInt() ?? 1).clamp(1, 50),
  );

  final others = await Future.wait([
    for (var page = 2; page <= totalPages; page++) readPage(page),
  ]);

  return _parse(() => [
        for (final page in [first, ...others])
          for (final item in page['items'] as List)
            fromJson(item as Map<String, dynamic>),
      ]);
}

```

*(Update `charactersProvider` and `planetsProvider` to call `fetchAllCharacters()` and `fetchAllPlanets()`—unlocking all ~58 characters instead of just page 1's 10!)*

#### B. Create `lib/image_cache.dart` (Disk Cache + HTTP Interceptor)

```dart
class _LoggingClient extends http.BaseClient {
  _LoggingClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Logs → IMG / ← IMG status & latency via apiLog(), then delegates to _inner.send(request)
  }

  @override
  void close() => _inner.close();
}

final CacheManager imageCacheManager = CacheManager(
  Config(
    'dragonball_images',
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 300,
    fileService: HttpFileService(httpClient: _LoggingClient(http.Client())),
  ),
);

```

#### C. Create `NetworkPicture` (`lib/widgets.dart`) & Replace `Image.network`

```dart
class NetworkPicture extends StatelessWidget {
  const NetworkPicture(this.url, {super.key, this.decodeWidth = 300});

  final String url;
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const Icon(Icons.image_not_supported_outlined);

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: imageCacheManager,
      memCacheWidth: decodeWidth, // Decode at thumbnail size (300px), 800px on details, 1600px in full-screen viewer
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }
}

```

---

### 5. Engineering Insights (Why Each Piece Exists)

* **Why `.clamp(1, 50)` on `totalPages`?** Never blindly trust an external API's pagination metadata—if a buggy server returns `totalPages: 999999`, `.clamp(1, 50)` prevents your app from launching a million concurrent HTTP requests.
* **Why `memCacheWidth` is a massive memory win:** An uncompressed RGBA bitmap of a `1500 × 2000` PNG takes `1500 × 2000 × 4 bytes = 12 MB` in Flutter's image cache. Setting `memCacheWidth: 300` decodes it at `300 × 400 × 4 bytes = 480 KB`—a **25x RAM reduction** per card while passing `decodeWidth: 800` on `CharacterScreen` and `1600` in `FullScreenImageViewer`.
* **Why `if (!kDebugMode) return;` inside `apiLog`:** Ensures debug string formatting and console I/O are stripped in release builds.

---

### 6. Data Flow

```text
fetchAllCharacters()
   ├── Round-trip 1: GET /characters?page=1&limit=10 ──▶ reads meta.totalPages (e.g. 6)
   └── Round-trip 2: Future.wait([page=2, page=3, page=4, page=5, page=6]) ──▶ flattens into List<Character>

NetworkPicture(url, decodeWidth: 300)
   ├── Hit in 'dragonball_images' disk cache ──▶ Decodes at 300px wide (0 network requests)
   └── Cache miss ──▶ _LoggingClient logs → IMG ──▶ Downloads & saves to disk for 14 days

```

---

### 7. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 18 — Production API Resilience & Disk Image Caching

### Delta
- **`lib/api.dart`:** Added `ApiException` (`noConnection`, `timeout`, `server`, `badData`), 15s `.timeout()`, 1x retry loop for transient errors, `kDebugMode` stopwatch logging, and `_fetchAllPages()` concurrent pagination via `Future.wait`.
- **`lib/image_cache.dart`:** Configured `CacheManager` (`stalePeriod: 14 days`, `maxNrOfCacheObjects: 300`) wrapped with a `_LoggingClient` (`http.BaseClient`).
- **`lib/widgets.dart`:** Replaced raw `Image.network` calls with `NetworkPicture` (`CachedNetworkImage` + `memCacheWidth` budget: `300` for cards, `800` for details, `1600` for full-screen viewer).

### Chosen vs. Alternatives
- **Chosen:** Concurrent `Future.wait` pagination + `CachedNetworkImage` with `memCacheWidth`. Cuts multi-page load to 2 round-trips and reduces grid image RAM usage by ~25x.
- **Alternatives:** Sequential `while` pagination (slow waterfall) or uncached `Image.network` (re-downloads on restart and decodes full-res images into small grid cells).

### Learned
- Always `.clamp()` server-supplied pagination counts before spawning concurrent `Future.wait` loops.
- Subclassing `http.BaseClient` cleanly intercepts network traffic for logging without modifying the underlying HTTP transport.
- `memCacheWidth` constrains decoded bitmap memory in Flutter's image cache without altering the original file on disk.

```

---

### 8. Practice Questions

1. Why does `_getJson` avoid retrying when `error.kind == ApiErrorKind.badData` or `error.statusCode == 404`?
2. On a cold launch with cached images on disk, why will `[API] → GET /characters` still appear in your console while `[API] → IMG goku.webp` will **not**?













# Step 19 — Themes, Settings & Browser-Style Global `AppZoom`

### 1. Objective

Give users full control over **Theme** (`System`, `Light`, `Dark`, and true `#000000` **AMOLED black**), **Text Size** (`0.9x`–`1.3x`), **Global Zoom** (`75%`–`150%` scaling text, icons, padding, and images together like browser zoom), and **Default Starting Tab**—persisted synchronously in `SharedPreferences` and exposed through `SettingsScreen`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **AMOLED dark theme** | `ColorScheme.fromSeed(..., brightness: Brightness.dark)` + `.copyWith(surface: #000000, surfaceContainer: #111111, ...)` | Separate hardcoded dark theme from scratch | Preserves Material 3 dynamic orange accent tonal palettes while turning off OLED background pixels (`#000000`) and keeping cards subtly elevated (`#111111`–`#202020`). |
| **Browser-style global zoom** | Lay out the app on a smaller pretend viewport (`realScreenSize / zoom`) via `MediaQuery.copyWith`, then stretch to physical screen using `FittedBox(fit: BoxFit.fill)` | `Transform.scale(scale: zoom)` | `Transform.scale` scales pixels without reflowing layout—causing text and buttons to clip off screen edges. Virtual viewport spoofing reflows the entire UI cleanly and scales touch coordinates automatically. |
| **Preventing narrow layout breakage** | Clamp zoom so `pretendScreenSize` never drops below `320 × 320` dp (`maxZoomAllowedFor`) + expose `AppZoomInfo` `InheritedWidget` | Allowing arbitrary `150%` zoom on a `360dp` narrow phone | `360 / 1.5 = 240dp`, which overflows standard headers/chips. Clamping at `320dp` (`~112%` on a `360dp` phone) guarantees zero layout breakage, while `AppZoomInfo` lets `SettingsScreen` read the real physical screen size. |
| **Text scaling + Zoom order** | Apply `MediaQuery` `textScaler` **outside** `AppZoom`, multiplying `media.textScaler.scale(1.0) * settings.textSize` | Replacing system `textScaler` directly or putting `textScaler` inside `AppZoom` | Multiplying preserves OS accessibility font settings, and placing `textScaler` outside `AppZoom` means zoom scales both text and containers proportionally. |

---

### 3. Install Dependency

```bash
flutter pub add package_info_plus

```

---

### 4. New Files & Delta Changes

#### A. Create `lib/theme.dart` (Material 3 + AMOLED Palette)

```dart
ThemeData buildTheme(Brightness brightness, {bool amoled = false}) {
  var scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFED6C24),
    brightness: brightness,
  );

  if (amoled) {
    scheme = scheme.copyWith(
      surface: const Color(0xFF000000),
      surfaceDim: const Color(0xFF000000),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerHigh: const Color(0xFF181818),
      surfaceContainerHighest: const Color(0xFF202020),
    );
  }

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}

```

#### B. Create `lib/settings.dart` (`AppSettings` + `SettingsNotifier`)

* Define `ThemeChoice` (`system`, `light`, `dark`, `amoled`) and `StartTab` (`characters`, `planets`, `explore`, `favorites`—matching `IndexedStack` order).
* `SettingsNotifier extends Notifier<AppSettings>` reads initial values synchronously from `sharedPreferencesProvider` inside `build()` (validating enums by `.name` and numbers against allowed lists, falling back safely if stored data is invalid), updates `state` via `copyWith`, writes to `_prefs`, and provides `resetAll()` (which clears only setting keys, keeping `favorite_ids` intact).
* Add `packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform())` for displaying the app version in `SettingsScreen`.

#### C. Create `lib/app_zoom.dart` (`AppZoomInfo` + `AppZoom`)

```dart
const double minLayoutWidth = 320;
const double minLayoutHeight = 320;

double maxZoomAllowedFor(Size realScreenSize) {
  final byWidth = realScreenSize.width / minLayoutWidth;
  final byHeight = realScreenSize.height / minLayoutHeight;
  return math.max(1.0, math.min(byWidth, byHeight));
}

```

Inside `AppZoom.build`:

1. Compute `pretendScreenSize = Size(realScreenSize.width / zoom, realScreenSize.height / zoom)`.
2. Wrap `child` in `AppZoomInfo` (`InheritedWidget` carrying `realScreenSize` and `appliedZoom`).
3. Use `FittedBox(fit: BoxFit.fill)` around `SizedBox.fromSize(size: pretendScreenSize)` and override `MediaQuery` (`size`, `devicePixelRatio: mediaQuery.devicePixelRatio * zoom`, and scaled `padding` / `viewInsets`).

#### D. Wire `MaterialApp.builder` (`lib/main.dart`) & Create `SettingsScreen`

1. In `lib/main.dart`, watch `settingsProvider` inside `ConsumerWidget` to set `themeMode`, `theme`, `darkTheme`, and wrap `child!` in `MediaQuery` (`textScaler`) + `AppZoom(requestedZoom: settings.zoom, child: child!)`.
2. In `HomeScreen`, initialize `late int _index = ref.read(settingsProvider).startTab.index;` and add a gear `IconButton` in `AppBar.actions` pushing `SettingsScreen`.
3. Create `lib/settings_screen.dart` with `Wrap` + `ChoiceChip` rows (`_ChoiceSetting<T>`), dynamic `maxZoom` hint read from `AppZoomInfo.maybeOf(context)?.realScreenSize`, `showLicensePage`, Privacy Policy dialog, and Reset confirmation `AlertDialog`.

---

### 5. Engineering Insights (Why Each Piece Exists)

* **Why `devicePixelRatio: mediaQuery.devicePixelRatio * zoom` inside `AppZoom`?** Because `FittedBox` stretches a smaller logical canvas (`288dp`) onto a larger physical canvas (`360dp`), multiplying `devicePixelRatio` by `zoom` tells Flutter's image/text rasterizer to render crisp higher-density pixels so zoomed text and icons never look blurry.
* **Why `Wrap` instead of `Row` for `ChoiceChip`s in `SettingsScreen`?** On narrow screens or at `130%` text size + `125%` zoom, a `Row` of 4 chips would throw a yellow-and-black `RenderFlex overflowed` error. `Wrap` automatically flows chips onto a second line cleanly.
* **Why `SettingsScreen` reads `AppZoomInfo.maybeOf(context)?.realScreenSize`:** Inside `AppZoom`, `MediaQuery.sizeOf(context)` returns the *pretend* smaller screen size. `AppZoomInfo` exposes the true physical size so the Zoom hint accurately tells the user what maximum zoom their device supports.

---

### 6. Architecture & Data Flow

```text
SharedPreferences (pre-loaded in main)
        │
        ▼
settingsProvider (SettingsNotifier)
        │
        ├──▶ MaterialApp (themeMode, lightTheme, darkTheme / AMOLED)
        ├──▶ MaterialApp.builder ──▶ MediaQuery(textScaler) ──▶ AppZoom (pretend Size + FittedBox)
        ├──▶ HomeScreen (_index = startTab.index)
        └──▶ SettingsScreen (ChoiceChips, AlertDialog resetAll, AppZoomInfo realScreenSize)

```

---

### 7. README Entry (Delta Only — Copy-Paste Ready)

```markdown
## Step 19 — Themes, Settings & Browser-Style Global `AppZoom`

### Delta
- **`lib/theme.dart`:** Built Material 3 `buildTheme()` supporting Light, Dark, and true `#000000` AMOLED surface overrides.
- **`lib/settings.dart`:** Created `AppSettings` and `SettingsNotifier` (backed by `sharedPreferencesProvider`) for theme, start tab, text size, and zoom, plus `packageInfoProvider`.
- **`lib/app_zoom.dart`:** Implemented virtual-viewport `AppZoom` (`MediaQuery` size spoofing + `FittedBox`, clamped at `320dp` min layout width) and `AppZoomInfo` `InheritedWidget`.
- **`lib/main.dart`, `lib/home_screen.dart` & `lib/settings_screen.dart`:** Wired reactive theme/text/zoom into `MaterialApp.builder`, initialized tab index from `startTab`, and built `SettingsScreen` with `Wrap` `ChoiceChip`s and reset confirmation dialog.

### Chosen vs. Alternatives
- **Chosen:** Virtual viewport `MediaQuery` spoofing + `FittedBox` for `AppZoom` + `ColorScheme.fromSeed` AMOLED overrides. Reflows layouts cleanly at any zoom without off-screen clipping.
- **Alternative:** `Transform.scale` for zoom (scales visuals without reflowing layout, causing horizontal text/button clipping).

### Learned
- Multiplying `devicePixelRatio` by `zoom` inside `AppZoom` keeps rasterized text and images sharp when stretched by `FittedBox`.
- `Wrap` prevents `ChoiceChip` rows from overflowing on narrow screens or high accessibility text scales.
- `InheritedWidget` (`AppZoomInfo`) cleanly passes un-spoofed physical screen dimensions down to `SettingsScreen`.

```

---

### 8. Practice Questions

1. Why does `AppZoom` divide `mediaQuery.padding` and `mediaQuery.viewInsets` by `zoom` inside the virtual `MediaQuery`?
2. Why did we use `ref.read(settingsProvider).startTab.index` (instead of `ref.watch`) when initializing `_index` in `_HomeScreenState`?












Here is **Step 20** again, structured so you can inspect the exact architectural upgrades, why each one exists, and drop the final delta right into your `README.md`.

---

# Step 20 — Architecture Review & Production Polish

### 1. Objective

Upgrade fixed mobile-only grid columns to **responsive adaptive grids** (`SliverGridDelegateWithMaxCrossAxisExtent`), enforce **48×48 dp accessibility touch targets** across interactive widgets, extract shared navigation helpers (`openCharacter`), and verify the complete **startup lifecycle, Riverpod DAG, and production release checklist**.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Responsive grid columns** | `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, childAspectRatio: 0.72)` inside `CardGrid` | `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` | Hardcoding `2` columns stretches cards into wide banners on tablets, foldables, and web/desktop. `MaxCrossAxisExtent(200)` automatically scales from 2 columns on a `390dp` phone to 4 columns on an `800dp` tablet and 6 columns on a `1280dp` desktop—with zero `MediaQuery` `if/else` breakpoints. |
| **Accessibility touch targets** | Global `materialTapTargetSize: MaterialTapTargetSize.padded` in `ThemeData` + explicit `const double minTouchSize = 48` on `FavoriteButton` & viewer controls + `Semantics` labels | Default shrink-wrapped icon hitboxes (`32–40dp`) | WCAG and Android Material guidelines require at least `48 × 48 dp` tap targets so users don't accidentally trigger the underlying card tap when trying to hit the heart button. |
| **Centralized navigation** | Shared `openCharacter(BuildContext, Character)` function in `widgets.dart` | Duplicating `Navigator.of(context).push(MaterialPageRoute(...))` in both `CharacterCard` and `ExploreScreen`'s `ListTile` | Single place to update route transitions or analytics later without touching multiple screens. |

---

### 3. Delta Changes (`lib/widgets.dart`)

#### A. Extract Responsive `CardGrid` & `openCharacter`

Replace the repeated `GridView.builder` boilerplate across `_CharactersTab`, `_PlanetsTab`, `_FavoritesTab`, and `ExploreScreen` with `CardGrid`:

```dart
/// Every button and tap area is at least this big (Android accessibility rule).
const double minTouchSize = 48;

class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

void openCharacter(BuildContext context, Character character) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CharacterScreen(character: character),
    ),
  );
}

```

#### B. Enforce `48 × 48 dp` Minimum Hitbox on `FavoriteButton` & Viewer Close Button

```dart
IconButton(
  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
  style: IconButton.styleFrom(
    minimumSize: const Size(minTouchSize, minTouchSize),
  ),
  // ...
)

```

---

### 4. End-to-End Architecture & Dependency Graph Review

Every layer in your final app flows in one predictable direction—from synchronous disk initialization at boot down to pure UI widgets:

```text
[1. Cold Start]
WidgetsFlutterBinding.ensureInitialized()
       │
       ▼
await SharedPreferences.getInstance()  ──▶  ProviderScope(overrides: [sharedPreferencesProvider])
                                                    │
       ┌────────────────────────────────────────────┼───────────────────────────────────┐
       ▼                                            ▼                                   ▼
settingsProvider                             favoritesProvider                    apiProvider (http.Client)
 (Theme, Zoom, TextSize, StartTab)            (Set<int> persisted)                 │
       │                                            │                    ┌──────────┴──────────┐
       ▼                                            │                    ▼                     ▼
MiniApp (MaterialApp.builder)                       │           charactersProvider     planetsProvider
 ├── ThemeData (Light / Dark / AMOLED)              │            (2-trip concurrent)    (2-trip concurrent)
 ├── MediaQuery (textScaler 0.8–2.0)                │                    │                     │
 └── AppZoom (virtual viewport + FittedBox)         │                    ▼                     ▼
       │                                            │         visibleCharactersProvider  visiblePlanetsProvider
       ▼                                            │                    │
SplashScreen (Future.wait + 8s timeout)             └──────────┬─────────┘
       │                                                       ▼
       ▼ (pushReplacement)                          favoriteCharactersProvider
HomeScreen (IndexedStack + NavigationBar)
 ├── [0] Characters ──▶ AsyncList ──▶ CardGrid ──▶ CharacterCard ──▶ CharacterScreen ──▶ characterExtrasProvider(id)
 ├── [1] Planets    ──▶ AsyncList ──▶ CardGrid ──▶ PlanetCard (ModalBottomSheet)               │
 ├── [2] Explore    ──▶ exploreGroupsProvider + exploreVisibleProvider (ki_parser.dart)        ▼
 └── [3] Favorites  ──▶ AsyncList ──▶ CardGrid ──▶ CharacterCard                     FullScreenImageViewer

```

---

### 5. Production Readiness Verification Checklist

1. **Zero Static Analysis Warnings:**
```bash
flutter analyze

```


2. **Deterministic Unit Tests on Pure Logic (`ki_parser.dart`, `AppZoom`, `fromJson`):**
```bash
flutter test

```


*(Because `parseKi`, `maxZoomAllowedFor`, and `Character.fromJson` have zero widget dependencies, they run in milliseconds without an emulator.)*
3. **Release-Safe Logging:**
All `[API]` and `[IMG]` logs are guarded by `if (!kDebugMode) return;`, ensuring zero console overhead or data leakage in production builds.
4. **Release Build Smoke Test:**
```bash
flutter build apk --release   # or flutter build web / flutter build ipa

```



---

### 6. README Entry (Final Step + Complete Progress Table — Copy-Paste Ready)

```markdown
## Step 20 — Architecture Review & Production Polish

### Delta
- **`lib/widgets.dart`:** Replaced fixed 2-column grids with responsive `CardGrid` (`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200)`), extracted shared `openCharacter()` navigation helper, and enforced `minTouchSize = 48` on interactive icons.
- **System Audit:** Verified unidirectional data flow (`SharedPreferences` ─▶ Riverpod DAG ─▶ `AsyncList` ─▶ `CardGrid`), debug-only `kDebugMode` logging, and release build readiness.

### Chosen vs. Alternatives
- **Chosen:** `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200)` + `48dp` touch targets. Adapts automatically across phones, tablets, and desktop/web without manual breakpoint conditionals.
- **Alternative:** `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` (stretches cards excessively on wide viewports).

### Learned
- `SliverGridDelegateWithMaxCrossAxisExtent` computes optimal column counts automatically from available viewport width.
- Isolating pure domain functions (`parseKi`, `maxZoomAllowedFor`, `Character.fromJson`) makes unit testing fast and deterministic.
- Enforcing `48dp` minimum touch targets and `Semantics` labels ensures accessibility across mobile and desktop inputs.

---

## Course Complete — 20 / 20 Steps

| Step | Feature | Status |
|---|---|---|
| 1 | Create Flutter Project & Entry Point | Completed |
| 2 | Static Homepage (`GridView.builder`) | Completed |
| 3 | `Character` Model | Completed |
| 4 | First API Request (`http`) | Completed |
| 5 | Separate API Service | Completed |
| 6 | JSON Parsing (`Character.fromJson`) | Completed |
| 7 | `FutureBuilder` & API Data | Completed |
| 8 | Loading, Error, Empty & Retry States | Completed |
| 9 | Reusable `CharacterCard` Widget | Completed |
| 10 | Character Details Screen & Navigation | Completed |
| 11 | Search & In-Memory Filtering | Completed |
| 12 | Favorites & Local Persistence (`SharedPreferences`) | Completed |
| 13 | Introduce Riverpod (`ProviderScope` & `Notifier`) | Completed |
| 14 | Migrate API & Search into Riverpod (`AsyncList<T>`) | Completed |
| 15 | Planets, Bottom Navigation (`IndexedStack`) & Splash | Completed |
| 16 | Explore Screen & Ki Power Parser | Completed |
| 17 | Advanced Character Details & Full-Screen Image Viewer | Completed |
| 18 | Concurrent Pagination, Retries & Disk Image Caching | Completed |
| 19 | Themes (AMOLED), Settings & Global `AppZoom` | Completed |
| 20 | Architecture Review & Production Polish | Completed |

```








# Step 21 — Offline JSON Disk Caching (Stale-While-Revalidate)

### 1. Objective

Persist the serialized character and planet lists (plus a timestamp) into `SharedPreferences` whenever a network fetch succeeds—so on cold launches without internet (or slow connections), the app falls back cleanly to cached JSON and displays an `"Offline mode"` status banner instead of a dead retry screen.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Storage location for JSON cache** | `SharedPreferences` (`cache_characters_v1`, `cache_planets_v1`, `cache_updated_at`) | Adding `sqflite`, `hive`, or `isar` | You already inject `SharedPreferences` synchronously at boot (`sharedPreferencesProvider`), and the entire Dragon Ball dataset (~58 characters + ~20 planets) is ~45 KB of JSON—well within key-value storage limits with zero new dependencies. |
| **Cache strategy** | **Network-first with offline fallback** (plus explicit pull-to-refresh) | Cache-only forever (never fetching updates) | Ensures users get fresh API data whenever online, while offline cold starts immediately hydrate from disk instead of failing on `ApiErrorKind.noConnection`. |
| **Data representation on disk** | `toJson()` on `Character` and `Planet` serialized via `jsonEncode` | Caching raw paginated HTTP pages | Storing the flattened, normalized `List>` avoids re-running 6-page envelope extraction on every offline cold start. |

---

### 3. Delta Changes

#### A. Add `toJson()` to `Character` & `Planet` (`lib/models.dart`)

```dart
// Inside Character:
Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'ki': ki,
      'maxKi': maxKi,
      'race': race,
      'gender': gender,
      'description': description,
      'image': image,
      'affiliation': affiliation,
    };

// Inside Planet:
Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'isDestroyed': isDestroyed,
    };

```

#### B. Create `lib/offline_cache.dart` (Typed JSON Cache Wrapper)

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class OfflineCache {
  OfflineCache(this._prefs);
  final SharedPreferences _prefs;

  static const _charactersKey = 'cache_characters_v1';
  static const _planetsKey = 'cache_planets_v1';
  static const _updatedAtKey = 'cache_updated_at_ms';

  Future<void> saveCharacters(List<Character> items) async {
    await _prefs.setString(
      _charactersKey,
      jsonEncode([for (final c in items) c.toJson()]),
    );
    await _prefs.setInt(_updatedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  List<Character>? readCharacters() {
    final raw = _prefs.getString(_charactersKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) Character.fromJson(item),
      ];
    } catch (_) {
      return null; // Corrupt cache falls back cleanly to network error
    }
  }

  Future<void> savePlanets(List<Planet> items) async {
    await _prefs.setString(
      _planetsKey,
      jsonEncode([for (final p in items) p.toJson()]),
    );
  }

  List<Planet>? readPlanets() {
    final raw = _prefs.getString(_planetsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) Planet.fromJson(item),
      ];
    } catch (_) {
      return null;
    }
  }

  DateTime? get lastUpdated {
    final ms = _prefs.getInt(_updatedAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

```

#### C. Wire Fallback & Offline Flag into `lib/providers.dart`

```dart
final offlineCacheProvider = Provider<OfflineCache>(
  (ref) => OfflineCache(ref.watch(sharedPreferencesProvider)),
);

class IsOffline extends Notifier<bool> {
  @override
  bool build() => false;
  void setOffline(bool value) => state = value;
}

final isOfflineProvider = NotifierProvider<IsOffline, bool>(IsOffline.new);

final charactersProvider = FutureProvider<List<Character>>((ref) async {
  final cache = ref.read(offlineCacheProvider);
  try {
    final fresh = await ref.watch(apiProvider).fetchAllCharacters();
    await cache.saveCharacters(fresh);
    ref.read(isOfflineProvider.notifier).setOffline(false);
    return fresh;
  } catch (error) {
    final cached = cache.readCharacters();
    if (cached != null && cached.isNotEmpty) {
      ref.read(isOfflineProvider.notifier).setOffline(true);
      return cached;
    }
    rethrow; // First-ever launch with no internet still shows Retry UI
  }
});

```

*(Apply the identical `try / catch` fallback pattern to `planetsProvider`.)*

#### D. Display Subtle Offline Banner in `lib/home_screen.dart`

Above `Expanded(child: IndexedStack(...))`, watch `isOfflineProvider`:

```dart
if (ref.watch(isOfflineProvider))
  MaterialBanner(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    content: const Text('Offline mode — showing saved data'),
    leading: const Icon(Icons.wifi_off, size: 20),
    actions: [
      TextButton(
        onPressed: () => reloadCharacters(ref),
        child: const Text('Retry'),
      ),
    ],
  ),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why version the storage keys (`cache_characters_v1`)?** If you add new fields to `Character` in a future release, bumping `_v1` → `_v2` avoids deserializing stale schemas that lack the new keys.
* **Why `rethrow` when `cached == null`?** On a brand-new install with airplane mode enabled, `readCharacters()` returns `null`—`rethrow` preserves the original `ApiException` so `AsyncList` displays its `Retry` button instead of an empty list.
* **Why `SettingsNotifier.resetAll()` won't accidentally wipe favorites if scoped by key:** Just like `favorite_ids`, `resetAll()` in `settings.dart` removes only setting keys—keeping both favorites and offline cache intact unless the user explicitly clears cache (Step 22).

---

### 5. Data Flow

```text
charactersProvider
   ├── 1. Try API: fetchAllCharacters()
   │        ├── Success ─▶ cache.saveCharacters(fresh) + isOffline = false ─▶ Return fresh
   │        └── Failure ─▶ cache.readCharacters()
   │                         ├── Cache hit  ─▶ isOffline = true + MaterialBanner ─▶ Return cached
   │                         └── Cache miss ─▶ rethrow ─▶ AsyncList Retry UI

```

---

Say **next** whenever you're ready for **Step 22 — Cache Management & Storage Controls**!











# Step 22 — Cache Management & Storage Controls

### 1. Objective

Give users visibility and control over local disk storage in `SettingsScreen`—displaying when offline data was last synced and providing a **Clear Cache** action that purges both disk/RAM image caches (`imageCacheManager` + `PaintingBinding.instance.imageCache`) and saved JSON snapshots (`OfflineCache`) without touching user favorites or app preferences.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Which caches to clear** | Disk image cache (`imageCacheManager.emptyCache()`), decoded RAM image cache (`PaintingBinding.instance.imageCache.clear()`), and offline JSON keys (`OfflineCache.clear()`) | Calling `SharedPreferences.clear()` | `prefs.clear()` would wipe `favorite_ids` and user theme/zoom settings. Targeted clearing frees temporary assets while preserving user data. |
| **Post-clear provider state** | Do **not** immediately `ref.invalidate(charactersProvider)` while offline | Immediately invalidating `charactersProvider` after clearing disk cache | If the user clears cache while offline, immediate invalidation would replace their already-loaded in-memory grid with an offline error screen. Let in-memory providers stay alive until the next refresh or restart. |
| **Confirmation UX** | `AlertDialog` confirmation + `SnackBar` feedback | One-tap immediate purge | Re-downloading up to 300 character/planet images uses mobile data; confirming prevents accidental taps. |

---

### 3. Delta Changes

#### A. Add `clear()` to `OfflineCache` (`lib/offline_cache.dart`)

```dart
Future<void> clear() async {
  await _prefs.remove(_charactersKey);
  await _prefs.remove(_planetsKey);
  await _prefs.remove(_updatedAtKey);
}

```

#### B. Add a Cache Helper in `lib/providers.dart`

```dart
Future<void> clearAppCaches(WidgetRef ref) async {
  await imageCacheManager.emptyCache();
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  await ref.read(offlineCacheProvider).clear();
}

```

#### C. Add Storage Section to `lib/settings_screen.dart`

1. Format `lastUpdated` from `ref.read(offlineCacheProvider).lastUpdated`:

```dart
String _formatSyncTime(DateTime? dt) {
  if (dt == null) return 'No offline snapshot saved';
  final twoDigits = (int n) => n.toString().padLeft(2, '0');
  return 'Last synced: ${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)} '
      '${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
}

```

2. Add a `ListTile` in `SettingsScreen` under a **Storage** section header:

```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.cleaning_services_outlined),
  title: const Text('Clear cached images & offline data'),
  subtitle: Text(_formatSyncTime(ref.watch(offlineCacheProvider).lastUpdated)),
  onTap: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'Removes saved images and offline snapshots. Your favorites and settings will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await clearAppCaches(ref);
    if (!context.mounted) return;
    setState(() {}); // Refreshes the "Last synced" subtitle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cached images and offline data cleared')),
    );
  },
),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why clear both `imageCacheManager` AND `PaintingBinding.instance.imageCache`?** `flutter_cache_manager` stores compressed `.webp`/`.png` files on disk, whereas Flutter's `PaintingBinding.instance.imageCache` keeps uncompressed decoded `ui.Image` bitmaps in RAM. Clearing only disk files leaves decoded bitmaps in RAM; clearing both frees disk space and memory immediately.
* **Why `if (!context.mounted) return;` appears twice:** Each `await` (`showDialog` and `clearAppCaches`) yields back to the event loop—checking `context.mounted` after each async gap ensures we never use a `BuildContext` if the user popped `SettingsScreen` mid-operation.

---

### 5. Cache Purge Flow

```text
User taps "Clear cached images & offline data"
       │
       ▼
AlertDialog confirmation (true)
       │
       ├──▶ imageCacheManager.emptyCache()                (Disk files deleted)
       ├──▶ PaintingBinding.instance.imageCache.clear()   (Decoded RAM bitmaps freed)
       └──▶ offlineCacheProvider.clear()                  (JSON snapshots removed; favorites untouched)

```

---

Say **next** whenever you're ready for **Step 23 — Tab-Scoped Search State**!










# Step 23 — Tab-Scoped Search State

### 1. Objective

Scope `searchTextProvider` by tab index (`NotifierProvider.family`) and bind each tab's `SearchBar` to its own `TextEditingController`—so typing `"Goku"` on the **Characters** tab never silently filters **Planets** to 0 results when switching bottom navigation tabs.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Search state granularity** | `NotifierProvider.family<TabSearchText, String, int>` keyed by `StartTab` / tab index (`0` = Characters, `1` = Planets, `3` = Favorites) | Single global `searchTextProvider` shared across all tabs, or resetting search on every tab switch | A global string leaks character queries into planets; resetting on tab switch destroys the user's in-progress filter if they briefly peek at Favorites and come back. `.family` isolates each tab's query cleanly. |
| **Controller lifecycle** | Store `Map<int, TextEditingController>` in `_HomeScreenState` (disposed in `dispose()`) | Reusing one `TextEditingController` and overwriting `.text` on tab change | Mutating a single controller's `.text` on tab switch resets cursor selection, triggers spurious `onChanged` callbacks, and flickers the clear icon. Dedicated controllers preserve cursor position per tab. |

---

### 3. Delta Changes

#### A. Parameterize `searchTextProvider` in `lib/providers.dart`

```dart
class TabSearchText extends Notifier<String> {
  TabSearchText(this.tabIndex);
  final int tabIndex;

  @override
  String build() => '';

  void setText(String value) => state = value;
  void clear() => state = '';
}

final tabSearchProvider =
    NotifierProvider.family<TabSearchText, String, int>(TabSearchText.new);

```

#### B. Update Filtered Providers in `lib/providers.dart`

```dart
final visibleCharactersProvider = Provider<AsyncValue<List<Character>>>((ref) {
  final asyncCharacters = ref.watch(charactersProvider);
  final search = ref.watch(tabSearchProvider(StartTab.characters.index)).trim().toLowerCase();

  return asyncCharacters.whenData((list) {
    if (search.isEmpty) return list;
    return [
      for (final c in list)
        if (c.name.toLowerCase().contains(search) ||
            c.race.toLowerCase().contains(search))
          c,
    ];
  });
});

final visiblePlanetsProvider = Provider<AsyncValue<List<Planet>>>((ref) {
  final asyncPlanets = ref.watch(planetsProvider);
  final search = ref.watch(tabSearchProvider(StartTab.planets.index)).trim().toLowerCase();

  return asyncPlanets.whenData((list) {
    if (search.isEmpty) return list;
    return [
      for (final p in list)
        if (p.name.toLowerCase().contains(search)) p,
    ];
  });
});

final favoriteCharactersProvider = Provider<AsyncValue<List<Character>>>((ref) {
  final asyncCharacters = ref.watch(charactersProvider);
  final favIds = ref.watch(favoritesProvider);
  final search = ref.watch(tabSearchProvider(StartTab.favorites.index)).trim().toLowerCase();

  return asyncCharacters.whenData((list) {
    return [
      for (final c in list)
        if (favIds.contains(c.id) &&
            (search.isEmpty ||
                c.name.toLowerCase().contains(search) ||
                c.race.toLowerCase().contains(search)))
          c,
    ];
  });
});

```

#### C. Bind Per-Tab Controllers in `lib/home_screen.dart`

```dart
late final Map<int, TextEditingController> _searchControllers = {
  StartTab.characters.index: TextEditingController(),
  StartTab.planets.index: TextEditingController(),
  StartTab.favorites.index: TextEditingController(),
};

@override
void dispose() {
  for (final controller in _searchControllers.values) {
    controller.dispose();
  }
  super.dispose();
}

```

Inside `_buildSearchHeader(int tabIndex, String hint)`:

```dart
final query = ref.watch(tabSearchProvider(tabIndex));
final controller = _searchControllers[tabIndex]!;

return SearchBar(
  controller: controller,
  hintText: hint,
  leading: const Icon(Icons.search),
  trailing: [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear search',
        onPressed: () {
          controller.clear();
          ref.read(tabSearchProvider(tabIndex).notifier).clear();
        },
        icon: const Icon(Icons.close),
      ),
  ],
  onChanged: (value) => ref.read(tabSearchProvider(tabIndex).notifier).setText(value),
);

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why key by `StartTab.<tab>.index` instead of magic numbers (`0`, `1`, `3`)?** Using the existing `StartTab` enum's `.index` creates a compile-time link between `IndexedStack` positions and provider keys—if you ever reorder tabs in `StartTab`, every search provider stays aligned automatically.
* **Why `IndexedStack` + per-tab `TextEditingController` work together seamlessly:** Because `IndexedStack` keeps off-screen tabs mounted in the widget tree, switching from Characters (`"Goku"`) to Planets (`"Namek"`) and back preserves both the scroll offset and the exact search bar text on every tab.

---

### 5. Scoped State Topology

```text
HomeScreen (_index)
 ├── Tab 0 (Characters) ──▶ _searchControllers[0] ──▶ tabSearchProvider(0) ──▶ visibleCharactersProvider
 ├── Tab 1 (Planets)    ──▶ _searchControllers[1] ──▶ tabSearchProvider(1) ──▶ visiblePlanetsProvider
 ├── Tab 2 (Explore)    ──▶ ExploreSelection.query ──▶ exploreSelectionProvider ──▶ exploreVisibleProvider
 └── Tab 3 (Favorites)  ──▶ _searchControllers[3] ──▶ tabSearchProvider(3) ──▶ favoriteCharactersProvider

```

---









# Step 24 — Planet ↔ Character Cross-Linking

### 1. Objective

Connect planets and characters bi-directionally across the UI: extract `PlanetCard`'s modal bottom sheet into a reusable `showPlanetSheet(BuildContext, Planet)` helper so tapping `originPlanet` on `CharacterScreen` opens that planet's sheet, and enrich the planet sheet with an interactive horizontal strip of native characters (`ActionChip`s) that navigate straight to `CharacterScreen`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Finding a planet's native characters** | Derived Riverpod provider `planetCharactersProvider(int planetId)` filtering `charactersProvider` (or matching `originPlanet`) | Making a new `GET /planets/$id` API call on every bottom sheet tap | `charactersProvider` is already cached in memory with all ~58 characters; deriving the list in RAM opens the sheet instantaneously with zero extra network round-trips. |
| **Modal sheet extraction** | Top-level `showPlanetSheet(BuildContext, Planet)` function in `lib/widgets.dart` | Duplicating `showModalBottomSheet(...)` inside both `PlanetCard` and `CharacterScreen` | Single source of truth for planet presentation, image viewer trigger, and native character navigation. |
| **Preventing infinite sheet → screen → sheet stacks** | Optional `bool allowCharacterNavigation = true` parameter (or popping the sheet first via `Navigator.of(sheetContext).pop()` before `openCharacter`) | Pushing `CharacterScreen` on top of an open `ModalBottomSheet` | Popping the bottom sheet before pushing `CharacterScreen` keeps the back-stack clean—pressing Back returns cleanly to the previous screen instead of a stale half-open sheet. |

---

### 3. Delta Changes

#### A. Add `planetCharactersProvider` (`lib/providers.dart`)

Since `/characters` list items don't include `originPlanet` (only `/characters/$id` does), match by checking loaded `characterExtrasProvider` entries **or** load `GET /planets/$id` once via `planetCharactersProvider`:

```dart
final planetCharactersProvider =
    FutureProvider.family<List<Character>, int>((ref, planetId) async {
  final json = await ref.watch(apiProvider).fetchPlanetRaw(planetId);
  final rawChars = json['characters'];
  if (rawChars is! List) return const [];

  final allChars = await ref.watch(charactersProvider.future);
  final byId = {for (final c in allChars) c.id: c};

  return [
    for (final item in rawChars)
      if (item is Map<String, dynamic> && item['id'] is num)
        byId[(item['id'] as num).toInt()] ?? Character.fromJson(item),
  ];
});

```

*(Add `Future> fetchPlanetRaw(int id)` in `lib/api.dart` calling `_getJson('/planets/$id') as Map<String, dynamic>`.)*

#### B. Extract `showPlanetSheet` (`lib/widgets.dart`)

```dart
void showPlanetSheet(BuildContext context, Planet planet) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _PlanetDetailSheet(planet: planet),
  );
}

```

Inside `_PlanetDetailSheet` (`ConsumerWidget`):

```dart
final residentsAsync = ref.watch(planetCharactersProvider(planet.id));

// Below planet description:
residentsAsync.when(
  loading: () => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: LinearProgressIndicator(),
  ),
  error: (_, __) => const SizedBox.shrink(),
  data: (residents) {
    if (residents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Notable Residents', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final character in residents)
              ActionChip(
                avatar: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    character.image,
                    cacheManager: imageCacheManager,
                  ),
                ),
                label: Text(character.name),
                onPressed: () {
                  Navigator.of(sheetContext).pop(); // Close sheet first
                  openCharacter(context, character);
                },
              ),
          ],
        ),
      ],
    );
  },
),

```

*(Update `PlanetCard`'s `InkWell.onTap` to call `showPlanetSheet(context, planet)`.)*

#### C. Make `originPlanet` Tappable on `CharacterScreen` (`lib/character_screen.dart`)

Replace the static `originPlanet` text row with a tappable `ActionChip` / `InkWell` row when `extras.originPlanet != null`:

```dart
if (extras.originPlanet != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: ActionChip(
      avatar: const Icon(Icons.public, size: 18),
      label: Text('Origin: ${extras.originPlanet!.name}'),
      onPressed: () => showPlanetSheet(context, extras.originPlanet!),
    ),
  ),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `byId[(item['id'] as num).toInt()] ?? Character.fromJson(item)`?** The `/planets/$id` endpoint returns partial character objects (sometimes missing fields or descriptions), whereas `charactersProvider` already holds the complete `Character` models in RAM. Looking up by `id` first ensures `CharacterScreen` receives the richest model available, with `Character.fromJson(item)` as a safe fallback.
* **Why `Navigator.of(sheetContext).pop()` uses `sheetContext` instead of the outer `context`:** Inside `showModalBottomSheet`, `sheetContext` belongs to the modal route itself—popping `sheetContext` dismisses only the bottom sheet while keeping the underlying `Scaffold` `context` valid for `openCharacter(context, character)`.

---

### 5. Bi-Directional Navigation Graph

```text
CharacterScreen
   ├── Tap "Origin: Planet Vegeta" ──▶ showPlanetSheet(context, originPlanet)
   │                                        │
   │                                        ▼
   │                                  _PlanetDetailSheet (planetCharactersProvider)
   │                                        │
   └── openCharacter(context, resident) ◀───┴── Tap ActionChip("Bardock" / "Vegeta")

```

---

Say **next** whenever you're ready for **Step 25 — Shared-Element `Hero` Transitions**!










# Step 25 — Shared-Element `Hero` Transitions

### 1. Objective

Connect `CharacterCard` and `CharacterScreen` with shared-element `Hero` animations so character artwork flies and scales smoothly between grid tiles and the full detail view—while avoiding duplicate-tag crashes caused by `IndexedStack` keeping multiple tabs alive in the widget tree simultaneously.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Hero tag uniqueness** | Scope tags by source surface (`'char-$heroScope-${character.id}'`, e.g., `'characters'`, `'favorites'`, `'explore'`) and pass that `heroTag` into `CharacterScreen` | Using a bare `'character-${character.id}'` tag everywhere | Because `HomeScreen` uses `IndexedStack`, Goku can be mounted simultaneously in **Characters** (index 0) and **Favorites** (index 3). When `Navigator.push` runs, Flutter scans the entire active tree for matching `Hero` tags—two identical tags in the source route throw a fatal `"There are multiple heroes that share the same tag within a subtree"` exception. |
| **Respecting accessibility** | Disable or instant-complete `Hero` flight when `MediaQuery.disableAnimationsOf(context)` is `true` | Unconditional `Hero` animations | Users who enable "Remove animations" in OS accessibility settings expect instant transitions without motion sickness triggers. |
| **Destination `Hero` alignment** | Match `BoxFit.contain` inside `Hero` on both source card and `CharacterScreen` | Wrapping `Image.network` with `BoxFit.cover` on source and `BoxFit.contain` on destination | Dragon Ball character PNGs have transparent vertical silhouettes; matching `BoxFit.contain` prevents harsh aspect-ratio snapping mid-flight. |

---

### 3. Delta Changes

#### A. Add `heroScope` to `CharacterCard` & `openCharacter` (`lib/widgets.dart`)

```dart
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.character,
    this.heroScope = 'grid',
  });

  final Character character;
  final String heroScope;

  String get _heroTag => 'character-$heroScope-${character.id}';

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final artwork = NetworkPicture(
      url: character.image,
      fit: BoxFit.contain,
      fallbackIcon: Icons.person_outline,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCharacter(
          context,
          character,
          heroTag: disableAnimations ? null : _heroTag,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: disableAnimations
                    ? artwork
                    : Hero(tag: _heroTag, child: artwork),
              ),
            ),
            // ... existing bottom Padding with character.name & character.race ...
          ],
        ),
      ),
    );
  }
}

void openCharacter(
  BuildContext context,
  Character character, {
  String? heroTag,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CharacterScreen(
        character: character,
        heroTag: heroTag,
      ),
    ),
  );
}

```

#### B. Pass Distinct `heroScope` Values from Each Tab (`lib/home_screen.dart` & `lib/explore_screen.dart`)

* **Characters tab:** `CharacterCard(character: c, heroScope: 'characters')`
* **Favorites tab:** `CharacterCard(character: c, heroScope: 'favorites')`
* **Explore grid:** `CharacterCard(character: c, heroScope: 'explore')`
* **Planet sheet resident chips (`lib/widgets.dart`):** `openCharacter(context, character)` (defaults `heroTag: null` since the modal sheet dismisses immediately).

#### C. Wrap the Primary Artwork in `CharacterScreen` (`lib/character_screen.dart`)

Add `final String? heroTag;` to `CharacterScreen` and wrap the main image:

```dart
final mainArtwork = NetworkPicture(
  url: character.image,
  fit: BoxFit.contain,
  fallbackIcon: Icons.person_outline,
);

// Inside the hero image container:
child: heroTag == null
    ? mainArtwork
    : Hero(tag: heroTag!, child: mainArtwork),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `IndexedStack` makes `heroScope` mandatory:** Unlike `PageView` or tab-swapping builders that unmount off-screen tabs, `IndexedStack` keeps all 4 tabs mounted in the `Element` tree with `Offstage(offstage: true)`. Flutter's `HeroController` searches offstage subtrees too—so scoping by tab (`'characters'` vs. `'favorites'`) guarantees every mounted `Hero` tag is globally unique.
* **Why `heroTag` is nullable (`String?`) on `CharacterScreen`:** Entry points without a visible card (like tapping a resident `ActionChip` inside a dismissed `ModalBottomSheet` or a deep link) pass `heroTag: null`, cleanly falling back to the standard Material route transition without orphaned `Hero` widgets.

---

### 5. Hero Flight Lifecycle

```text
User taps CharacterCard in Favorites tab (heroScope: 'favorites')
       │
       ▼
Source Hero(tag: 'character-favorites-1') found in active tree
       │
       ▼  Navigator.push(CharacterScreen(heroTag: 'character-favorites-1'))
Destination Hero(tag: 'character-favorites-1') matched in overlay
       │
       ▼
Flutter interpolates Rect + Scale smoothly across route transition (and reverses on pop)

```

---

Say **next** whenever you're ready for **Step 26 — Logarithmic Ki Power Comparison (VS Mode)**!







# Step 26 — Logarithmic Ki Power Comparison (VS Mode)

### 1. Objective

Build an interactive **VS Power Comparison** screen that lets users select any two characters and compare their base `ki` and `maxKi` visually—mapping `parseKi` from `ki_parser.dart` onto a **base-10 logarithmic bar scale** so characters spanning 21+ orders of magnitude (`1,000` vs. `90 Septillion`) render with readable proportions instead of collapsing to `0%`.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Bar scaling math** | Base-10 logarithmic normalization: `math.log(value) / math.ln10` mapped against `[0, ceilingLog10]`, with `1.0` reserved for `double.infinity` (`∞`) | Linear ratio `kiA / max(kiA, kiB)` | Dragon Ball power levels span from `~1,000` ($10^3$) to `90 Septillion` ($9 \times 10^{25}$). On a linear scale, `1,000 / 9e25 = 0.000000000000000000001%`—making every fighter except Zeno look identical at `0px` wide. Logarithmic scaling maps each order of magnitude (`Thousand` → `Million` → `Billion` → `Septillion`) to equal visual steps. |
| **Handling `0`, `Unknown`, and `∞**` | Pure `kiBarFraction(double ki, {double ceilingLog10 = 26.0})` helper: `<= 0` → `0.0`, `isInfinite` → `1.0`, finite `> 0` → `(log10(ki) / ceilingLog10).clamp(0.05, 0.96)` | Passing `0` or `double.infinity` directly into `math.log()` | `math.log(0)` yields `-Infinity` and `math.log(double.infinity)` yields `Infinity`—both throw `ArgumentError` or `UnsupportedError` inside `FractionallySizedBox(widthFactor: ...)`. |
| **Entry point** | `Compare` icon button in `CharacterScreen`'s `AppBar` (pre-selecting the current character in Fighter A) | Adding a 5th bottom navigation tab | Keeps the bottom `NavigationBar` clean at 4 destinations while letting users immediately pit the character they're inspecting against any rival. |

---

### 3. Delta Changes

#### A. Add Pure Logarithmic Scale Helper to `lib/ki_parser.dart`

```dart
import 'dart:math' as math;

/// Converts a parsed Ki value into a 0.0..1.0 bar width on a log10 scale.
/// [ceilingLog10] represents the highest finite log10 Ki in the catalog (e.g. 26.0 for ~10^26).
double kiBarFraction(double ki, {double ceilingLog10 = 26.0}) {
  if (ki.isNaN || ki <= 0) return 0.0;
  if (ki.isInfinite) return 1.0;

  final logVal = math.log(ki) / math.ln10;
  if (logVal <= 0) return 0.04;
  return (logVal / ceilingLog10).clamp(0.05, 0.96);
}

```

#### B. Create `lib/compare_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ki_parser.dart';
import 'models.dart';
import 'providers.dart';
import 'widgets.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key, this.initialLeft});

  final Character? initialLeft;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  Character? _left;
  Character? _right;

  @override
  void initState() {
    super.initState();
    _left = widget.initialLeft;
  }

  @override
  Widget build(BuildContext context) {
    final charsAsync = ref.watch(charactersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Power Comparison (Log Scale)')),
      body: charsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (characters) {
          if (characters.length < 2) {
            return const Center(child: Text('Need at least 2 characters to compare.'));
          }
          final left = _left ?? characters.first;
          final right = _right ??
              characters.firstWhere(
                (c) => c.id != left.id,
                orElse: () => characters[1],
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FighterPicker(
                      label: 'Fighter A',
                      selected: left,
                      characters: characters,
                      onChanged: (c) => setState(() => _left = c),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  Expanded(
                    child: _FighterPicker(
                      label: 'Fighter B',
                      selected: right,
                      characters: characters,
                      onChanged: (c) => setState(() => _right = c),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MetricComparisonCard(
                title: 'Base Ki (Log10 Scale)',
                leftName: left.name,
                leftLabel: left.ki,
                leftValue: parseKi(left.ki),
                rightName: right.name,
                rightLabel: right.ki,
                rightValue: parseKi(right.ki),
              ),
              const SizedBox(height: 12),
              _MetricComparisonCard(
                title: 'Max Ki (Log10 Scale)',
                leftName: left.name,
                leftLabel: left.maxKi,
                leftValue: parseKi(left.maxKi),
                rightName: right.name,
                rightLabel: right.maxKi,
                rightValue: parseKi(right.maxKi),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FighterPicker extends StatelessWidget {
  const _FighterPicker({
    required this.label,
    required this.selected,
    required this.characters,
    required this.onChanged,
  });

  final String label;
  final Character selected;
  final List<Character> characters;
  final ValueChanged<Character> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
              height: 110,
              child: NetworkPicture(
                url: selected.image,
                fit: BoxFit.contain,
                fallbackIcon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selected.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: [
                for (final c in characters)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                final picked = characters.firstWhere((c) => c.id == id);
                onChanged(picked);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricComparisonCard extends StatelessWidget {
  const _MetricComparisonCard({
    required this.title,
    required this.leftName,
    required this.leftLabel,
    required this.leftValue,
    required this.rightName,
    required this.rightLabel,
    required this.rightValue,
  });

  final String title;
  final String leftName;
  final String leftLabel;
  final double leftValue;
  final String rightName;
  final String rightLabel;
  final double rightValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final leftWins = leftValue > rightValue;
    final rightWins = rightValue > leftValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _LogBarRow(
              name: leftName,
              rawLabel: leftLabel,
              fraction: kiBarFraction(leftValue),
              color: leftWins ? scheme.primary : scheme.secondary,
              isWinner: leftWins,
            ),
            const SizedBox(height: 12),
            _LogBarRow(
              name: rightName,
              rawLabel: rightLabel,
              fraction: kiBarFraction(rightValue),
              color: rightWins ? scheme.primary : scheme.secondary,
              isWinner: rightWins,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogBarRow extends StatelessWidget {
  const _LogBarRow({
    required this.name,
    required this.rawLabel,
    required this.fraction,
    required this.color,
    required this.isWinner,
  });

  final String name;
  final String rawLabel;
  final double fraction;
  final Color color;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              rawLabel,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                color: isWinner ? color : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

```

#### C. Add Compare Action to `CharacterScreen` (`lib/character_screen.dart`)

In `CharacterScreen`'s `AppBar.actions` (next to `FavoriteButton`):

```dart
IconButton(
  tooltip: 'Compare power level',
  style: IconButton.styleFrom(
    minimumSize: const Size(minTouchSize, minTouchSize),
  ),
  icon: const Icon(Icons.compare_arrows),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareScreen(initialLeft: character),
      ),
    );
  },
),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `clamp(0.05, 0.96)` for finite `> 0` Ki while `double.infinity` gets `1.0`?** Reserving `0.96` as the ceiling for huge finite numbers (`90 Septillion`) leaves a visible step up to `1.0` for Zeno's `"∞"`, accurately reflecting that infinity still exceeds any finite Septillion value.
* **Why `FractionallySizedBox(widthFactor: fraction)` inside `Align(alignment: Alignment.centerLeft)`?** `FractionallySizedBox` requires an alignment whenever `widthFactor` is less than `1.0`—without `Align(centerLeft)`, Flutter centers the bar inside the track instead of anchoring it to the left edge.

---

### 5. Power Comparison Flow

```text
CharacterScreen (AppBar: compare_arrows) ──▶ CompareScreen(initialLeft: character)
                                                    │
                                 ┌──────────────────┴──────────────────┐
                                 ▼                                     ▼
                       parseKi(left.maxKi)                   parseKi(right.maxKi)
                                 │                                     │
                                 ▼                                     ▼
                       kiBarFraction(leftVal)                kiBarFraction(rightVal)
                                 └──────────────────┬──────────────────┘
                                                    ▼
                                      FractionallySizedBox Log10 Bars

```

---

Say **next** whenever you're ready for **Step 27 — Dynamic `AppZoom` Presets in Settings**!











# Step 27 — Dynamic `AppZoom` Presets in Settings

### 1. Objective

Connect `SettingsScreen`'s zoom selector directly to `maxZoomAllowedFor(realScreenSize)` in `app_zoom.dart` so presets exceeding a narrow device's physical `320dp` minimum viewport width are visually marked as capped (or disabled) instead of letting users tap `125%` and `150%` on a `360dp` phone and wonder why both produce the exact same `112%` zoom.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Handling presets above `maxZoom**` | Keep `zoomPresets` visible, disable chips where `preset > maxAllowed + 0.001` (`onSelected: null`), and show a subtitle explaining the device ceiling (e.g., `"Max 112% on this screen width"`) | Silently deleting presets from the list or letting users select `1.5` while `AppZoom` silently clamps it | Deleting chips makes the UI look incomplete compared to tablets; letting users tap `150%` with zero visual change feels like a broken control. Disabling out-of-range chips with an explicit device-width subtitle communicates the exact physical constraint. |
| **Reading physical viewport size inside `SettingsScreen**` | `View.of(context).physicalSize / View.of(context).devicePixelRatio` | `MediaQuery.sizeOf(context)` inside `SettingsScreen` | `MediaQuery.sizeOf(context)` inside `SettingsScreen` returns the **already-zoomed virtual viewport** created by `AppZoom` above it—creating a feedback loop where zooming out makes the screen look wider! `View.of(context)` always reads the true physical screen size. |
| **Active chip highlight when clamped** | Highlight the preset closest to `effectiveZoom = settings.zoom.clamp(minZoom, maxAllowed)` | Exact equality `settings.zoom == preset` | If a user restores preferences from a tablet (`1.5`) onto a phone (`maxAllowed = 1.125`), exact equality highlights zero chips. Matching the nearest valid preset keeps the active selection clear. |

---

### 3. Delta Changes

#### A. Add Preset Filtering Helper in `lib/app_zoom.dart`

```dart
/// Returns the effective zoom after clamping to the physical viewport's 320dp floor.
double effectiveZoomFor(double requestedZoom, Size physicalLogicalSize) {
  final maxAllowed = maxZoomAllowedFor(physicalLogicalSize);
  return requestedZoom.clamp(minZoom, maxAllowed);
}

```

#### B. Update Zoom Section in `lib/settings_screen.dart`

Inside `SettingsScreen.build(BuildContext context)`:

```dart
final view = View.of(context);
final physicalLogicalSize = view.physicalSize / view.devicePixelRatio;
final maxAllowed = maxZoomAllowedFor(physicalLogicalSize);
final effectiveZoom = effectiveZoomFor(settings.zoom, physicalLogicalSize);

```

Render the zoom `ChoiceChip` wrap with dynamic availability and a helper caption:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final preset in zoomPresets)
      Builder(
        builder: (context) {
          final isSupported = preset <= maxAllowed + 0.001;
          final isSelected = (effectiveZoom - preset).abs() < 0.01 ||
              (!isSupported &&
                  preset == zoomPresets.firstWhere((p) => p > maxAllowed, orElse: () => -1) &&
                  (effectiveZoom - maxAllowed).abs() < 0.01 &&
                  !zoomPresets.any((p) => p <= maxAllowed + 0.001 && (effectiveZoom - p).abs() < 0.01));

          return ChoiceChip(
            label: Text('${(preset * 100).round()}%'),
            selected: isSelected,
            onSelected: isSupported
                ? (_) => ref.read(settingsProvider.notifier).setZoom(preset)
                : null,
          );
        },
      ),
  ],
),
if (maxAllowed < zoomPresets.last - 0.001)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'Capped at ${(maxAllowed * 100).floor()}% to keep at least ${minVirtualWidth.round()}dp width on this screen.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `View.of(context)` vs. `MediaQuery.of(context)` matters here:** `AppZoom` sits in `MaterialApp.builder` *above* every route in `Navigator`, overriding `MediaQueryData.size` to `realSize / zoom`. Any widget below `AppZoom` (including `SettingsScreen`) that calls `MediaQuery.sizeOf(context)` sees the scaled virtual size rather than the hardware display—`View.of(context)` queries the underlying `FlutterView` directly, bypassing `AppZoom`'s `MediaQuery` override.
* **Why `+ 0.001` epsilon on floating-point comparisons (`preset <= maxAllowed + 0.001`)?** Dividing `360.0 / 320.0` produces `1.125`, while other screen widths (like `384.0 / 320.0`) can yield repeating binary fractions—an epsilon prevents valid boundary presets from being accidentally disabled due to IEEE-754 rounding.

---

### 5. Viewport Constraint Flow

```text
FlutterView (View.of(context))
       │
       ▼  physicalSize / devicePixelRatio
True Logical Screen Size (e.g., 360dp × 800dp)
       │
       ▼  maxZoomAllowedFor() ──▶ 360 / 320 = 1.125 (112%)
SettingsScreen ChoiceChips
 ├── 75%, 90%, 100% ──▶ Enabled (preset <= 1.125)
 └── 115%, 125%, 150% ──▶ Disabled + Caption: "Capped at 112%..."

```

---

Say **next** whenever you're ready for **Step 28 — Native Share Sheet Integration**!










# Step 28 — Native Share Sheet Integration

### 1. Objective

Add a **Share** action to `CharacterScreen`'s `AppBar` using `share_plus` so users can invoke the native OS share sheet (Android, iOS, macOS, Windows, Web) with a clean, formatted character profile card (name, race, base/max Ki, affiliation, summary, and artwork link) plus clipboard fallback if sharing is unavailable.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Share payload format** | Pure `formatCharacterShareText(Character c, {Planet? originPlanet})` helper returning a concise, multi-line summary + image URL | Sharing raw JSON or downloading & attaching local PNG files on tap | Text + artwork URL executes instantaneously with zero network/disk I/O delay, works offline, requires zero extra storage permissions, and allows `formatCharacterShareText` to be unit tested directly. |
| **Share plugin** | Official Flutter Community `share_plus` (`SharePlus.instance.share(ShareParams(...))`) | Manual `MethodChannel` per platform or `Clipboard.setData` only | `share_plus` invokes native `Intent.ACTION_SEND` on Android, `UIActivityViewController` on iOS/macOS, and `navigator.share` on Web out of the box. |
| **iPad / macOS popover anchor** | Pass `sharePositionOrigin` computed from the button's `RenderBox` | Calling `SharePlus.instance.share(...)` with `sharePositionOrigin: null` | On iPadOS and macOS, omitting `sharePositionOrigin` throws a platform exception (`UIActivityViewController` requires an anchor `CGRect` on tablet/desktop viewports). |

---

### 3. Delta Changes

#### A. Install `share_plus`

```bash
flutter pub add share_plus

```

#### B. Add Pure Share Formatter (`lib/models.dart` or `lib/character_screen.dart`)

```dart
String formatCharacterShareText(
  Character character, {
  Planet? originPlanet,
}) {
  final buffer = StringBuffer()
    ..writeln('${character.name} (${character.race})')
    ..writeln('Base Ki: ${character.ki} | Max Ki: ${character.maxKi}')
    ..writeln('Affiliation: ${character.affiliation}');

  if (originPlanet != null) {
    buffer.writeln('Origin Planet: ${originPlanet.name}');
  }

  final bio = character.description.trim();
  if (bio.isNotEmpty) {
    final snippet = bio.length > 180 ? '${bio.substring(0, 177)}...' : bio;
    buffer
      ..writeln()
      ..writeln(snippet);
  }

  if (character.image.isNotEmpty) {
    buffer
      ..writeln()
      ..write(character.image);
  }

  return buffer.toString().trim();
}

```

#### C. Add Share Button to `CharacterScreen` (`lib/character_screen.dart`)

Inside `CharacterScreen`'s `AppBar.actions`:

```dart
Builder(
  builder: (buttonContext) => IconButton(
    tooltip: 'Share character',
    style: IconButton.styleFrom(
      minimumSize: const Size(minTouchSize, minTouchSize),
    ),
    icon: const Icon(Icons.share_outlined),
    onPressed: () async {
      final box = buttonContext.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      final extras = ref.read(characterExtrasProvider(character.id)).valueOrNull;
      final text = formatCharacterShareText(
        character,
        originPlanet: extras?.originPlanet,
      );

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: '${character.name} — Dragon Ball Universe',
          sharePositionOrigin: origin,
        ),
      );
    },
  ),
),

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `Builder(builder: (buttonContext) => ...)` wraps the `IconButton`:** Calling `context.findRenderObject()` on `CharacterScreen`'s outer `BuildContext` returns the whole screen's `RenderBox`, placing the iPad/macOS popover arrow at `(0, 0)` top-left. Wrapping the button in `Builder` gives `buttonContext` scoped specifically to the `IconButton` so `localToGlobal(Offset.zero) & box.size` anchors the share popover right under the share icon.
* **Why `ref.read(characterExtrasProvider(character.id)).valueOrNull` instead of `await`ing the future:** If `originPlanet` has already finished loading, `.valueOrNull` includes it immediately; if the network is slow or offline, it falls back gracefully to `null` instead of blocking the share sheet behind an extra spinner.

---

### 5. Share Invocation Flow

```text
User taps Share icon in CharacterScreen AppBar
       │
       ├──▶ buttonContext.findRenderObject() ──▶ Rect anchor (for iPadOS / macOS)
       ├──▶ characterExtrasProvider(id).valueOrNull ──▶ Optional originPlanet
       └──▶ formatCharacterShareText() ──▶ SharePlus.instance.share() ──▶ Native OS Share Sheet

```

---

Say **next** whenever you're ready for **Step 29 — Unit Tests for Pure Domain Logic**!











# Step 29 — Unit Tests for Pure Domain Logic

### 1. Objective

Lock in the most delicate pure-Dart logic across your codebase—`ki_parser.dart` (`parseKi`, `powerOf`, `kiBarFraction`), `app_zoom.dart` (`maxZoomAllowedFor`, `effectiveZoomFor`), `models.dart` (`Character.fromJson`, `Planet.fromJson`, `toJson` round-trips), and `OfflineCache`—with fast, deterministic unit tests in `test/` that run in under a second without an emulator or network connection.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Test runner & assertions** | Standard `flutter_test` (`group`, `test`, `expect`, `closeTo`) | Adding external assertion libraries (`matcher`, `shouldly`) | Built into every Flutter project with zero extra dependencies; `closeTo(expected, delta)` handles IEEE-754 floating-point math cleanly. |
| **Mocking `SharedPreferences**` | `SharedPreferences.setMockInitialValues({...})` + `await SharedPreferences.getInstance()` | Writing a fake `SharedPreferences` implementation class with 25 boilerplate methods | `shared_preferences` ships an official in-memory mock store for tests that exercises your real `OfflineCache` and `SettingsNotifier` persistence logic end-to-end. |
| **File organization** | Mirror `lib/` modules in `test/` (`ki_parser_test.dart`, `app_zoom_test.dart`, `models_and_cache_test.dart`) | One monolithic `widget_test.dart` | Keeps failures pinpointed to the exact module and lets you run a single file (`flutter test test/ki_parser_test.dart`) during refactors. |

---

### 3. Delta Changes

#### A. Create `test/ki_parser_test.dart`

```dart
import 'package:dragonball_learning/ki_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseKi', () {
    test('parses plain comma-separated numbers', () {
      expect(parseKi('60.000.000'), 60000000);
      expect(parseKi('1,500'), 1500);
      expect(parseKi('0'), 0);
    });

    test('parses named magnitude suffixes accurately', () {
      expect(parseKi('3 Billion'), 3e9);
      expect(parseKi('90 Septillion'), 90e24);
      expect(parseKi('1.5 Quintillion'), 1.5e18);
    });

    test('handles infinity and unknown strings safely', () {
      expect(parseKi('∞'), double.infinity);
      expect(parseKi('Infinity'), double.infinity);
      expect(parseKi('Unknown'), -1);
      expect(parseKi(''), -1);
    });
  });

  group('kiBarFraction', () {
    test('maps edge cases and logarithmic orders of magnitude', () {
      expect(kiBarFraction(-1), 0.0);
      expect(kiBarFraction(0), 0.0);
      expect(kiBarFraction(double.infinity), 1.0);

      final low = kiBarFraction(1e3);   // 1,000
      final mid = kiBarFraction(1e12);  // 1 Trillion
      final high = kiBarFraction(9e25); // 90 Septillion

      expect(low, lessThan(mid));
      expect(mid, lessThan(high));
      expect(high, lessThanOrEqualTo(0.96));
    });
  });
}

```

#### B. Create `test/app_zoom_test.dart`

```dart
import 'dart:ui';
import 'package:dragonball_learning/app_zoom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppZoom viewport math', () {
    test('caps zoom on narrow phones to preserve 320dp minimum width', () {
      // 360dp / 320dp = 1.125 max zoom
      expect(maxZoomAllowedFor(const Size(360, 800)), closeTo(1.125, 0.001));
      expect(effectiveZoomFor(1.5, const Size(360, 800)), closeTo(1.125, 0.001));
    });

    test('allows full 1.5x preset on tablets and desktops', () {
      expect(maxZoomAllowedFor(const Size(1024, 768)), 1.5);
      expect(effectiveZoomFor(1.5, const Size(1024, 768)), 1.5);
    });

    test('never allows zoom below minZoom (0.75)', () {
      expect(maxZoomAllowedFor(const Size(280, 600)), minZoom);
      expect(effectiveZoomFor(0.5, const Size(400, 800)), minZoom);
    });
  });
}

```

#### C. Create `test/models_and_cache_test.dart`

```dart
import 'package:dragonball_learning/models.dart';
import 'package:dragonball_learning/offline_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Character & Planet JSON serialization', () {
    test('falls back safely when nullable API fields are missing', () {
      final char = Character.fromJson({'id': 1.0, 'name': 'Goku'});
      expect(char.id, 1);
      expect(char.name, 'Goku');
      expect(char.race, 'Unknown');
      expect(char.ki, 'Unknown');
    });

    test('survives toJson -> fromJson round-trip losslessly', () {
      const original = Character(
        id: 2,
        name: 'Vegeta',
        ki: '54.000.000',
        maxKi: '19.84 Septillion',
        race: 'Saiyan',
        gender: 'Male',
        description: 'Prince of all Saiyans',
        image: 'https://example.com/vegeta.png',
        affiliation: 'Z Fighter',
      );

      final restored = Character.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.maxKi, original.maxKi);
      expect(restored.affiliation, original.affiliation);
    });
  });

  group('OfflineCache', () {
    test('persists, reads, and clears characters without wiping other keys', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_ids': ['1', '2'],
      });
      final prefs = await SharedPreferences.getInstance();
      final cache = OfflineCache(prefs);

      expect(cache.readCharacters(), isNull);

      await cache.saveCharacters(const [
        Character(
          id: 1,
          name: 'Goku',
          ki: '60.000.000',
          maxKi: '90 Septillion',
          race: 'Saiyan',
          gender: 'Male',
          description: 'Earth hero',
          image: 'https://example.com/goku.png',
          affiliation: 'Z Fighter',
        ),
      ]);

      final loaded = cache.readCharacters();
      expect(loaded, isNotNull);
      expect(loaded!.single.name, 'Goku');
      expect(cache.lastUpdated, isNotNull);

      await cache.clear();
      expect(cache.readCharacters(), isNull);
      expect(prefs.getStringList('favorite_ids'), ['1', '2']);
    });
  });
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why `expect(prefs.getStringList('favorite_ids'), ['1', '2'])` is asserted after `cache.clear()`:** This regression test proves Step 22's contract—clearing cached JSON snapshots never accidentally wipes user favorites.
* **Why pure functions make testing effortless:** Because `parseKi`, `kiBarFraction`, `maxZoomAllowedFor`, and `Character.fromJson` take plain Dart types (`String`, `double`, `Size`, `Map`) and never import `BuildContext`, you don't need `tester.pumpWidget()` or mock HTTP servers to verify your core business math.

---

### 5. Test Execution Flow

```text
flutter test
 ├── test/ki_parser_test.dart          ──▶ Verifies suffixes (Billion..Septillion), ∞, & log10 bars
 ├── test/app_zoom_test.dart           ──▶ Verifies 320dp floor clamping on narrow vs. wide screens
 └── test/models_and_cache_test.dart   ──▶ Verifies null-safe fromJson, round-trip, & isolated cache clear

```

---

Say **next** whenever you're ready for the final step: **Step 30 — Widget & Golden Tests with Riverpod Overrides**!










# Step 30 — Widget Tests with Riverpod Overrides

### 1. Objective

Verify your end-to-end UI flows—tab-scoped search filtering (`HomeScreen`), favorite toggling persistence (`FavoritesNotifier`), and offline fallback banners (`isOfflineProvider`)—inside `test/widget_test.dart` using `ProviderScope(overrides: [...])` and `http.testing.MockClient` so tests execute deterministically with zero live network calls.

---

### 2. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Injecting fake data into UI tests** | Override `sharedPreferencesProvider` + `apiProvider` (backed by `MockClient` from `package:http/testing.dart`) inside `ProviderScope(overrides: [...])` | Overriding `charactersProvider` directly with static lists | Overriding at the lowest boundary (`apiProvider` + `sharedPreferencesProvider`) exercises the **entire Riverpod DAG** (`DragonBallApi` → `OfflineCache` → `charactersProvider` → `visibleCharactersProvider` → `HomeScreen`) in a single test without touching the internet. |
| **Avoiding `CachedNetworkImage` HTTP timers in tests** | `NetworkPicture` gracefully renders `fallbackIcon` when image URLs are empty (`url: ''`) in fixture models | Spinning up an `HttpOverrides` mock image server for every test | Passing `image: ''` in test fixtures hits `NetworkPicture`'s fast-path fallback icon immediately, eliminating pending network timers that cause `flutter_test` to fail with `"A Timer is still pending"`. |
| **Pump strategy** | `await tester.pumpWidget(...)` followed by `await tester.pumpAndSettle()` | Single `await tester.pump()` | `charactersProvider` and `planetsProvider` resolve asynchronously across microtasks; `pumpAndSettle()` advances frames until `AsyncList` finishes transitioning from `CircularProgressIndicator` to `CardGrid`. |

---

### 3. Delta Changes (`test/widget_test.dart`)

```dart
import 'dart:convert';
import 'package:dragonball_learning/api.dart';
import 'package:dragonball_learning/home_screen.dart';
import 'package:dragonball_learning/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  final sampleCharactersPayload = jsonEncode({
    'items': [
      {
        'id': 1,
        'name': 'Goku',
        'ki': '60.000.000',
        'maxKi': '90 Septillion',
        'race': 'Saiyan',
        'gender': 'Male',
        'description': 'Earth protector',
        'image': '',
        'affiliation': 'Z Fighter',
      },
      {
        'id': 2,
        'name': 'Piccolo',
        'ki': '2.000.000',
        'maxKi': '1.5 Quintillion',
        'race': 'Namekian',
        'gender': 'Male',
        'description': 'Namekian warrior',
        'image': '',
        'affiliation': 'Z Fighter',
      },
    ],
    'meta': {'totalPages': 1, 'totalItems': 2},
  });

  final samplePlanetsPayload = jsonEncode({
    'items': [
      {
        'id': 1,
        'name': 'Namek',
        'isDestroyed': true,
        'description': 'Homeworld of the Namekians',
        'image': '',
      },
    ],
    'meta': {'totalPages': 1, 'totalItems': 1},
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestableHome({required MockClient mockClient}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiProvider.overrideWithValue(DragonBallApi(client: mockClient)),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('scopes search per tab and persists toggled favorites', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/characters')) {
        return http.Response(sampleCharactersPayload, 200);
      }
      if (request.url.path.endsWith('/planets')) {
        return http.Response(samplePlanetsPayload, 200);
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(buildTestableHome(mockClient: mockClient));
    await tester.pumpAndSettle();

    // 1. Both characters render initially
    expect(find.text('Goku'), findsOneWidget);
    expect(find.text('Piccolo'), findsOneWidget);

    // 2. Filter Characters tab to "Goku"
    await tester.enterText(find.byType(SearchBar).first, 'Goku');
    await tester.pumpAndSettle();
    expect(find.text('Goku'), findsOneWidget);
    expect(find.text('Piccolo'), findsNothing);

    // 3. Switch to Planets tab — search must NOT leak from Characters tab
    await tester.tap(find.text('Planets'));
    await tester.pumpAndSettle();
    expect(find.text('Namek'), findsOneWidget);

    // 4. Switch back to Characters, favorite Goku, and verify Favorites tab
    await tester.tap(find.text('Characters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pumpAndSettle();

    expect(prefs.getStringList('favorite_ids'), ['1']);

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Goku'), findsOneWidget);
  });

  testWidgets('falls back to OfflineCache and shows offline banner on network error', (tester) async {
    // Seed offline snapshot before launching widget
    await prefs.setString(
      'cache_characters_v1',
      jsonEncode([
        {
          'id': 1,
          'name': 'Goku',
          'ki': '60.000.000',
          'maxKi': '90 Septillion',
          'race': 'Saiyan',
          'gender': 'Male',
          'description': 'Cached hero',
          'image': '',
          'affiliation': 'Z Fighter',
        },
      ]),
    );

    final failingClient = MockClient((_) async => throw Exception('No internet'));

    await tester.pumpWidget(buildTestableHome(mockClient: failingClient));
    await tester.pumpAndSettle();

    expect(find.text('Offline mode — showing saved data'), findsOneWidget);
    expect(find.text('Goku'), findsOneWidget);
  });
}

```

---

### 4. Engineering Insights (Why Each Piece Exists)

* **Why constructor-injecting `client` into `DragonBallApi({http.Client? client})` pays off here:** Because `DragonBallApi` accepts an optional `http.Client` (defaulting to `http.Client()` in production), tests can inject `MockClient` without subclassing or rewriting any API parsing logic.
* **Why `find.byTooltip('Add to favorites')` is more resilient than `find.byIcon(Icons.favorite_border)`:** Querying by accessibility `tooltip` simultaneously verifies Step 20's accessibility semantics *and* continues passing even if you later swap the heart icon asset.
* **Why overriding `sharedPreferencesProvider` is the key to Riverpod testability:** Because `settingsProvider`, `favoritesProvider`, and `offlineCacheProvider` all read `sharedPreferencesProvider`, overriding that single root provider automatically isolates every state mutation to an in-memory `SharedPreferences` map for each test case.

---

### 5. Complete 30-Step Test & Dependency Harness

```text
ProviderScope(overrides: [
  sharedPreferencesProvider ──▶ In-memory SharedPreferences (setMockInitialValues)
  apiProvider               ──▶ DragonBallApi(client: MockClient)
])
       │
       ▼
MaterialApp(home: HomeScreen())
 ├── Test 1: Characters search ("Goku") ──▶ Planets unaffected ("Namek") ──▶ Favorite persisted
 └── Test 2: MockClient throws error    ──▶ OfflineCache hit + "Offline mode" MaterialBanner

```

---

All **30 steps** of the Dragon Ball Flutter architecture—from initial `main.dart` setup through offline caching, shared-element transitions, logarithmic power comparison, and full Riverpod unit/widget testing—are now complete!






Yes—across your **16 `lib/` files** and the **30-step roadmap**, your architecture is complete, cohesive, and production-ready.

### Architecture & File Coverage Audit

| Layer | Files | Responsibility & Status |
| --- | --- | --- |
| **App Shell & Viewport** | `main.dart`, `theme.dart`, `app_zoom.dart`, `splash_screen.dart` | Root `ProviderScope`, Material 3 + AMOLED dark theme, virtual viewport scaling (`320dp` minimum floor), and animated boot transition. |
| **Data & Offline Cache** | `models.dart`, `api.dart`, `image_cache.dart` (+ `offline_cache.dart` from Step 21) | Null-safe `fromJson` / `toJson`, paginated REST client with typed `ApiException`s, 14-day image disk cache (`imageCacheManager`), and `SharedPreferences` JSON fallback. |
| **Reactive State** | `providers.dart`, `explore_providers.dart`, `settings.dart` | Unidirectional Riverpod graph (`charactersProvider`, `planetsProvider`, tab-scoped search, multi-facet `ExploreSelection`, favorites, and persisted settings). |
| **Screens & Shared UI** | `home_screen.dart`, `explore_screen.dart`, `character_screen.dart`, `settings_screen.dart`, `full_screen_image_viewer.dart`, `widgets.dart` (+ `compare_screen.dart` from Step 26) | Responsive `CardGrid`, `Hero` transitions, bi-directional Planet ↔ Character sheets, pinch-to-zoom viewer, logarithmic Ki VS comparison, share sheet, and cache controls. |
| **Verification** | `test/ki_parser_test.dart`, `test/app_zoom_test.dart`, `test/models_and_cache_test.dart`, `test/widget_test.dart` | Pure-domain unit tests and `MockClient` + `ProviderScope` widget tests covering offline fallback and tab isolation. |

### Final Pre-Release Verification Checklist

Before cutting a release build (`flutter build apk --release` / `flutter build ipa`), run these three final commands in your project root to confirm zero regressions across all 16 files:

1. **Static Analysis:** `flutter analyze` (verifies zero warnings, unused imports, or dead code across `lib/` and `test/`).
2. **Test Suite:** `flutter test` (confirms all unit and widget tests pass deterministically).
3. **Release Network Check:** Verify `android/app/src/main/AndroidManifest.xml` explicitly declares `<uses-permission android:name="android.permission.INTERNET" />` (debug mode injects it automatically, while release APKs require it explicitly).





Looking back across the 16 files and the 30-step progression, there are three architectural refinements worth tightening—especially when targeting **Flutter Web on Cloudflare Pages**:

### 1. What Could Be Improved in the Codebase

1. **Web-Safe Image Caching (`image_cache.dart`):** `flutter_cache_manager` relies on `path_provider` + `sqflite` / local file IO under the hood, which either no-ops or hits IndexedDB quirks on Flutter Web while the browser's own HTTP cache already handles `CachedNetworkImage`. Splitting `image_cache.dart` with conditional imports (`image_cache_io.dart` vs. `image_cache_web.dart` returning `null` for `cacheManager`) keeps Web builds lean and avoids mobile-only disk cache overhead on browsers.
2. **Typed `ki_parser.dart` & Pagination Concurrency (`api.dart`):**
* In `api.dart`, fetching all pages sequentially (`for (int page = 2; page <= totalPages; page++)`) waits for each round-trip one by one. After page 1 returns `totalPages`, fetching pages `2..totalPages` concurrently with `Future.wait(...)` cuts cold-start load time from ~6 serial round-trips down to 2.
* For `ki_parser.dart`, `double` loses integer precision above $2^{53}$ ($\approx 9 \times 10^{15}$, i.e., Quadrillion+), which is fine for sorting and log bars, though storing a lightweight `KiValue` class (`raw`, `numeric`, `isInfinite`) avoids magic `-1` sentinel checks scattered across `explore_providers.dart` and `compare_screen.dart`.


3. **Declarative URL Routing (`go_router` or `onGenerateRoute`) for Web:** On Android/iOS, imperative `Navigator.push` works seamlessly. On Flutter Web, browser Back/Forward buttons and shareable deep links (`/character/1`, `/compare`) work much more naturally when routes map to URL paths instead of anonymous `MaterialPageRoute`s.

---

### 2. How to Deploy to Cloudflare Pages (Static Hosting)

Flutter compiles to a static HTML/JS/Wasm bundle (`build/web`) with zero server-side runtime required, making it a native fit for Cloudflare Pages.

#### Step 1: Build the Production Web Bundle Locally

In your project root, run:

```bash
flutter build web --release

```

*(Optional: add `--wasm` if all your dependencies support WasmGC, or stick with the default JS/CanvasKit build for maximum compatibility with `shared_preferences` and `cached_network_image`.)*

This outputs static assets to `build/web/`.

#### Step 2: Configure Single-Page App (SPA) Redirects

Cloudflare Pages serves static files by path. Create a file named `_redirects` inside `web/` (so `flutter build web` copies it straight into `build/web/_redirects`) with:

```text
/*    /index.html   200

```

This ensures refreshing any deep route returns `index.html` with a `200` status instead of a Cloudflare `404` page.

#### Step 3: Deploy via Wrangler CLI (Fastest Direct Upload)

1. Install or run Cloudflare's Wrangler CLI:
```bash
npx wrangler login

```


2. Create the project once and deploy `build/web`:
```bash
npx wrangler pages deploy build/web --project-name=dragonball-universe

```


Cloudflare outputs a live `*.pages.dev` HTTPS URL immediately.

#### Alternative: Git-Connected Auto-Deploys (GitHub / GitLab)

If you push the repo to GitHub and connect it in **Cloudflare Dashboard → Workers & Pages → Create → Pages → Connect to Git**:

* **Build command:**
```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 && ./flutter/bin/flutter build web --release

```


* **Build output directory:** `build/web`

#### Web-Specific Sanity Check After Deploying

* **CORS on Dragon Ball API:** `dragonball-api.com` sends permissive CORS headers (`Access-Control-Allow-Origin: *`) for JSON `GET` requests, so `http.get` works directly from `*.pages.dev`. If any character PNG host blocks CanvasKit WebGL texture reads (`ImageCodecException` / CORS image error), deploy with `--web-renderer html` or proxy images through a lightweight Cloudflare Pages Function (`/functions/img.js`).





Both of these upgrades work across **Android, iOS, macOS, Windows, Linux, and Web** from a single codebase: Dart conditional imports compile natively on mobile/desktop while cleanly excluding file-system caching on Web, and `go_router` unifies mobile `Navigator` stacks with browser URL history and deep links.

---

### Part 1 — Web-Safe Conditional Image Caching (`image_cache.dart`)

#### 1. How Dart Conditional Imports Work

Dart resolves `import 'a.dart' if (dart.library.io) 'b.dart'` at compile time:

* **Android, iOS, macOS, Windows, Linux** have `dart:io` → compiles `image_cache_io.dart` (uses `flutter_cache_manager` + 14-day disk cache).
* **Flutter Web** lacks `dart:io` → compiles `image_cache_web.dart` (returns `null` so `CachedNetworkImage` delegates straight to the browser's native HTTP cache).

#### 2. Create `lib/image_cache_web.dart`

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

BaseCacheManager? get platformImageCacheManager => null;

Future<void> clearPlatformImageCache() async {
  // Browsers manage HTTP image cache natively; PaintingBinding clears in-memory bitmaps.
}

```

#### 3. Create `lib/image_cache_io.dart`

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final CacheManager _ioCacheManager = CacheManager(
  Config(
    'dragonball_images_v1',
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 300,
  ),
);

BaseCacheManager? get platformImageCacheManager => _ioCacheManager;

Future<void> clearPlatformImageCache() async {
  await _ioCacheManager.emptyCache();
}

```

#### 4. Update `lib/image_cache.dart` (Barrel & Public API)

```dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'image_cache_web.dart'
    if (dart.library.io) 'image_cache_io.dart' as impl;

BaseCacheManager? get imageCacheManager => impl.platformImageCacheManager;

Future<void> clearDiskImageCache() => impl.clearPlatformImageCache();

```

#### 5. Update Call Sites (`lib/widgets.dart` & `lib/providers.dart`)

* In `lib/widgets.dart`, `CachedNetworkImage` and `CachedNetworkImageProvider` both accept `cacheManager: BaseCacheManager?`—passing `cacheManager: imageCacheManager` works identically on mobile (`CacheManager`) and Web (`null`).
* In `lib/providers.dart`, update `clearAppCaches` (from Step 22) to call `await clearDiskImageCache();` instead of `await imageCacheManager.emptyCache();`.

---

### Part 2 — Cross-Platform Declarative Routing (`go_router`)

`go_router` works identically on Android, iOS, desktop, and Web—giving mobile users standard swipe-back/system-back navigation while giving Web users clean URLs (`/`, `/character/1`, `/compare`, `/settings`, `/image`) and browser Back/Forward support.

#### 1. Install `go_router`

```bash
flutter pub add go_router

```

#### 2. Create `lib/router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'character_screen.dart';
import 'compare_screen.dart';
import 'full_screen_image_viewer.dart';
import 'home_screen.dart';
import 'models.dart';
import 'providers.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';

class CharacterRouteExtra {
  const CharacterRouteExtra({this.character, this.heroTag});
  final Character? character;
  final String? heroTag;
}

class ImageViewerExtra {
  const ImageViewerExtra({required this.url, required this.title});
  final String url;
  final String title;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onFinished: () => context.go('/'),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'character/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
              final extra = state.extra is CharacterRouteExtra
                  ? state.extra as CharacterRouteExtra
                  : null;

              // Fast path: passed in memory from a card tap
              if (extra?.character != null) {
                return CharacterScreen(
                  character: extra!.character!,
                  heroTag: extra.heroTag,
                );
              }

              // Deep-link / Web refresh path: resolve character from charactersProvider by :id
              return _CharacterDeepLinkLoader(characterId: id);
            },
          ),
          GoRoute(
            path: 'compare',
            builder: (context, state) {
              final initialLeft = state.extra is Character ? state.extra as Character : null;
              return CompareScreen(initialLeft: initialLeft);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'image',
            builder: (context, state) {
              final extra = state.extra is ImageViewerExtra
                  ? state.extra as ImageViewerExtra
                  : ImageViewerExtra(
                      url: state.uri.queryParameters['url'] ?? '',
                      title: state.uri.queryParameters['title'] ?? 'Artwork',
                    );
              return FullScreenImageViewer(url: extra.url, title: extra.title);
            },
          ),
        ],
      ),
    ],
  );
});

/// Handles direct URL entry on Web (e.g. refreshing /character/1) when state.extra is null.
class _CharacterDeepLinkLoader extends ConsumerWidget {
  const _CharacterDeepLinkLoader({required this.characterId});
  final int characterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charsAsync = ref.watch(charactersProvider);
    return charsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load character: $err')),
      ),
      data: (list) {
        final match = list.firstWhere(
          (c) => c.id == characterId,
          orElse: () => list.first,
        );
        return CharacterScreen(character: match);
      },
    );
  }
}

```

#### 3. Wire `MaterialApp.router` in `lib/main.dart`

Replace `MaterialApp(...)` with `MaterialApp.router(...)` while keeping your `AppZoom` wrapper inside `builder:` intact:

```dart
final router = ref.watch(routerProvider);

return MaterialApp.router(
  debugShowCheckedModeBanner: false,
  title: 'Dragon Ball Universe',
  theme: buildLightTheme(),
  darkTheme: buildDarkTheme(amoled: settings.amoledDark),
  themeMode: settings.themeMode,
  routerConfig: router,
  builder: (context, child) => AppZoom(
    zoom: settings.zoom,
    child: child ?? const SizedBox.shrink(),
  ),
);

```

#### 4. Update Navigation Calls Across Screens

* **Open Character (`lib/widgets.dart`):**
```dart
void openCharacter(BuildContext context, Character character, {String? heroTag}) {
  context.push(
    '/character/${character.id}',
    extra: CharacterRouteExtra(character: character, heroTag: heroTag),
  );
}

```


* **Open Settings (`lib/home_screen.dart`):** `context.push('/settings');`
* **Open Compare (`lib/character_screen.dart`):** `context.push('/compare', extra: character);`
* **Open Full-Screen Image (`lib/character_screen.dart` & `lib/widgets.dart`):**
```dart
context.push(
  '/image?url=${Uri.encodeComponent(url)}&title=${Uri.encodeComponent(title)}',
  extra: ImageViewerExtra(url: url, title: title),
);

```



---

### Why This Solves Both Mobile & Web Cleanly

| Scenario | Behavior |
| --- | --- |
| **Tap card on Android / iOS / Web** | Passes `CharacterRouteExtra` in memory—instant transition with `Hero` animation intact and URL updated to `/character/1`. |
| **Refresh browser on `/character/1` or share link** | `state.extra` is `null` after page reload; `_CharacterDeepLinkLoader` reads `:id` from the URL path, resolves Goku from `charactersProvider` (or `OfflineCache`), and renders `CharacterScreen` without crashing. |
| **Android / iOS system Back button or edge swipe** | `context.push(...)` pushes onto the native route stack so `context.pop()` and OS back gestures work identically to `Navigator.push`. |







Updating `api.dart` to fetch remaining pages concurrently replaces a serial waterfall of HTTP requests with a single parallel batch, cutting cold-start API latency from $N$ sequential round-trips down to 2 round-trips (Page 1 for metadata + Pages `2..N` in parallel).

---

### 1. Chosen vs. Alternatives

| Decision | Chosen | Alternative | Why |
| --- | --- | --- | --- |
| **Concurrency primitive** | `Future.wait([for (int p = 2; p <= totalPages; p++) ...])` | Sequential `for` loop with `await` inside, or adding a semaphore queue library | The Dragon Ball API catalog has ~6 pages for characters and ~2 pages for planets—small enough that firing pages `2..totalPages` in one `Future.wait` batch completes in a single round-trip without overwhelming the server or adding dependencies. |
| **Order preservation** | `Future.wait` returns results in the exact index order of the input `List<Future>` | Collecting responses into a shared list inside `.then((_) => items.addAll(...))` | `Future.wait` guarantees deterministic ordering (`page 2`, `page 3`, ..., `page N`) regardless of which network socket finishes first—keeping character IDs sorted identically across launches. |
| **Error handling** | Let `Future.wait` fail fast (`eagerError: true`, the default) so `charactersProvider` cleanly triggers `OfflineCache` fallback or `ApiException` | Swallowing individual page failures and returning a silently truncated list | A partial character catalog breaks filtering and planet cross-links; failing fast lets Step 21's `OfflineCache` fallback serve the full cached snapshot or show the `Retry` banner. |

---

### 2. Refactored Paginated Fetcher in `lib/api.dart`

Extract a single generic `_fetchAllPages<T>` helper inside `DragonBallApi` so both `fetchAllCharacters()` and `fetchAllPlanets()` share the exact same concurrent pagination pipeline:

```dart
Future<List<T>> _fetchAllPages<T>({
  required String path,
  required T Function(Map<String, dynamic> json) fromJson,
  int pageLimit = 20,
}) async {
  // 1. Fetch page 1 first to discover totalPages
  final firstPage = await _getJson('$path?page=1&limit=$pageLimit');
  final firstItems = _extractItems(firstPage, fromJson);
  final totalPages = _extractTotalPages(firstPage);

  if (totalPages <= 1) return firstItems;

  // 2. Fire pages 2..totalPages concurrently in deterministic order
  final remainingPageFutures = <Future<List<T>>>[
    for (int page = 2; page <= totalPages; page++)
      _getJson('$path?page=$page&limit=$pageLimit')
          .then((raw) => _extractItems(raw, fromJson)),
  ];

  final remainingPages = await Future.wait(remainingPageFutures);

  return <T>[
    ...firstItems,
    for (final pageItems in remainingPages) ...pageItems,
  ];
}

```

#### Supporting Parsers & Public Methods in `lib/api.dart`

```dart
List<T> _extractItems<T>(
  dynamic decoded,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final rawList = decoded is Map<String, dynamic>
      ? decoded['items']
      : decoded is List
          ? decoded
          : null;

  if (rawList is! List) return const [];

  return <T>[
    for (final item in rawList)
      if (item is Map<String, dynamic>) fromJson(item),
  ];
}

int _extractTotalPages(dynamic decoded) {
  if (decoded is Map<String, dynamic>) {
    final meta = decoded['meta'];
    if (meta is Map<String, dynamic> && meta['totalPages'] is num) {
      return (meta['totalPages'] as num).toInt();
    }
  }
  return 1;
}

Future<List<Character>> fetchAllCharacters() => _fetchAllPages<Character>(
      path: '/characters',
      fromJson: Character.fromJson,
    );

Future<List<Planet>> fetchAllPlanets() => _fetchAllPages<Planet>(
      path: '/planets',
      fromJson: Planet.fromJson,
    );

```

---

### 3. Engineering Insights (Why Each Piece Exists)

* **Why `limit=20` is passed explicitly in `'$path?page=$page&limit=$pageLimit'`:** Explicit page limits prevent pagination drift if the remote API ever changes its default page size (e.g., from `10` to `20`), ensuring `totalPages` from page 1 always aligns with the slices requested in `2..totalPages`.
* **Why `decoded is List` is still handled in `_extractItems`:** Even though paginated endpoints wrap results in `{"items": [...], "meta": {...}}`, keeping the `decoded is List` branch makes `_fetchAllPages` immune to endpoints that return a flat JSON array with no `meta` envelope (`_extractTotalPages` returns `1`, so `Future.wait` is skipped cleanly).
* **Zero changes needed in `test/widget_test.dart`:** Because `_extractTotalPages` returns `1` when `meta['totalPages'] == 1`, existing `MockClient` tests returning a single-page fixture hit the `if (totalPages <= 1) return firstItems;` fast path automatically.

---

### 4. Request Timeline Comparison

```text
Before (Serial):
  Page 1 ──▶ Page 2 ──▶ Page 3 ──▶ Page 4 ──▶ Page 5 ──▶ Page 6   (~6x RTT)

After (Concurrent Future.wait):
  Page 1 ──┬──▶ Page 2 ──┐
           ├──▶ Page 3 ──┤
           ├──▶ Page 4 ──┼──▶ Merged & Ordered List               (~2x RTT)
           ├──▶ Page 5 ──┤
           └──▶ Page 6 ──┘

```







To publish your `go_router`-enabled Flutter Web build cleanly on Cloudflare Pages, configure your SPA routing rules, static cache headers, and `web/index.html` metadata before running the build and deploy commands.

---

### 1. SPA Routing & Security Headers (`web/_redirects` & `web/_headers`)

`flutter build web` copies every file inside `web/` directly into `build/web/`—so placing Cloudflare's configuration files in `web/` ensures they are included automatically on every build.

#### A. Create `web/_redirects`

Without this file, refreshing `/character/1` or `/compare` on Cloudflare Pages returns a `404 Not Found` because no physical `character/1/index.html` file exists on disk.

```text
/*    /index.html   200

```

#### B. Create `web/_headers` (Recommended for Flutter Web Caching)

Flutter Web fingerprints its compiled bundles, while `index.html`, `flutter_bootstrap.js`, and `manifest.json` must never be served stale across deployments:

```text
/index.html
  Cache-Control: no-cache, no-store, must-revalidate

/flutter_bootstrap.js
  Cache-Control: no-cache, no-store, must-revalidate

/version.json
  Cache-Control: no-cache, no-store, must-revalidate

/assets/*
  Cache-Control: public, max-age=31536000, immutable

```

---

### 2. Clean `web/index.html` Configuration

Verify `web/index.html` includes `<base href="$FLUTTER_BASE_HREF">`, proper viewport scaling for `AppZoom`, and clean PWA/social metadata:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0">
  <meta name="description" content="Dragon Ball Universe — Explore characters, planets, transformations, and logarithmic Ki power comparisons.">
  <meta name="theme-color" content="#121212">

  <!-- Open Graph / Link Preview Metadata -->
  <meta property="og:title" content="Dragon Ball Universe">
  <meta property="og:description" content="Explore Dragon Ball characters, origin planets, and logarithmic Ki power levels.">
  <meta property="og:type" content="website">

  <!-- iOS Web App Meta Tags -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Dragon Ball Universe">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <link rel="icon" type="image/png" href="favicon.png">
  <title>Dragon Ball Universe</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>

```

*(Note: Keep `<base href="$FLUTTER_BASE_HREF">` untouched—Flutter's build toolchain replaces `$FLUTTER_BASE_HREF` with `/` at compile time, which `go_router` requires so nested paths like `/character/1` resolve relative asset URLs from the root `/` instead of `/character/assets/...`.)*

---

### 3. Build & Deploy via Wrangler CLI

Run these commands from your Flutter project root:

```bash
# 1. Run static analysis and tests first
flutter analyze
flutter test

# 2. Build the production static web bundle
flutter build web --release

# 3. Verify _redirects and _headers were copied into build/web/
ls -la build/web/_redirects build/web/_headers

# 4. Authenticate Wrangler with your Cloudflare account (opens browser once)
npx wrangler login

# 5. Create the Cloudflare Pages project (run once; skip if already created)
npx wrangler pages project create dragonball-universe --production-branch=main

# 6. Deploy build/web to Cloudflare Pages
npx wrangler pages deploy build/web --project-name=dragonball-universe --branch=main

```

---

### 4. Post-Deploy Verification Checklist

1. **Deep-Link Refresh Test:** Open `[https://dragonball-universe.pages.dev/character/1](https://dragonball-universe.pages.dev/character/1)` directly in a new incognito tab and press **F5 / Reload**—confirm it loads Goku via `_CharacterDeepLinkLoader` with HTTP `200` instead of a `404`.
2. **Browser Navigation Test:** Tap a character card → tap **Compare** → press the browser's native **Back** button twice to confirm `go_router` pops cleanly back to `/`.
3. **CORS / Image Check:** Open DevTools **Network / Console** on the live `*.pages.dev` URL; if any character PNG fails to render in CanvasKit due to remote image host CORS restrictions, rebuild with:
```bash
flutter build web --release --no-web-resources-cdn

```


or add a lightweight Cloudflare Pages Function at `functions/proxy-image.js` to proxy external character images with `Access-Control-Allow-Origin: *`.