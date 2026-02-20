# App Store Screenshot Cutting Guide

## Source File
- `カイログ.png` — a single wide panoramic image containing all screenshots side by side.

## Output
- `s_1.png` through `s_5.png` — 5 equal slices, left to right.

## Capture Requirement (Important)
- Capture screenshots from a **release/profile build** only.
- Do **not** capture from a Flutter debug run (`flutter run` default) to avoid debug overlays/banners in App Store assets.

## Target Dimensions
- **1284 × 2778 px** (iPhone 6.7" — required by App Store Connect)

## Accepted Dimensions (App Store Connect 6.5"/6.7")
| Orientation | Dimensions |
|-------------|------------|
| Portrait    | 1242 × 2688 |
| Landscape   | 2688 × 1242 |
| Portrait    | 1284 × 2778 |
| Landscape   | 2778 × 1284 |

## Tool
- **Python 3 + Pillow** (`pip3 install Pillow`)

## Script
```python
from PIL import Image
import os

img = Image.open('assets/app store/カイログ.png')
w, h = img.size
slice_w = w // 5
target_w, target_h = 1284, 2778
output_dir = 'assets/app store'

for i in range(5):
    left = i * slice_w
    crop = img.crop((left, 0, left + slice_w, h))
    resized = crop.resize((target_w, target_h), Image.LANCZOS)
    resized.save(os.path.join(output_dir, f"s_{i+1}.png"))
```

Run from project root (`/Users/fatboy/kurabe`).
