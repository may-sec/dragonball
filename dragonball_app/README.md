You have two sets of Flutter project notes: your Dragon Ball Explorer setup and your newer Enterprise Feed setup. The best approach is to combine them into one development reference while preserving the commands you actually used and highlighting the extra packages, configuration, and implementation details that are easy to forget.

There are two important distinctions to preserve:

- Enterprise Feed uses `riverpod_annotation` and `riverpod_generator` for Riverpod code generation.
- Dragon Ball Explorer also uses Flutter Hooks, image caching, environment configuration, and favorites-related functionality. Those are useful additions, but they are not automatically part of the Enterprise Feed project just because they appeared in the earlier setup.

## Combined setup reference

# Flutter Project Setup — Enterprise Feed / Dragon Ball Explorer

A consolidated reference for Flutter project creation, Riverpod state management, repository architecture, environment configuration, image caching, testing, app assets, and release builds.

## 1. Create the Flutter project

```
flutter create --org com.enterprise --platforms=android,ios,macos enterprise_feed
cd enterprise_feed
```

This creates an app with Android, iOS, and macOS platform folders. Keep these folders when integrating the supplied `lib/`, `test/`, and configuration files.

## 2. Install dependencies

### Core infrastructure

```
flutter pub add meta
flutter pub add http path_provider
```

- `meta`: annotations and metadata utilities.
- `http`: REST API communication.
- `path_provider`: access to platform-specific directories for local files and disk-based caching.

### Riverpod and code generation

```
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add dev:build_runner dev:riverpod_generator dev:test
```

- `flutter_riverpod`: provider-based state management and dependency injection.
- `riverpod_annotation`: annotations for generated providers.
- `build_runner`: executes Dart code-generation builders.
- `riverpod_generator`: generates Riverpod providers.
- `test`: pure Dart unit testing.

Generate the Riverpod files after adding or changing annotated providers:

```
dart run build_runner build --delete-conflicting-outputs
```

For active development, you can use the generator in watch mode:

```
dart run build_runner watch --delete-conflicting-outputs
```

Use the generated `.g.dart` files as required by the source code. The generated files should not be manually edited.

### Additional packages from the Dragon Ball project

```
flutter pub add flutter_hooks hooks_riverpod
flutter pub add cached_network_image
flutter pub add shared_preferences crypto
```

These cover additional capabilities used in the earlier project:

- `flutter_hooks`: lifecycle-aware hooks and local widget state.
- `hooks_riverpod`: Riverpod integration for hook-based widgets.
- `cached_network_image`: cached network images, placeholders, and error widgets.
- `shared_preferences`: lightweight local key-value storage, useful for persisting simple preferences.
- `crypto`: cryptographic hashing and related utilities.

If you are using `hooks_riverpod`, you generally do not need to add `flutter_riverpod` separately as a direct dependency unless your project structure or package usage requires it.

### Choose one environment configuration approach

**Option A — Dart compile-time environment values**

```
flutter run --dart-define-from-file=.env
```

The file passed to `--dart-define-from-file` must contain JSON-formatted key-value pairs, even if it is named `.env`.

Example:

```
{
  "API_BASE_URL": "https://dragonball-api.com/api"
}
```

Read the value in Dart:

```
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://dragonball-api.com/api',
);
```

**Option B — `flutter_dotenv`**

```
flutter pub add flutter_dotenv
```

This package supports conventional `.env` files containing entries such as:

```
API_BASE_URL=https://dragonball-api.com/api
```

Load the file at application startup and register it as an asset in `pubspec.yaml`.

These two approaches are not interchangeable: `--dart-define-from-file` expects JSON, while `flutter_dotenv` parses dotenv syntax. Choose the approach that matches your existing source code.

## 3. Project architecture

```
lib/
├── core/
│   ├── errors/
│   │   └── failure.dart
│   └── result/
│       └── result.dart
│
└── features/
    └── products/
        ├── domain/
        │   ├── entities/
        │   ├── value_objects/
        │   └── repositories/
        │
        ├── data/
        │   ├── dtos/
        │   ├── datasources/
        │   └── repositories/
        │
        └── presentation/
            ├── controllers/
            └── views/
```

### Domain layer — pure Dart

Contains business concepts and rules without Flutter widgets or HTTP implementation details.

- Entities and value objects.
- Repository contracts.
- Business rules and validation.

### Data layer — infrastructure

Implements repository contracts and communicates with external systems.

- DTOs and JSON serialization.
- Remote data sources using HTTP.
- Local data sources and file operations where needed.
- Repository implementations and response mapping.

### Presentation layer — Flutter

Contains the user interface and state-management integration.

- Screens and reusable widgets.
- Riverpod controllers and providers.
- Loading, error, empty, and success states.
- User interactions, filters, pagination, and refresh behavior.

### Shared core

- `Failure` types describe expected errors.
- `Result` types represent successful and failed operations.
- Shared utilities should remain independent of individual feature implementations when practical.

The intended dependency direction is:

```
Presentation → Domain ← Data
```

The data layer implements domain contracts; the domain layer should not import Flutter widgets, HTTP clients, or concrete data implementations.

## 4. Android network permission

In `android/app/src/main/AndroidManifest.xml`, ensure this permission is declared directly inside the `<manifest>` element and outside the `<application>` element:

```
<uses-permission android:name="android.permission.INTERNET" />
```

This allows the Android application to access the network. Verify the merged release manifest if requests work in development but fail in a release build.

## 5. Get dependencies and validate the project

```
flutter pub get
dart format lib test
flutter analyze
flutter test
```

These commands:

1. Resolve package dependencies.
2. Format Dart source files.
3. Run static analysis.
4. Execute the test suite.

For a Flutter application, keep `flutter_test` available for widget tests; the `test` package is primarily for pure Dart tests.

## 6. Run on the development device

The command used previously:

```
flutter run -d "POCO M2 Pro" --dart-define-from-file=.env
```

List available devices if the device name changes:

```
flutter devices
```

Ensure the environment file uses the format expected by the selected configuration method.

## 7. Configure launcher icons and native splash screens

Install the generators as development dependencies if they are not already in `pubspec.yaml`:

```
flutter pub add dev:flutter_launcher_icons
flutter pub add dev:flutter_native_splash
```

Configure their respective sections in `pubspec.yaml` before generating assets.

Generate launcher icons:

```
dart run flutter_launcher_icons
```

Generate native splash-screen resources:

```
dart run flutter_native_splash:create
```

Keep the source icon and splash images in the project and ensure their paths match the configuration.

## 8. Build the release APK and copy it for distribution

The original build and copy command:

```
flutter build apk --release --dart-define-from-file=.env && \
mkdir -p web/download && \
cp build/app/outputs/flutter-apk/app-release.apk web/download/dragonball.apk
```

The commands execute in sequence only if the preceding command succeeds.

The output is copied to `web/download/dragonball.apk`. Note that this filename refers to Dragon Ball, while the project creation command names the app `enterprise_feed`. If this is now an Enterprise Feed app, change the destination filename to avoid distributing the wrong artifact under a misleading name.

For example:

```
flutter build apk --release --dart-define-from-file=.env && \
mkdir -p web/download && \
cp build/app/outputs/flutter-apk/app-release.apk web/download/enterprise_feed.apk
```

The APK is an Android artifact; the same command does not build iOS or macOS releases.

## 9. Dragon Ball Explorer capabilities to carry forward

The earlier Dragon Ball project included these additional features and concepts:

- Character and planet browsing.
- Character search with debouncing.
- Race, gender, affiliation, and planet-status filters.
- Infinite scrolling and pagination.
- Character details, transformations, and origin planets.
- Favorites state.
- Independent character and planet loading and error states.
- Repository injection through Riverpod.
- `FutureProvider.family`, `AsyncNotifierProvider`, `AsyncValue`, and `select`.
- Image caching, preloading, placeholders, and error handling.
- Model parsing and result-type tests.

These are feature-level capabilities rather than automatic consequences of installing the packages. Carry them into the new project only where they match the intended product.

## 10. Final pre-release checklist

- Confirm all dependencies are declared in `pubspec.yaml`.
- Generate and validate all Riverpod `.g.dart` files.
- Confirm the environment file format matches the configuration approach.
- Keep secrets out of client-side configuration files.
- Confirm Android internet permission is present.
- Verify API base URL and response parsing.
- Test loading, empty, error, retry, refresh, and pagination flows.
- Verify local storage behavior if persistence is implemented.
- Configure launcher icons and splash assets.
- Run `dart format`, `flutter analyze`, and `flutter test`.
- Build and test the release APK.
- Confirm the copied APK filename matches the application being distributed.
- Preserve platform-specific project folders and signing configuration.



## Unique things you may have forgotten

These are the details I would keep in a separate checklist because they are easy to miss when rebuilding or moving between projects.

| Item                                  | Why it matters                                                                                                                                           |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Riverpod code generation              | Adding the generator packages is not enough; run `build_runner` and maintain generated provider files.                                                   |
| Flutter Hooks                         | `useState`, `useEffect`, `useMemoized`, and hook-based controllers require the appropriate hooks packages and widget types.                              |
| Environment-file format               | Your `.env` filename is valid for either workflow, but its contents must match the parser you use.                                                       |
| Image cache and preload               | `cached_network_image` helps with repeat loads; explicit preloading and graceful error handling are separate implementation choices.                     |
| Persistent versus in-memory favorites | `shared_preferences` is available for simple persistence, but favorites do not become persistent until you wire it into the state and repository layers. |
| Domain independence                   | Keep HTTP and Flutter-specific dependencies out of pure-Dart domain contracts.                                                                           |
| Launcher and splash generators        | Their commands need matching configuration and image assets in the project.                                                                              |
| Android release networking            | Verify the internet permission in the merged release manifest, not just the source manifest.                                                             |
| Artifact naming                       | `enterprise_feed` and `dragonball.apk` currently describe different project identities.                                                                  |
| Tests                                 | `test` covers pure Dart testing; Flutter widget tests use `flutter_test`.                                                                                |

One final caution: the commands above combine the two projects' recorded setup, not a verified snapshot of your current `pubspec.yaml` or source tree. In particular, check whether the new Enterprise Feed project actually uses `flutter_dotenv`, `shared_preferences`, `crypto`, and image preloading before carrying those dependencies forward.