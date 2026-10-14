# Dragon Ball Explorer — Riverpod-first Flutter app

A Dragon Ball catalogue built to practise Riverpod, Flutter Hooks,
asynchronous state, pagination, and repository-based architecture.

## Features

- Character and planet browsing
- Character name search
- Character race, gender, and affiliation filters
- Planet destruction-status filters
- Debounced search
- Infinite scrolling and pagination
- Character detail page with transformations and origin planet
- Planet detail page
- Favorites toggling
- Loading, empty, error, retry, and refresh flows
- Independent character and planet loading/error state
- Riverpod repository injection
- Tests for model parsing and result types

## Architecture

Flutter widget
    -> Riverpod controller/provider
    -> Repository
    -> HTTP client
    -> Dragon Ball API

Responses flow back through the repository and Riverpod to the UI.

## Concepts used

- ProviderScope
- Provider
- NotifierProvider
- AsyncNotifierProvider
- FutureProvider.family
- AsyncValue
- ref.watch
- ref.read
- ref.listen
- select
- useState
- useEffect
- useMemoized
- useTextEditingController
- useScrollController
- Search debouncing
- Immutable state and copyWith
- Result and sealed Failure classes

## Setup

1. Keep your existing Flutter platform folders.
2. Copy the supplied `lib/`, `test/`, `pubspec.yaml`, and
   `analysis_options.yaml` into your project root.
3. Run:

   flutter pub get
   flutter analyze
   flutter test
   flutter run

## API configuration

The default API URL is:

https://dragonball-api.com/api

Override it if needed:

flutter run --dart-define=API_BASE_URL=https://dragonball-api.com/api

## Implementation notes

- This source uses Riverpod without generated provider files.
- Filtered API responses are treated as flat arrays; unfiltered responses
  are expected to use the pagination envelope.
- The API's response format and filter semantics should be verified against
  its current live behavior.
- Favorites are in-memory state in this learning version; they do not persist
  across application restarts.
- Repository errors are represented as Result/Failure values. Detail providers
  convert failures to thrown exceptions so AsyncValue can expose an error state.
- Server authorization and secrets are not handled by this public API demo.