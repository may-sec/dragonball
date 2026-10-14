
#!/bin/bash
set -euo pipefail

echo "Reading app version from pubspec.yaml..."

VERSION="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"

if [[ -z "${VERSION}" ]]; then
  echo "ERROR: version not found in pubspec.yaml"
  exit 1
fi

# Convert Flutter's version+build format into a filename-safe format.
# Example: 1.0.0+1 -> 1.0.0-1
SAFE_VERSION="${VERSION//+/-}"

APK_NAME="dragonball-v${SAFE_VERSION}.apk"
APK_DIR="web/download"
APK_PATH="${APK_DIR}/${APK_NAME}"

echo "App version: ${VERSION}"
echo "APK filename: ${APK_NAME}"

echo "Building release APK..."

flutter pub get

flutter build apk \
  --release \
  --dart-define-from-file=.env

echo "Copying APK to download directory..."

mkdir -p "${APK_DIR}"

cp \
  build/app/outputs/flutter-apk/app-release.apk \
  "${APK_PATH}"

echo "=========================================="
echo " APK build completed successfully"
echo " Version: ${VERSION}"
echo " Output: ${APK_PATH}"
echo "=========================================="
