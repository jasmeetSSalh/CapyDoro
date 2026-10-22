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


POOL_SURFACE = 12.5   # water line, in points from the top


def draw_steam(canvas: Image.Image, scale: int, t: float):
    """Three wisps rising off the pool (draw before the capybara so they sit behind it)."""
    import math
    draw = ImageDraw.Draw(canvas)
    for x0, offset in [(5.0, 0.0), (22.0, 0.35), (39.0, 0.7)]:
        rise = ((t * 2 + offset) % 1) * 2.0
        pts = []
        for k in range(9):
            u = k / 8
            y = (POOL_SURFACE - 0.5 - u * 6.5 - rise) * scale
            x = (x0 + 0.7 * math.sin(u * 2 * math.pi + t * 4 * math.pi)) * scale
            pts.append((x, y))
        draw.line(pts, fill=(176, 196, 212, 220), width=max(1, round(scale * 0.7)), joint="curve")


def put(canvas: Image.Image, img: Image.Image, f: float, center_x: float, scale: int,
        top: float = None, bottom: float = None, mirror: bool = False):
    """Pastes `img` scaled by `f` (output px per source px), centred on `center_x` points,
    with its top (or bottom) at the given points. Anything off the canvas is clipped."""
    img = img.crop(img.getchannel("A").getbbox())
    if mirror:
        img = ImageOps.mirror(img)
    small = img.resize((round(img.width * f), round(img.height * f)), Image.LANCZOS)
    small = small.filter(ImageFilter.UnsharpMask(radius=0.6, percent=60, threshold=1))
    y_px = round(top * scale) if top is not None else round(bottom * scale) - small.height
    x_px = round(center_x * scale - small.width / 2)
    pad = max(0, -y_px)
    tall = Image.new("RGBA", (canvas.width, max(canvas.height, y_px + pad + small.height) + pad), (0, 0, 0, 0))
    tall.alpha_composite(small, (max(0, x_px), y_px + pad)) if x_px >= 0 else \
        tall.alpha_composite(small.crop((-x_px, 0, small.width, small.height)), (0, y_px + pad))
    canvas.alpha_composite(tall.crop((0, pad, canvas.width, pad + canvas.height)))


def draw_pool(canvas: Image.Image, scale: int, t: float):
    """The wide pool over everything already drawn: rippling surface, softly rounded bottom
    corners, fading out towards the bottom so it reads as a pool, not a solid block."""
    import math
    width, height = SPRING_CANVAS_PT
    size = canvas.size
    water = Image.new("RGBA", size, (0, 0, 0, 0))
    wdraw = ImageDraw.Draw(water)
    edge = []
    for k in range(0, 89):
        x_pt = width * k / 88
        y_pt = POOL_SURFACE + 0.4 * math.sin(x_pt / 2.2 + t * 4 * math.pi)
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
    fade = Image.new("L", size, 0)
    for y in range(size[1]):
        depth = max(0.0, (y / scale - POOL_SURFACE) / (height - POOL_SURFACE))
        fade.paste(round(210 - 150 * depth), (0, y, size[0], y + 1))
    water.putalpha(ImageChops.multiply(water.getchannel("A"), fade))
    ImageDraw.Draw(water).line(edge, fill=(58, 138, 198, 255), width=max(1, round(scale * 0.7)))
    canvas.alpha_composite(water)


def draw_drops(canvas: Image.Image, scale: int, drops):
    """Water droplets: (x, y, radius) in points."""
    draw = ImageDraw.Draw(canvas)
    for x, y, r in drops:
        draw.ellipse(((x - r) * scale, (y - r) * scale, (x + r) * scale, (y + r) * scale),
                     fill=(110, 185, 235, 255))


def pool_canvas(scale: int) -> Image.Image:
    return Image.new("RGBA", (SPRING_CANVAS_PT[0] * scale, SPRING_CANVAS_PT[1] * scale), (0, 0, 0, 0))


def spring_frame(scale: int, step: int, factor: float) -> Image.Image:
    """One hot-spring frame: the capybara floats across a wide pool and back, turning to face
    the way it drifts, bobbing a little, with ripples and steam around it."""
    import math
    canvas = pool_canvas(scale)
    t = step / SPRING_FRAMES                              # 0 → 1 over the loop
    draw_steam(canvas, scale, t)
    put(canvas, load(1), factor * 0.8, scale=scale,
        center_x=SPRING_CANVAS_PT[0] / 2 + 13 * math.sin(2 * math.pi * t),   # drifts ±13 pt
        top=3.6 + 0.35 * math.sin(4 * math.pi * t),                          # gentle bob
        mirror=math.cos(2 * math.pi * t) < 0)                                # drifting left → face left
    draw_pool(canvas, scale, t)
    return canvas


# ---- Transitions (B5): played once, ~10 fps, when the phase changes ----------------------

TRANSITIONS = ("flop", "dive", "wake", "emerge")


def flop_frames(scale, factor, size, baseline):
    """Focus → short break: slows, flops down (with a little overshoot), first z appears."""
    f1 = load(1)
    steps = [(1.0, 1.0), (1.02, 0.96), (1.05, 0.9), (1.09, 0.83),
             (1.13, 0.76), (1.1, 0.8), (1.1, 0.8), (1.1, 0.8)]
    frames = [place([(squash(f1, sx, sy), 0)], factor, size, baseline)[0] for sx, sy in steps]
    draw_z(ImageDraw.Draw(frames[6]), 15.5, 6.5, 1.6, scale)
    draw_z(ImageDraw.Draw(frames[7]), 15.8, 6.0, 1.9, scale)
    return frames


def wake_frames(scale, factor, size, baseline):
    """Short break → focus: the z goes, then a big stretch up and settle into standing."""
    f1 = load(1)
    steps = [((1.1, 0.8), 0), ((1.1, 0.8), 0), ((1.05, 0.9), 0), ((0.95, 1.07), 12),
             ((0.97, 1.04), 4), ((1.0, 1.0), 0), ((1.0, 1.0), 0)]
    frames = [place([(squash(f1, sx, sy), lift)], factor, size, baseline)[0] for (sx, sy), lift in steps]
    draw_z(ImageDraw.Draw(frames[0]), 15.5, 6.5, 1.8, scale)
    return frames


def dive_frames(scale, factor):
    """Focus → long break: crouch, hop in an arc and splash into the pool, then bob up to
    where the floating loop starts (centre, facing right)."""
    f1, f2, f3, f4, _ = (load(n) for n in range(1, 6))
    f = factor * 0.8
    air = factor * 0.6      # the jump drawings are taller; smaller in the air so the hat fits
    # (image, size, centre x, top or bottom in points). The menu bar is only 20 pt tall, so
    # the hop reads mostly through the poses and the sideways move, with a low arc.
    spec = [
        (squash(f1, 1.08, 0.88), f, 10.0, None, POOL_SURFACE),   # crouch at the water's edge
        (f2, air, 13.0, None, 12.1),                             # take-off
        (f3, air, 16.0, None, 11.0),
        (f3, air, 18.5, None, 10.9),                             # top of the hop
        (f4, air, 20.5, None, 11.4),
        (f1, f, 22.0, 5.6, None),                                # splash! (sunk deep)
        (f1, f, 22.0, 5.0, None),
        (f1, f, 22.0, 4.2, None),
        (f1, f, 22.0, 3.4, None),
        (f1, f, 22.0, 3.6, None),                                # = first floating frame
    ]
    splashes = {
        5: [(15, 9, 0.6), (17, 7.5, 0.7), (27, 7.5, 0.7), (29, 9, 0.6), (19, 6, 0.5), (25, 6, 0.5)],
        6: [(13.5, 10, 0.5), (15.5, 8.5, 0.6), (28.5, 8.5, 0.6), (30.5, 10, 0.5)],
        7: [(13, 11.6, 0.45), (31, 11.6, 0.45)],
    }
    frames = []
    for i, (img, size_f, cx, top, bottom) in enumerate(spec):
        canvas = pool_canvas(scale)
        t = i / 40
        draw_steam(canvas, scale, t)
        put(canvas, img, size_f, cx, scale, top=top, bottom=bottom)
        draw_pool(canvas, scale, t)
        draw_drops(canvas, scale, splashes.get(i, []))
        frames.append(canvas)
    return frames


def emerge_frames(scale, factor, size, baseline):
    """Long break → focus: rises out of the pool, then (out of the water, normal width)
    shakes off the drops and stands."""
    f1 = load(1)
    frames = []
    for i, top in enumerate([3.6, 2.4, 1.0]):
        canvas = pool_canvas(scale)
        draw_steam(canvas, scale, i / 40)
        put(canvas, f1, factor * 0.8, 22.0, scale, top=top)
        draw_pool(canvas, scale, i / 40)
        frames.append(canvas)
    shakes = [
        (6, [(3, 8, 0.6), (21, 7, 0.6), (2, 13, 0.5), (22, 12, 0.5)]),
        (-6, [(1.5, 6, 0.5), (22.5, 5, 0.5), (1, 12, 0.45), (23, 11, 0.45)]),
        (4, [(1, 4.5, 0.4), (23, 4, 0.4)]),
        (0, []),
    ]
    for angle, drops in shakes:
        img = f1.rotate(angle, resample=Image.BICUBIC, expand=True)
        frame = place([(img, 0)], factor, size, baseline)[0]
        draw_drops(frame, scale, drops)
        frames.append(frame)
    return frames


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
        "flop": flop_frames(scale, factor, size, baseline),
        "dive": dive_frames(scale, factor),
        "wake": wake_frames(scale, factor, size, baseline),
        "emerge": emerge_frames(scale, factor, size, baseline),
    }


def folder_for(name: str) -> Path:
    return OUT / "transitions" / name if name in TRANSITIONS else OUT / name


def save_all():
    for scale, suffix in [(1, ""), (2, "@2x")]:
        for name, frames in render(scale).items():
            folder = folder_for(name)
            if scale == 1 and folder.exists():
                shutil.rmtree(folder)       # start clean so removed frames don't linger
            folder.mkdir(parents=True, exist_ok=True)
            for i, frame in enumerate(frames, 1):
                frame.save(folder / f"{name}_{i:02d}{suffix}.png")
    save_asset_catalog()
    save_preview()


def save_asset_catalog():
    """Copies every frame into Assets.xcassets/Sprites/<name>.imageset (1x + 2x).
    Colour images, not templates: the capybara keeps its colours in the menu bar."""
    import json
    if ASSETS.exists():
        shutil.rmtree(ASSETS)          # start clean so removed frames don't linger
    ASSETS.mkdir(parents=True)
    info = {"author": "xcode", "version": 1}
    (ASSETS / "Contents.json").write_text(json.dumps({"info": info}, indent=2) + "\n")
    for name in ("walk", "jump", "stand", "nap", "spring", "sleep") + TRANSITIONS:
        for one_x in sorted(folder_for(name).glob(f"{name}_[0-9][0-9].png")):
            stem = one_x.stem
            folder = ASSETS / f"{stem}.imageset"
            folder.mkdir()
            shutil.copy(one_x, folder / f"{stem}.png")
            shutil.copy(one_x.with_name(f"{stem}@2x.png"), folder / f"{stem}@2x.png")
            (folder / "Contents.json").write_text(json.dumps({
                "images": [
                    {"filename": f"{stem}.png", "idiom": "universal", "scale": "1x"},
                    {"filename": f"{stem}@2x.png", "idiom": "universal", "scale": "2x"},
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
    save_transition_preview(sprites)


def save_transition_preview(sprites):
    """A GIF of a whole cycle with its transitions: walk → flop → nap → wake → walk → dive →
    hot spring → emerge → stand, on a light and a dark menu bar, zoomed 4x."""
    seq = []
    def add(name, repeat, ms):
        for _ in range(repeat):
            seq.extend((frame, ms) for frame in sprites[name])
    add("walk", 2, 125); add("flop", 1, 100); add("nap", 3, 333); add("wake", 1, 100)
    add("walk", 2, 125); add("dive", 1, 100); add("spring", 1, 250); add("emerge", 1, 100)
    add("stand", 1, 1200)
    zoom = 4
    w = max(f.width for f, _ in seq)
    h = max(f.height for f, _ in seq)
    frames, durations = [], []
    for frame, ms in seq:
        bar = Image.new("RGBA", (w * 2 + 24, h + 8), (0, 0, 0, 0))
        for i, bg in enumerate([(236, 236, 236, 255), (36, 36, 38, 255)]):
            tile = Image.new("RGBA", (w + 12, h + 8), bg)
            tile.alpha_composite(frame, (6, 4))
            bar.paste(tile, (i * (w + 12), 0))
        frames.append(bar.resize((bar.width * zoom, bar.height * zoom), Image.NEAREST).convert("RGB"))
        durations.append(ms)
    frames[0].save(OUT / "preview" / "transitions.gif", save_all=True,
                   append_images=frames[1:], duration=durations, loop=0, disposal=2)


if __name__ == "__main__":
    save_all()
    print("Wrote sprites to", OUT)
