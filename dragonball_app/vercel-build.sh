#!/bin/bash
set -e

export FLUTTER_ROOT_WARNING=false
export PUB_SUMMARY_ONLY=true

echo "Creating .env file from environment variables..."
cat <<EOF > .env
API_BASE_URL=${API_BASE_URL:-https://dragonball-api.com/api}
EOF

echo "Downloading Flutter SDK..."
if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

export PATH="$PATH:`pwd`/_flutter/bin"

git config --global --add safe.directory "`pwd`/_flutter"

echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

echo "Fetching dependencies..."
flutter pub get

echo "Building release web artifacts..."
flutter build web --release --no-wasm-dry-run