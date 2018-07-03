import os
import shutil
from PIL import Image

SIZES = {
    (20,    "icon-20.png"),
    (40,    "icon-20@2x.png"),
    (40,    "icon-20@2x2.png"),
    (60,    "icon-20@3x.png"),
    (29,    "icon-29.png"),
    (58,    "icon-29@2x.png"),
    (58,    "icon-29@2x2.png"),
    (87,    "icon-29@3x.png"),
    (40,    "icon-40.png"),
    (80,    "icon-40@2x.png"),
    (80,    "icon-40@2x2.png"),
    (120,   "icon-40@3x.png"),
    (120,   "icon-60@2x.png"),
    (180,   "icon-60@3x.png"),
    (76,    "icon-76.png"),
    (152,   "icon-76@2x.png"),
    (167,   "icon-83@2x.png")
}

ICON_FOLDER = "picstore/Assets.xcassets/AppIcon.appiconset"

img = Image.open("picstore/Assets.xcassets/AppIcon.appiconset/icon-1024.jpg")
for size, name in SIZES:
    icon = img.resize((size, size), Image.ANTIALIAS)
    icon.save(os.path.join(ICON_FOLDER, name))
