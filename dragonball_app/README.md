flutter create --org com.enterprise --platforms=android,ios,macos enterprise_feed
cd enterprise_feed

# Functional types and metadata
flutter pub add meta

# Data layer infrastructure
flutter pub add http path_provider

# State & Dependency Injection (using Riverpod with code-gen)
flutter pub add flutter_riverpod riverpod_annotation

# Dev dependencies for generation and pure Dart testing
flutter pub add dev:build_runner dev:riverpod_generator dev:test



lib/
├── core/
│   ├── errors/failure.dart
│   └── result/result.dart
└── features/
    └── products/
        ├── domain/              <-- PURE DART (No Flutter, no HTTP/Dio)
        │   ├── entities/
        │   ├── value_objects/
        │   └── repositories/
        ├── data/                <-- INFRASTRUCTURE (HTTP, Disk I/O, DTOs)
        │   ├── dtos/
        │   ├── datasources/
        │   └── repositories/
        └── presentation/        <-- FLUTTER FRAMEWORK (Widgets, Notifiers)
            ├── controllers/
            └── views/


flutter build web --release --no-wasm-dry-run --dart-define-from-file=.env && \

flutter build apk --release --dart-define-from-file=.env && \
mkdir -p build/web/download && \
cp build/app/outputs/flutter-apk/app-release.apk build/web/download/dragonball.apk