"""Makes the app's launcher icons, splash logo and in-app logo from the
Baseera logo (the 900x1600 poster in the project folder).
Run: python tool/make_icons.py ["path/to/Baseera logo.jpeg"]"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

APP = Path(__file__).resolve().parents[1]
SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else APP.parent / "Baseera logo.jpeg"
RES = APP / "android/app/src/main/res"

# The poster's background around the emblem, and the emblem (ring, glasses,
# name) in poster pixels.
BACKGROUND = (2, 1, 16)
EMBLEM_CENTER = (460, 790)
EMBLEM_WIDTH = 614
CROP = 840  # square around the emblem and its star; the corners are plain background

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def emblem() -> Image.Image:
    """The emblem on a transparent square, edges faded into nothing."""
    poster = Image.open(SOURCE).convert("RGB")
    cx, cy = EMBLEM_CENTER
    half = CROP // 2
    square = poster.crop((cx - half, cy - half, cx + half, cy + half)).convert("RGBA")
    fade = Image.new("L", (CROP, CROP), 0)
    inset = int(CROP * 0.03)
    ImageDraw.Draw(fade).ellipse((inset, inset, CROP - inset, CROP - inset), fill=255)
    square.putalpha(fade.filter(ImageFilter.GaussianBlur(CROP * 0.02)))
    return square


def draw(size: int, fill: float, background: bool, corner: float = 0) -> Image.Image:
    """The emblem [fill] of [size] wide, on the dark background or transparent,
    optionally as a rounded square."""
    scale = size * fill / EMBLEM_WIDTH
    art = EMBLEM.resize((round(CROP * scale),) * 2, Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), BACKGROUND + (255,) if background else (0, 0, 0, 0))
    offset = (size - art.width) // 2
    if offset < 0:  # the faded edge is wider than the canvas: trim it
        art = art.crop((-offset, -offset, -offset + size, -offset + size))
        offset = 0
    canvas.alpha_composite(art, (offset, offset))
    if corner:
        mask = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * corner, fill=255)
        canvas.putalpha(mask.resize((size, size), Image.LANCZOS))
    return canvas


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(path.relative_to(APP), image.size)


EMBLEM = emblem()

# In-app logo (BrandMark), also the 512 px store icon.
save(draw(512, 0.86, background=True), APP / "assets/brand/logo.png")

for name, d in DENSITIES.items():
    # Android 7 and older: a rounded square.
    save(draw(round(48 * d), 0.84, background=True, corner=0.2), RES / f"mipmap-{name}/ic_launcher.png")
    # Android 8+: adaptive icon. The emblem stays inside the 66 dp safe circle
    # of the 108 dp layer, so every launcher mask keeps all of it.
    save(draw(round(108 * d), 0.52, background=False), RES / f"mipmap-{name}/ic_launcher_foreground.png")
    # Android 7-11 splash: the emblem centred on the dark background.
    save(draw(round(180 * d), 0.9, background=False), RES / f"drawable-{name}/splash_logo.png")

# Web preview build.
save(draw(32, 0.9, background=True), APP / "web/favicon.png")
for size in (192, 512):
    save(draw(size, 0.84, background=True), APP / f"web/icons/Icon-{size}.png")
    save(draw(size, 0.62, background=True), APP / f"web/icons/Icon-maskable-{size}.png")
