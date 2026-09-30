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
            
            # Convert to RGB to ensure no transparency issues on App Store, though PNG is processed
            if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                alpha = img.convert('RGBA').split()[-1]
                bg = Image.new("RGB", img.size, (255, 255, 255))
                bg.paste(img, mask=alpha)
                img = bg
            
            resized = img.resize((target_w, target_h), Image.LANCZOS)
            # Save without alpha channel as Apple doesn't allow alpha in App Store screenshots
            resized.convert('RGB').save(path, format='PNG')
