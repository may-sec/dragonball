#!/bin/bash

# Create necessary directories for organization
mkdir -p responses/characters_pages
mkdir -p responses/characters_single
mkdir -p responses/planets_pages
mkdir -p responses/planets_single
mkdir -p responses/filters
mkdir -p images
mkdir -p logs

echo "=========================================="
echo "Starting Dragon Ball API Full Harvest..."
echo "=========================================="

# 1. Fetch Paginated Characters (Pages 1 to 6)
echo "[*] Fetching character pages (1-6)..."
for page in {1..6}; do
  status=$(curl -s -o "responses/characters_pages/page_$page.json" -w "%{http_code}" "https://dragonball-api.com/api/characters?page=$page&limit=10")
  echo "  -> Characters Page $page | HTTP Status: $status"
  echo "Characters Page $page: $status" >> logs/status_report.log
done

# 2. Fetch All Individual Characters (IDs 1 to 58)
echo "[*] Fetching individual characters (1-58)..."
for id in {1..58}; do
  status=$(curl -s -o "responses/characters_single/character_$id.json" -w "%{http_code}" "https://dragonball-api.com/api/characters/$id")
  echo "  -> Character ID $id | HTTP Status: $status"
  echo "Character ID $id: $status" >> logs/status_report.log
done

# 3. Fetch Paginated Planets (Pages 1 to 2)
echo "[*] Fetching planet pages (1-2)..."
for page in {1..2}; do
  status=$(curl -s -o "responses/planets_pages/page_$page.json" -w "%{http_code}" "https://dragonball-api.com/api/planets?page=$page&limit=10")
  echo "  -> Planets Page $page | HTTP Status: $status"
  echo "Planets Page $page: $status" >> logs/status_report.log
done

# 4. Fetch All Individual Planets (IDs 1 to 20)
echo "[*] Fetching individual planets (1-20)..."
for id in {1..20}; do
  status=$(curl -s -o "responses/planets_single/planet_$id.json" -w "%{http_code}" "https://dragonball-api.com/api/planets/$id")
  echo "  -> Planet ID $id | HTTP Status: $status"
  echo "Planet ID $id: $status" >> logs/status_report.log
done

# 5. Fetch Filter Endpoints
echo "[*] Fetching filter examples..."
curl -s -o "responses/filters/saiyan_zfighters.json" "https://dragonball-api.com/api/characters?race=Saiyan&affiliation=Z+fighter"
curl -s -o "responses/filters/planets_destroyed.json" "https://dragonball-api.com/api/planets?isDestroyed=true"

echo "=========================================="
echo "Extraction & Image Download Phase..."
echo "=========================================="

# 6. Extract all .webp URLs from the saved JSON responses
echo "[*] Extracting .webp image links from responses..."
grep -rhoE 'https?://[^\"]+\.webp' responses/ | sort -u > image_urls.txt

total_images=$(wc -l < image_urls.txt)
echo "Found $total_images unique image URLs."

# 7. Download every extracted webp image
counter=1
while IFS= read -r url; do
  if [ -n "$url" ]; then
    filename=$(basename "$url")
    echo "[$counter/$total_images] Downloading $filename..."
    curl -s -o "images/$filename" "$url"
    ((counter++))
  fi
done < image_urls.txt

echo "=========================================="
echo "All tasks completed successfully!"
echo "Check 'logs/status_report.log' for any non-200 HTTP codes."
echo "=========================================="