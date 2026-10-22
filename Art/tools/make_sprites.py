#!/usr/bin/env python3
"""
Builds the menu bar capybara animations from the hand-made art.

  walk  (8 frames, play at 8 fps)  – made from Jump_Animation_Frames/1.png:
         legs lift in alternating pairs, body bobs and tilts, pom-pom bounces.
  jump  (9 frames, play at 10 fps) – crouch, the 5 drawn jump frames on an arc,
         squash on landing, settle.
  stand  (1 frame)  – frame 1 as drawn (idle, or a phase waiting for Start).
  nap    (4 frames, 3 fps) – short break: frame 1 lying low, with z's floating up.
  spring (16 frames, 4 fps, 44 pt wide) – long break: frame 1 floating across a wide
         hot-spring pool and back, with ripples and rising steam (water and steam drawn here).
  sleep  (1 frame)  – frame 1 lying low (squashed), with "z z" drawn above its head.

Every frame shares one canvas with the feet on the same baseline, so nothing jitters.
Output: Art/sprites/{walk,jump}/<pose>_NN.png (1x) and <pose>_NN@2x.png (2x),
preview images in Art/sprites/preview/, and the same frames as image sets in
CapyDoro/Assets.xcassets/Sprites/ so the app can load them by name ("walk_01").

Run from anywhere:  python3 Art/tools/make_sprites.py
Needs Pillow (pip install pillow). Dev-only; nothing here ships in the app.
"""
from pathlib import Path
import shutil

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

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


def stand_frames():
    return [(load(1), 0)]


def sleep_frames():
    return [(squash(load(1), 1.1, 0.8), 0)]               # lying low, eyes already closed


def draw_z(draw: ImageDraw.ImageDraw, x: float, y: float, size: float, scale: int):
    """One 'z' (positions in points) in a soft blue that reads on light and dark menu bars."""
    x, y, size = x * scale, y * scale, size * scale
    z = [(x, y), (x + size, y), (x, y + size), (x + size, y + size)]
    draw.line(z, fill=(92, 118, 196, 255), width=max(1, round(scale * 0.8)))


def draw_zzz(canvas: Image.Image, scale: int) -> Image.Image:
    """Paused: two still z's above the head (top right)."""
    draw = ImageDraw.Draw(canvas)
    for x, y, size in [(16.0, 4.2, 2.4), (19.6, 1.2, 3.0)]:   # second z higher and bigger
        draw_z(draw, x, y, size, scale)
    return canvas


def draw_rising_zzz(canvas: Image.Image, scale: int, step: int) -> Image.Image:
    """Short-break nap: z's that float up from the head and grow, two at a time, so the
    4-frame loop looks like a steady stream."""
    draw = ImageDraw.Draw(canvas)
    for t in (step / 4, ((step + 2) % 4) / 4):          # 0 = just left the head, 1 = top
        draw_z(draw, 15.5 + 5 * t, 6.5 - 6 * t, 1.8 + 1.4 * t, scale)
    return canvas


SPRING_CANVAS_PT = (44, 20)   # wider than the other poses: a pool to drift around in
SPRING_FRAMES = 16            # one full there-and-back drift (4 s at 4 fps)


def spring_frame(scale: int, step: int, factor: float) -> Image.Image:
    """One hot-spring frame: the capybara floats across a wide pool and back, turning to face
    the way it drifts, bobbing a little, with ripples and steam around it."""
    import math
    width, height = SPRING_CANVAS_PT
    size = (width * scale, height * scale)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    t = step / SPRING_FRAMES                              # 0 → 1 over the loop
    surface = 12.5                                        # water line, in points from the top

    # Steam: three wisps rising off the water (drawn first, so they sit behind the capybara).
    draw = ImageDraw.Draw(canvas)
    for x0, offset in [(5.0, 0.0), (22.0, 0.35), (39.0, 0.7)]:
        rise = ((t * 2 + offset) % 1) * 2.0
        pts = []
        for k in range(9):
            u = k / 8
            y = (surface - 0.5 - u * 6.5 - rise) * scale
            x = (x0 + 0.7 * math.sin(u * 2 * math.pi + t * 4 * math.pi)) * scale
            pts.append((x, y))
        draw.line(pts, fill=(176, 196, 212, 220), width=max(1, round(scale * 0.7)), joint="curve")

    # The capybara: smaller than standing, drifting ±13 pt from the middle and back.
    capy = load(1)
    capy = capy.crop(capy.getchannel("A").getbbox())
    if math.cos(2 * math.pi * t) < 0:                     # drifting left → face left
        capy = ImageOps.mirror(capy)
    f = factor * 0.8
    small = capy.resize((round(capy.width * f), round(capy.height * f)), Image.LANCZOS)
    small = small.filter(ImageFilter.UnsharpMask(radius=0.6, percent=60, threshold=1))
    center_x = width / 2 + 13 * math.sin(2 * math.pi * t)
    top = 3.6 + 0.35 * math.sin(4 * math.pi * t)          # gentle bob; back stays above water
    x_px = round(center_x * scale - small.width / 2)
    tall = Image.new("RGBA", (size[0], max(size[1], round(top * scale) + small.height)), (0, 0, 0, 0))
    tall.alpha_composite(small, (x_px, round(top * scale)))
    canvas.alpha_composite(tall.crop((0, 0, size[0], size[1])))

    # Water: the full width, a rippling surface and softly rounded bottom corners,
    # slightly see-through so the submerged body shows faintly.
    water = Image.new("RGBA", size, (0, 0, 0, 0))
    wdraw = ImageDraw.Draw(water)
    edge = []
    for k in range(0, 89):
        x_pt = width * k / 88
        y_pt = surface + 0.4 * math.sin(x_pt / 2.2 + t * 4 * math.pi)
        edge.append((x_pt * scale, y_pt * scale))
    radius = 3.0
    corners = []
    for k in range(0, 9):                                 # bottom-right corner, then bottom-left
        a = math.pi / 2 * k / 8
        corners.append(((width - radius + radius * math.cos(a)) * scale,
                         (height - radius + radius * math.sin(a)) * scale))
    for k in range(0, 9):
        a = math.pi / 2 + math.pi / 2 * k / 8
        corners.append(((radius + radius * math.cos(a)) * scale,
                         (height - radius + radius * math.sin(a)) * scale))
    wdraw.polygon(edge + corners, fill=(122, 194, 234, 255))
    # Fade the water out towards the bottom so it reads as a pool, not a solid block.
    fade = Image.new("L", size, 0)
    for y in range(size[1]):
        depth = max(0.0, (y / scale - surface) / (height - surface))   # 0 at surface → 1 at bottom
        fade.paste(round(210 - 150 * depth), (0, y, size[0], y + 1))
    water.putalpha(ImageChops.multiply(water.getchannel("A"), fade))
    ImageDraw.Draw(water).line(edge, fill=(58, 138, 198, 255), width=max(1, round(scale * 0.7)))
    canvas.alpha_composite(water)
    return canvas


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
        "stand": place(stand_frames(), factor, size, baseline),
        "nap": [draw_rising_zzz(place(sleep_frames(), factor, size, baseline)[0], scale, step)
                for step in range(4)],
        "sleep": [draw_zzz(f, scale) for f in place(sleep_frames(), factor, size, baseline)],
        "spring": [spring_frame(scale, step, factor) for step in range(SPRING_FRAMES)],
    }


def save_all():
    for scale, suffix in [(1, ""), (2, "@2x")]:
        for pose, frames in render(scale).items():
            folder = OUT / pose
            if scale == 1 and folder.exists():
                shutil.rmtree(folder)       # start clean so removed frames don't linger
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
    for pose in ("walk", "jump", "stand", "nap", "spring", "sleep"):
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
