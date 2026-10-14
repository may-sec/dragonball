
#!/bin/bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-https://dragonball-api.com/api}"

VERSION="$(awk '/^version:/ {print $2; exit}' pubspec.yaml)"

if [ -z "${VERSION}" ]; then
  echo "ERROR: Could not read version from pubspec.yaml"
  exit 1
fi

# Flutter versions use version+buildNumber.
# Replace '+' to produce a safe filename.
SAFE_VERSION="${VERSION//+/-}"

DOWNLOAD_DIR="web/download"
APK_NAME="dragonball-v${SAFE_VERSION}.apk"
APK_PATH="${DOWNLOAD_DIR}/${APK_NAME}"

echo "Building Android APK: ${APK_NAME}"

flutter pub get

flutter build apk \
  --release \
  --dart-define="API_BASE_URL=${API_BASE_URL}"

mkdir -p "${DOWNLOAD_DIR}"

cp \
  build/app/outputs/flutter-apk/app-release.apk \
  "${APK_PATH}"

echo "APK created: ${APK_PATH}"
echo "Remember to commit or upload this release before deploying to Vercel."
