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

Use the following Python script to automatically scan all localization folders, resize the `.png` files to EXACTLY 1284x2778, remove alpha channels (transparency is rejected by Apple), and save them in-place.

**Prerequisites:** Python 3 + Pillow (`pip3 install Pillow`)

```python
# Save this as resize_screenshots.py in the project root
from PIL import Image
import os
import glob

target_w, target_h = 1284, 2778

for root, dirs, files in os.walk('assets/appstore'):
    for file in files:
        if file.lower().endswith('.png'):
            path = os.path.join(root, file)
            img = Image.open(path)
            w, h = img.size
            if w == target_w and h == target_h:
                continue
            print(f"Resizing {path} from {w}x{h} to {target_w}x{target_h}")
            
            # Remove alpha channel if present
            if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                alpha = img.convert('RGBA').split()[-1]
                bg = Image.new("RGB", img.size, (255, 255, 255))
                bg.paste(img, mask=alpha)
                img = bg
            
            resized = img.resize((target_w, target_h), Image.LANCZOS)
            resized.convert('RGB').save(path, format='PNG')
```

Run from the project root (`/Users/fatboy/pet`):
```bash
python3 resize_screenshots.py
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

Here is a bash script to automate the upload process for all locales:

```bash
#!/bin/bash
# Save this as upload_screenshots.sh in the project root
set -e

# NOTE: Replace the UUIDs with the actual version-localization IDs obtained from asc localizations list
VERSION_LOC_KR="93643a42-f682-4c10-87d7-e85f8bb0d508"
VERSION_LOC_JP="c39480e3-1376-4a52-a226-2b864cfdf8bc"
VERSION_LOC_ENG="261a2394-b8a3-4035-8abb-f0f835e21c6d"
VERSION_LOC_CN="df0e27b5-092d-42fd-90e9-e502ce4345f7"

echo "Uploading KR..."
asc screenshots upload --version-localization "$VERSION_LOC_KR" --path "./assets/appstore/KR" --device-type "APP_IPHONE_65"

echo "Uploading JP..."
asc screenshots upload --version-localization "$VERSION_LOC_JP" --path "./assets/appstore/JP" --device-type "APP_IPHONE_65"

echo "Uploading ENG..."
asc screenshots upload --version-localization "$VERSION_LOC_ENG" --path "./assets/appstore/ENG" --device-type "APP_IPHONE_65"

echo "Uploading CN..."
asc screenshots upload --version-localization "$VERSION_LOC_CN" --path "./assets/appstore/CN" --device-type "APP_IPHONE_65"

echo "Done."
```

Run from the project root:
```bash
bash upload_screenshots.sh
```
