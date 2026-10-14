
#!/bin/bash
set -euo pipefail

export FLUTTER_ROOT_WARNING=false
export PUB_SUMMARY_ONLY=true

PROJECT_ROOT="$(pwd)"
FLUTTER_DIR="${PROJECT_ROOT}/_flutter"
SOURCE_DOWNLOAD_DIR="${PROJECT_ROOT}/web/download"
WEB_OUTPUT_DIR="${PROJECT_ROOT}/build/web"
OUTPUT_DOWNLOAD_DIR="${WEB_OUTPUT_DIR}/download"

API_BASE_URL="${API_BASE_URL:-https://dragonball-api.com/api}"

echo "=========================================="
echo " Dragon Ball Universe - Vercel Build"
echo "=========================================="

# --------------------------------------------------
# 1. Create .env for Flutter
# --------------------------------------------------

echo "Creating .env file..."

cat > "${PROJECT_ROOT}/.env" <<EOF
API_BASE_URL=${API_BASE_URL}
EOF

# --------------------------------------------------
# 2. Install Flutter SDK if necessary
# --------------------------------------------------

echo "Checking Flutter SDK..."

if [ ! -d "${FLUTTER_DIR}" ]; then
  echo "Downloading Flutter stable SDK..."

  git clone \
    https://github.com/flutter/flutter.git \
    --depth 1 \
    -b stable \
    "${FLUTTER_DIR}"
else
  echo "Flutter SDK already exists."
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

git config --global --add safe.directory "${FLUTTER_DIR}"

# --------------------------------------------------
# 3. Configure Flutter
# --------------------------------------------------

echo "Configuring Flutter..."

flutter config --no-analytics
flutter config --enable-web

echo "Flutter version:"
flutter --version

# --------------------------------------------------
# 4. Fetch dependencies
# --------------------------------------------------

echo "Fetching Flutter dependencies..."

flutter pub get

# --------------------------------------------------
# 5. Build Flutter web application
# --------------------------------------------------

echo "Building release web artifacts..."

flutter build web \
  --release \
  --no-wasm-dry-run \
  --dart-define="API_BASE_URL=${API_BASE_URL}"

# --------------------------------------------------
# 6. Prepare download directories
# --------------------------------------------------

echo "Preparing APK download directories..."

mkdir -p "${SOURCE_DOWNLOAD_DIR}"
mkdir -p "${OUTPUT_DOWNLOAD_DIR}"

# --------------------------------------------------
# 7. Generate the download page and copy APK files
# --------------------------------------------------

echo "Generating APK download page..."

python3 - \
  "${SOURCE_DOWNLOAD_DIR}" \
  "${OUTPUT_DOWNLOAD_DIR}" <<'PYTHON'
import html
import pathlib
import re
import shutil
import sys

source_dir = pathlib.Path(sys.argv[1])
output_dir = pathlib.Path(sys.argv[2])

output_dir.mkdir(parents=True, exist_ok=True)

# Accept versioned filenames such as:
# dragonball-v1.0.0.apk
# dragonball-v1.1.0-3.apk
# dragonball-v1.10.0-12.apk

version_pattern = re.compile(
    r"-v(\d+(?:\.\d+)*)(?:-(\d+))?\.apk$",
    re.IGNORECASE,
)


def version_key(path):
    match = version_pattern.search(path.name)

    if not match:
        # Unrecognized filenames appear after versioned releases.
        return (0, (), 0, path.name.lower())

    version = tuple(
        int(part) for part in match.group(1).split(".")
    )
    build_number = int(match.group(2) or 0)

    return (1, version, build_number, path.name.lower())


# Discover APKs supplied in web/download.
apk_files = [
    file
    for file in source_dir.glob("*.apk")
    if file.is_file()
]

apk_files.sort(key=version_key, reverse=True)

# Copy APKs to the actual Vercel output directory.
for apk in apk_files:
    destination = output_dir / apk.name

    # Avoid copying a file onto itself.
    if apk.resolve() != destination.resolve():
        shutil.copy2(apk, destination)

print(f"Found {len(apk_files)} APK release(s).")

# --------------------------------------------------
# Build the release cards
# --------------------------------------------------

items = []

for apk in apk_files:
    filename = apk.name
    match = version_pattern.search(filename)

    if match:
        version = match.group(1)
        build_number = match.group(2)

        version_label = f"Version {version}"

        if build_number:
            version_label += f" (Build {build_number})"
    else:
        version_label = apk.stem

    safe_version = html.escape(version_label)
    safe_filename = html.escape(filename)
    safe_href = html.escape(filename, quote=True)

    items.append(
        f"""
        <article class="release">
          <div class="release-info">
            <strong>{safe_version}</strong>
            <span>{safe_filename}</span>
            <span class="file-type">Android APK</span>
          </div>

          <a class="download"
             href="/download/{safe_href}"
             download>
            Download APK
          </a>
        </article>
        """
    )

if items:
    listing = "\n".join(items)
else:
    listing = """
    <section class="empty">
      <h2>No APK releases available</h2>
      <p>
        Android releases will appear here after APK files
        are added to the release directory.
      </p>
    </section>
    """

# --------------------------------------------------
# Generate index.html automatically
# --------------------------------------------------

page = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1">

  <meta name="theme-color" content="#ED6C24">

  <meta name="description"
        content="Download Android releases of Dragon Ball Universe.">

  <title>Dragon Ball Universe — APK Downloads</title>

  <style>
    :root {{
      color-scheme: light dark;

      --accent: #ED6C24;
      --background: #FFFAF5;
      --surface: #FFFFFF;
      --text: #29231F;
      --muted: #71665E;
      --border: #E8DDD3;
      --button-text: #FFFFFF;
    }}

    @media (prefers-color-scheme: dark) {{
      :root {{
        --accent: #FF8A45;
        --background: #171717;
        --surface: #242424;
        --text: #F5F5F5;
        --muted: #B5ACA5;
        --border: #414141;
        --button-text: #171717;
      }}
    }}

    * {{
      box-sizing: border-box;
    }}

    body {{
      margin: 0;
      padding: 32px 18px;
      background: var(--background);
      color: var(--text);
      font-family: system-ui, -apple-system, BlinkMacSystemFont,
                   "Segoe UI", sans-serif;
    }}

    main {{
      width: 100%;
      max-width: 760px;
      margin: 0 auto;
    }}

    .brand {{
      color: var(--accent);
      font-size: 13px;
      font-weight: 800;
      letter-spacing: 2px;
      text-transform: uppercase;
    }}

    h1 {{
      margin: 12px 0 8px;
      font-size: clamp(28px, 5vw, 42px);
      line-height: 1.15;
    }}

    .description {{
      margin-bottom: 28px;
      color: var(--muted);
      line-height: 1.7;
    }}

    .release {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
      margin-top: 14px;
      padding: 18px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
    }}

    .release-info {{
      display: flex;
      flex-direction: column;
      gap: 6px;
      min-width: 0;
      overflow-wrap: anywhere;
    }}

    .release-info strong {{
      font-size: 16px;
    }}

    .release-info span {{
      color: var(--muted);
      font-size: 13px;
    }}

    .download {{
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      padding: 11px 16px;
      border-radius: 10px;
      background: var(--accent);
      color: var(--button-text);
      text-decoration: none;
      font-weight: 700;
      transition: opacity 150ms ease;
    }}

    .download:hover {{
      opacity: 0.85;
    }}

    .download:focus-visible {{
      outline: 3px solid var(--accent);
      outline-offset: 3px;
    }}

    .empty {{
      padding: 24px;
      border: 1px dashed var(--border);
      border-radius: 16px;
    }}

    .empty p {{
      color: var(--muted);
      line-height: 1.6;
    }}

    footer {{
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid var(--border);
      color: var(--muted);
      font-size: 13px;
      line-height: 1.6;
    }}

    @media (max-width: 440px) {{
      .release {{
        align-items: flex-start;
        flex-direction: column;
      }}

      .download {{
        width: 100%;
      }}
    }}
  </style>
</head>

<body>
  <main>
    <div class="brand">Dragon Ball Universe</div>

    <h1>APK Downloads</h1>

    <p class="description">
      Browse available Android releases. The newest version
      appears first.
    </p>

    {listing}

    <footer>
      Install APK files only from sources you trust.
      Android may ask you to authorize installation from
      your browser or file manager.
    </footer>
  </main>
</body>
</html>
"""

index_file = output_dir / "index.html"
index_file.write_text(page, encoding="utf-8")

print(f"Generated: {index_file}")
print(f"Listed {len(apk_files)} APK release(s).")
PYTHON

# --------------------------------------------------
# 8. Verify deployment artifacts
# --------------------------------------------------

if [ ! -f "${WEB_OUTPUT_DIR}/index.html" ]; then
  echo "ERROR: Flutter web index.html was not generated."
  exit 1
fi

if [ ! -f "${OUTPUT_DOWNLOAD_DIR}/index.html" ]; then
  echo "ERROR: APK download index.html was not generated."
  exit 1
fi

echo "=========================================="
echo " Build completed successfully"
echo " Web output: ${WEB_OUTPUT_DIR}"
echo " APK downloads: ${OUTPUT_DOWNLOAD_DIR}"
echo "=========================================="
