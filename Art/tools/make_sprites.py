#!/usr/bin/env python3
"""
Builds the menu bar capybara animations from the hand-made art.

  walk  (8 frames, play at 8 fps)  – made from Jump_Animation_Frames/1.png:
         legs lift in alternating pairs, body bobs and tilts, pom-pom bounces.
  jump  (9 frames, play at 10 fps) – crouch, the 5 drawn jump frames on an arc,
         squash on landing, settle.

Every frame shares one canvas with the feet on the same baseline, so nothing jitters.
Output: Art/sprites/{walk,jump}/<pose>_NN.png (1x) and <pose>_NN@2x.png (2x),
preview images in Art/sprites/preview/, and the same frames as image sets in
CapyDoro/Assets.xcassets/Sprites/ so the app can load them by name ("walk_01").

Run from anywhere:  python3 Art/tools/make_sprites.py
Needs Pillow (pip install pillow). Dev-only; nothing here ships in the app.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageFilter

ART = Path(__file__).resolve().parent.parent
SRC = ART / "sprites" / "Jump_Animation_Frames"
OUT = ART / "sprites"
ASSETS = ART.parent / "CapyDoro" / "Assets.xcassets" / "Sprites"

# Canvas in points (the menu bar is ~22–24 pt tall). 2x pixels = points * 2.
CANVAS_PT = (24, 20)
STAND_HEIGHT_PT = 16          # standing capybara height; leaves room above for the jump arc
BASELINE_PT = 19.5            # feet sit here (from the top), half a point above the bottom

# Regions in the source art (frame 1 is 480x428). Found by eye.
LEG_TOP = 345
BACK_LEGS_X = (60, 230)
FRONT_LEGS_X = (265, 380)
POMPOM_BOTTOM = 62


def load(n: int) -> Image.Image:
    img = Image.open(SRC / f"{n}.png").convert("RGBA")
    return defringe(img)


def defringe(img: Image.Image) -> Image.Image:
    """Removes the whitish glow AI background removal leaves around the outline."""
    r, g, b, a = img.split()
    a = a.point(lambda v: 0 if v < 110 else (255 if v > 200 else v))
    a = a.filter(ImageFilter.MinFilter(3))        # shave ~1 px off the edge
    return Image.merge("RGBA", (r, g, b, a))


def shift_region(img: Image.Image, box, dx: int, dy: int) -> Image.Image:
    """Moves a rectangular patch (e.g. a pair of legs) by dx, dy, over the rest of the art."""
    patch = img.crop(box)
    base = img.copy()
    # Clear where the patch was, then paste the patch at its new spot.
    base.paste((0, 0, 0, 0), box)
    # Keep the body pixels that overlapped the leg box's top edge so no hole appears.
    body_edge = img.crop((box[0], box[1], box[2], box[1] + 18))
    base.alpha_composite(body_edge, (box[0], box[1]))
    base.alpha_composite(patch, (box[0] + dx, box[1] + dy))
    return base


def walk_frames() -> list[Image.Image]:
    src = load(1)
    w, h = src.size
    # (back legs dy, front legs dy, body bob dy, tilt degrees, pom-pom dy) per frame.
    # Legs lift alternately; the body is highest when legs are planted mid-stride.
    steps = [
        (-22, 0, 0, 2.0, 3),
        (-12, 0, -8, 1.2, 6),
        (0, 0, -13, 0.0, 0),
        (0, 0, -8, -1.2, -4),
        (0, -22, 0, -2.0, 3),
        (0, -12, -8, -1.2, 6),
        (0, 0, -13, 0.0, 0),
        (0, 0, -8, 1.2, -4),
    ]
    frames = []
    for back, front, bob, tilt, pom in steps:
        f = src
        f = shift_region(f, (BACK_LEGS_X[0], LEG_TOP, BACK_LEGS_X[1], h), 0, back)
        f = shift_region(f, (FRONT_LEGS_X[0], LEG_TOP, FRONT_LEGS_X[1], h), 0, front)
        # Pom-pom lags behind the body for a little secondary bounce.
        pompom = f.crop((0, 0, w, POMPOM_BOTTOM))
        body = f.copy()
        body.paste((0, 0, 0, 0), (0, 0, w, POMPOM_BOTTOM))
        body.alpha_composite(pompom, (0, pom))
        # Lift the whole body (not the feet) by `bob`, then rock it slightly around the feet.
        # The feet strip starts 40 px higher than the cut so, when the torso rises,
        # belly pixels underneath fill the gap instead of leaving a see-through stripe.
        cut = LEG_TOP + 10
        torso = body.crop((0, 0, w, cut))
        feet = body.crop((0, cut - 40, w, h))
        canvas = Image.new("RGBA", (w, h + 20), (0, 0, 0, 0))
        canvas.alpha_composite(feet, (0, cut - 40 + 20))
        canvas.alpha_composite(torso, (0, 20 + bob))
        canvas = canvas.rotate(tilt, resample=Image.BICUBIC, center=(w // 2, h + 20))
        frames.append((canvas, 0))   # (image, extra lift above baseline in source px)
    return frames


def squash(img: Image.Image, sx: float, sy: float) -> Image.Image:
    w, h = img.size
    return img.resize((round(w * sx), round(h * sy)), Image.LANCZOS)


def jump_frames():
    f1, f2, f3, f4, f5 = (load(n) for n in range(1, 6))
    # (image, lift above the baseline in source pixels)
    return [
        (f1, 0),
        (squash(f1, 1.08, 0.88), 0),      # crouch
        (f2, 40),                         # take-off
        (f3, 95),                         # rising
        (f3, 120),                        # apex (hold one frame)
        (f4, 90),                         # coming down
        (f5, 15),                         # touch-down
        (squash(f5, 1.1, 0.86), 0),       # land squash
        (squash(f1, 0.97, 1.04), 0),      # settle
    ]


def place(frames, scale_px: float, size_px, baseline_px: float):
    """Scales every frame by the same factor and stands it on one baseline, centred."""
    out = []
    for img, lift in frames:
        bbox = img.getchannel("A").getbbox()
        img = img.crop(bbox)
        small = img.resize((max(1, round(img.width * scale_px)), max(1, round(img.height * scale_px))), Image.LANCZOS)
        small = small.filter(ImageFilter.UnsharpMask(radius=0.6, percent=60, threshold=1))
        canvas = Image.new("RGBA", size_px, (0, 0, 0, 0))
        x = (size_px[0] - small.width) // 2
        y = round(baseline_px - small.height - lift * scale_px)
        canvas.alpha_composite(small, (x, max(0, y)))
        out.append(canvas)
    return out


def render(scale: int):
    """scale = 1 for @1x, 2 for @2x."""
    size = (CANVAS_PT[0] * scale, CANVAS_PT[1] * scale)
    stand = load(1)
    factor = STAND_HEIGHT_PT * scale / stand.getchannel("A").getbbox()[3]
    baseline = BASELINE_PT * scale
    return {
        "walk": place(walk_frames(), factor, size, baseline),
        "jump": place(jump_frames(), factor, size, baseline),
    }


def save_all():
    for scale, suffix in [(1, ""), (2, "@2x")]:
        for pose, frames in render(scale).items():
            folder = OUT / pose
            folder.mkdir(exist_ok=True)
            for i, frame in enumerate(frames, 1):
                frame.save(folder / f"{pose}_{i:02d}{suffix}.png")
    save_asset_catalog()
    save_preview()


def save_asset_catalog():
    """Copies every frame into Assets.xcassets/Sprites/<name>.imageset (1x + 2x).
    Colour images, not templates: the capybara keeps its colours in the menu bar."""
    import json, shutil
    if ASSETS.exists():
        shutil.rmtree(ASSETS)          # start clean so removed frames don't linger
    ASSETS.mkdir(parents=True)
    info = {"author": "xcode", "version": 1}
    (ASSETS / "Contents.json").write_text(json.dumps({"info": info}, indent=2) + "\n")
    for pose in ("walk", "jump"):
        for one_x in sorted((OUT / pose).glob(f"{pose}_[0-9][0-9].png")):
            name = one_x.stem
            folder = ASSETS / f"{name}.imageset"
            folder.mkdir()
            shutil.copy(one_x, folder / f"{name}.png")
            shutil.copy(one_x.with_name(f"{name}@2x.png"), folder / f"{name}@2x.png")
            (folder / "Contents.json").write_text(json.dumps({
                "images": [
                    {"filename": f"{name}.png", "idiom": "universal", "scale": "1x"},
                    {"filename": f"{name}@2x.png", "idiom": "universal", "scale": "2x"},
                ],
                "info": info,
            }, indent=2) + "\n")


def save_preview():
    """A GIF of the focus loop (walk ×3, then a hop) on a light and a dark menu bar, zoomed 4x."""
    sprites = render(2)
    sequence = sprites["walk"] * 3 + sprites["jump"]
    durations = [125] * 24 + [100] * len(sprites["jump"])
    zoom = 4
    w, h = sprites["walk"][0].size
    gif_frames = []
    for frame in sequence:
        bar = Image.new("RGBA", (w * 2 + 24, h + 8), (0, 0, 0, 0))
        light = Image.new("RGBA", (w + 12, h + 8), (236, 236, 236, 255))
        dark = Image.new("RGBA", (w + 12, h + 8), (36, 36, 38, 255))
        light.alpha_composite(frame, (6, 4))
        dark.alpha_composite(frame, (6, 4))
        bar.paste(light, (0, 0)); bar.paste(dark, (w + 12, 0))
        bar = bar.resize((bar.width * zoom, bar.height * zoom), Image.NEAREST)
        gif_frames.append(bar.convert("RGB"))
    (OUT / "preview").mkdir(exist_ok=True)
    gif_frames[0].save(OUT / "preview" / "focus_loop.gif", save_all=True,
                       append_images=gif_frames[1:], duration=durations, loop=0, disposal=2)
    # Contact sheet of every @2x frame for quick inspection.
    allf = sprites["walk"] + sprites["jump"]
    sheet = Image.new("RGBA", ((w + 4) * len(allf), h * 2 + 4), (255, 0, 255, 255))
    for i, frame in enumerate(allf):
        tile = Image.new("RGBA", (w, h), (36, 36, 38, 255)); tile.alpha_composite(frame)
        sheet.alpha_composite(frame, (i * (w + 4), 0))
        sheet.alpha_composite(tile, (i * (w + 4), h + 4))
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(OUT / "preview" / "frames.png")


if __name__ == "__main__":
    save_all()
    print("Wrote sprites to", OUT)
