# App Store Screenshot Guide (PetTomo)

This guide explains how to prepare and upload App Store screenshots for the PetTomo project.

## Directory Structure
Screenshots are organized by localization within `assets/appstore/`:
- `assets/appstore/JP/` (Japanese)
- `assets/appstore/CN/` (Traditional Chinese)
- `assets/appstore/ENG/` (English)
- `assets/appstore/KR/` (Korean)

There should be up to 5 screenshots per language.

## Capture Requirement (Important)
- Capture screenshots from a **release/profile build** only.
- Do **not** capture from a Flutter debug run (`flutter run` default) to avoid debug overlays/banners.

## Target Dimensions
App Store Connect strictly requires exact pixel dimensions for the 6.7" iPhone display. Raw exports often vary slightly (e.g., 1243x2689), so they must be perfectly resized to **1284x2778**.

- **1284 × 2778 px** (iPhone 6.7" — required by App Store Connect)

## Step 1: Resizing Screenshots

`scripts/resize_screenshots.py` scans all localization folders, resizes `.png` files to EXACTLY 1284x2778, removes alpha channels (transparency is rejected by Apple), and saves them in-place.

**Prerequisites:** Python 3 + Pillow (`pip3 install Pillow`)

Run from the project root:
```bash
python3 scripts/resize_screenshots.py
```

## Step 2: Uploading via App Store Connect CLI (asc)

Once resized, use the `asc` CLI to upload the screenshots directly to App Store Connect.

**Important:** You need the `version-localization` ID for each target language on App Store Connect. You can find them by calling:
```bash
# Get your App ID using: asc apps list
# Assuming PetTomo App ID is 6757725650. Get your active version ID first:
asc versions list --app 6757725650

# Then get the localization IDs for that version:
asc localizations list --version "<VERSION_ID>"
```

`scripts/upload_screenshots.sh` uploads every locale folder. Update its version-localization IDs first if the version changed.

Run from the project root:
```bash
bash scripts/upload_screenshots.sh
```
