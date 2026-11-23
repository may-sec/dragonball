Aha—I see what you mean! You want **Steps 1 through 10** rewritten into your `README.md` using the **same clean, non-repetitive, delta-only format** (showing only the *new* concept/code introduced at each step, plus `Chosen vs. Alternatives` and `Learned`), so you don't repeat `SliverGridDelegate` or `Card` boilerplate across steps!

Here is your complete, refactored **Steps 1–10** `README.md`—strictly non-repetitive, accurate to your actual codebase, and structured for deep engineering understanding:

```markdown
# Dragon Ball Universe — Flutter Learning Project

## Step 1 — Create the Flutter Project & Entry Point

### Commands
```bash
flutter create dragonball_learning
cd dragonball_learning
flutter run

```

### Initial `lib/main.dart`

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
        body: const Center(child: Text('Welcome to Dragon Ball Universe')),
      ),
    );
  }
}

```

### Chosen vs. Alternatives

* **Chosen:** `MaterialApp` + `Scaffold` directly in `main.dart`.
* **Alternatives:** `CupertinoApp` (iOS-only styling) or `WidgetsApp` (bare canvas with zero Material components or navigation defaults).

### Learned

* `main()` is the Dart entry point; `runApp()` mounts the root widget to Flutter's rendering tree.
* `MaterialApp` provides Material theming and routing; `Scaffold` provides the standard screen skeleton (`appBar`, `body`).

---

## Step 2 — Build a Static Homepage (`GridView.builder`)

### Create `lib/screens/home_screen.dart`

```dart
final List> characters = const [
  {'name': 'Goku', 'race': 'Saiyan'},
  {'name': 'Vegeta', 'race': 'Saiyan'},
  {'name': 'Piccolo', 'race': 'Namekian'},
  {'name': 'Frieza', 'race': 'Frieza Race'},
];

// Inside Scaffold.body:
GridView.builder(
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
                Text(character['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(character['race']!),
              ],
            ),
          ),
        ],
      ),
    );
  },
)

```

### Delta in `lib/main.dart`

* Replaced inline `Scaffold` with `home: HomeScreen()` and added Material 3 `ColorScheme.fromSeed`.

### Chosen vs. Alternatives

* **Chosen:** `GridView.builder` (builds visible items lazily as you scroll).
* **Alternative:** `GridView.count` or `Row`/`Column` lists (instantiates every widget in memory upfront, even off-screen).

### Learned

* `Expanded` gives the image area all remaining vertical space inside a `Column`.
* `clipBehavior: Clip.antiAlias` clips child corners to match the rounded `Card` shape.

---

## Step 3 — Create the `Character` Model

### Create `lib/models/character.dart`

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

### Delta in `HomeScreen`

* Replaced `List>` (`character['name']!`) with `List<Character>` (`character.name`).

### Chosen vs. Alternatives

* **Chosen:** Immutable `Character` class with `final` fields and a `const` constructor.
* **Alternative:** Raw `Map<String, dynamic>` (no autocomplete, runtime key-typo crashes, requires `!` null assertions).

### Learned

* Compile-time type safety eliminates null-assertion (`!`) operators and enforces required fields via `required`.

---

## Step 4 — Make the First API Request

### Add Dependency & Test Request

```bash
flutter pub add http

```

```dart
final uri = Uri.parse('[https://dragonball-api.com/api/characters](https://dragonball-api.com/api/characters)');
final response = await http.get(uri);

```

### Chosen vs. Alternatives

* **Chosen:** Official `http` package (`http.get`).
* **Alternatives:** `dart:io` `HttpClient` (low-level, breaks on Web) or `dio` (heavy dependency for basic REST GETs).

### Learned

* Network calls return a `Future` and use `async`/`await` so the UI thread never freezes while waiting for bytes.

---

## Step 5 — Separate API Service Layer

### Create `lib/services/dragon_ball_api.dart`

```dart
class DragonBallApi {
  static const _baseurl = '[https://dragonball-api.com/api](https://dragonball-api.com/api)';

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

### Chosen vs. Alternatives

* **Chosen:** Dedicated `DragonBallApi` service class in `lib/services/`.
* **Alternative:** Calling `http.get()` directly inside `HomeScreen.initState()` (couples network endpoints and status checks to UI widgets).

### Learned

* Separation of concerns: UI widgets ask for data; the service handles URLs, HTTP calls, and non-200 error throwing.

---

## Step 6 — Parse JSON into `Character` Objects

### Delta in `lib/models/character.dart`

* Expanded `Character` with `ki`, `maxKi`, `description`, `image`, `affiliation`, and added `factory Character.fromJson`:

```dart
factory Character.fromJson(Map<String, dynamic> json) {
  String readString(String key, {String fallback = ''}) {
    final value = json[key];
    return value == null ? fallback : value.toString();
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

```

### Delta in `lib/services/dragon_ball_api.dart`

```dart
final decodedData = jsonDecode(response.body);
final items = decodedData['items'] as List;
return items.map((item) => Character.fromJson(item)).toList();

```

### Flow

```text
JSON String ─▶ jsonDecode() ─▶ decodedData['items'] ─▶ items.map(Character.fromJson) ─▶ List<Character>

```

### Chosen vs. Alternatives

* **Chosen:** Manual `factory Character.fromJson` with a null-safe `readString` helper.
* **Alternative:** `json_serializable` code generation (adds `build_runner` overhead) or direct map indexing `json['race'] as String` (crashes if the API sends `null`).

### Learned

* `factory` constructors can run validation/fallback logic before returning an instance.
* `(json['id'] as num).toInt()` safely handles JSON numbers whether Dart decodes them as `int` or `double`.

---

## Step 7 — Display Real API Data (`FutureBuilder`)

### Delta in `lib/screens/home_screen.dart`

* Converted `HomeScreen` to a `StatefulWidget` and cached the `Future` in `initState()`:

```dart
late Future<List<Character>> _charactersFuture;

@override
void initState() {
  super.initState();
  _charactersFuture = _api.fetchCharacters();
}

```

### Chosen vs. Alternatives

* **Chosen:** `FutureBuilder<List<Character>>` bound to `_charactersFuture`.
* **Alternative:** Manual `_isLoading`, `_error`, and `_characters` flags inside `setState` (more boilerplate state variables to keep in sync).

### Learned

* **Critical rule:** Store `_charactersFuture` in `initState()`, never inside `build()`—otherwise every UI rebuild fires a duplicate HTTP request.

---

## Step 8 — Handle Loading, Error, Empty & Retry States

### Delta in `lib/screens/home_screen.dart`

* Added `_retryFetchCharacters()` and ordered `AsyncSnapshot` guards inside `FutureBuilder`:

```dart
void _retryFetchCharacters() {
  setState(() {
    _charactersFuture = _api.fetchCharacters();
  });
}

// Guard order inside builder:
// 1. snapshot.connectionState == ConnectionState.waiting ─▶ CircularProgressIndicator
// 2. snapshot.hasError ─▶ Error icon + message + ElevatedButton.icon(onPressed: _retryFetchCharacters)
// 3. !snapshot.hasData || snapshot.data!.isEmpty ─▶ 'No characters found.'
// 4. Success ─▶ GridView.builder

```

### Chosen vs. Alternatives

* **Chosen:** Explicit 4-state branching + reassigning `_charactersFuture` inside `setState()` on retry.
* **Alternative:** Returning `[]` on catch inside `DragonBallApi` (silently hides network failures as "No characters found").

### Learned

* Calling `_api.fetchCharacters()` without `setState()` will not notify `FutureBuilder` to listen to the new `Future`.

---

## Step 9 — Extract Reusable `CharacterCard` Widget

### Create `lib/widgets/character_card.dart`

* Moved the `Card` UI out of `HomeScreen`'s `itemBuilder` into `CharacterCard({required this.character})`, replacing the placeholder `Icon` with `Image.network`:

```dart
Image.network(
  character.image,
  fit: BoxFit.cover,
  width: double.infinity,
  errorBuilder: (context, error, stackTrace) {
    return const Center(child: Icon(Icons.broken_image, size: 48));
  },
)

```

### Delta in `HomeScreen`

* `itemBuilder` is now a single line: `CharacterCard(character: characters[index])`.

### Chosen vs. Alternatives

* **Chosen:** Standalone `StatelessWidget` class (`CharacterCard`).
* **Alternative:** Private helper method `Widget _buildCard(...)` inside `_HomeScreenState` (cannot be reused across Favorites or Explore screens).

### Learned

* `Image.network(..., errorBuilder: ...)` prevents broken image URLs from throwing unhandled exceptions or rendering blank gaps.

---

## Step 10 — Character Details Screen & Navigation

### Create `lib/screens/character_details_screen.dart`

* Built `CharacterDetailsScreen({required this.character})` using `SingleChildScrollView` + a reusable `_detailrow(title, value)` helper for stats (`id`, `ki`, `maxKi`, `race`, `gender`, `affiliation`) and `description`.

### Delta in `lib/widgets/character_card.dart`

* Wrapped the card's `Column` in `InkWell`:

```dart
InkWell(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CharacterDetailsScreen(character: character),
      ),
    );
  },
  child: Column( ... ),
)

```

### Navigation Flow

```text
HomeScreen ─▶ CharacterCard (InkWell onTap) ─▶ Navigator.push(MaterialPageRoute) ─▶ CharacterDetailsScreen(character)

```

### Chosen vs. Alternatives

* **Chosen:** Passing the already-loaded `Character` object directly via constructor into `MaterialPageRoute`.
* **Alternative:** Passing only `character.id` and re-fetching from the API on the details screen (adds loading delay for fields we already have).

### Learned

* `Navigator.of(context).push()` pushes a route onto the stack and automatically adds a back button to the new screen's `AppBar`.
* `InkWell` provides Material touch ripple feedback on tap.

---

## Current Progress

| Step | Feature | Status |
| --- | --- | --- |
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
| 11 | Search & In-Memory Filtering | Next |

```

