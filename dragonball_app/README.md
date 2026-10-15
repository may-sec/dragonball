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

    
    main> AndroidManifest.xml
    <!-- ADD THIS LINE: Required for HTTP/HTTPS calls in release APK -->
    <uses-permission android:name="android.permission.INTERNET" />



flutter run -d "POCO M2 Pro" --dart-define-from-file=.env

flutter pub get                                          
dart run flutter_launcher_icons
dart run flutter_native_splash:create


flutter build apk --release --dart-define-from-file=.env && \
mkdir -p web/download && \
cp build/app/outputs/flutter-apk/app-release.apk web/download/dragonball.apk