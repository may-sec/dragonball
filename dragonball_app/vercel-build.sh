
echo "Building Flutter web..."
flutter build web --release --no-wasm-dry-run \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "Building Android APK..."
flutter build apk --release \
  --dart-define=API_BASE_URL="$API_BASE_URL"

echo "Preparing APK download..."
mkdir -p build/web/download

cp build/app/outputs/flutter-apk/app-release.apk \
  build/web/download/dragonball.apk

echo "Web and APK artifacts are ready."
