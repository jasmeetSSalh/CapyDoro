# Art drop folder

Put raw art here. This folder is **not** part of the app target; Claude imports
files from here into `CapyDoro/Assets.xcassets`. Missing files are fine, because the app
falls back to SF Symbols.

```
Art/
├── app-icon/   icon-1024.png        (+ optional icon-foreground.png, icon-background.png)
├── menubar/    capybara.svg         (or capybara.png + capybara@2x.png)
├── sprites/
│   ├── walk/   walk_01.png … walk_08.png    focus running   (8 frames ideal)
│   ├── stand/  stand_01.png …               idle / waiting  (1+ frames)
│   ├── nap/    nap_01.png …                 short break     (1+ frames)
│   ├── spring/ spring_01.png …              long break      (1+ frames)
│   └── sleep/  sleep_01.png …               paused          (1+ frames)
└── sound/      chime.wav  (optional)
```

## Rules for every image
- **PNG with real transparency** (alpha channel). AI tools often paint a fake grey/white
  checkerboard into the pixels. Open the file in Preview: if you see a checkerboard *in the
  image itself*, it's fake and needs removing.
- **sRGB** colour.
- **Lowercase file names**, underscore, **two-digit frame numbers**: `walk_01.png`, not `Walk 1.png`.

## App icon: `app-icon/icon-1024.png`
- Exactly **1024 × 1024 px**, square.
- **Full-bleed**: fill the whole square, with **no rounded corners and no drop shadow**.
  macOS 26+ applies its own rounded shape and glass effect.
- Keep the capybara inside the middle ~80% so nothing gets clipped.
- Optional but better: give the capybara alone on a transparent background
  (`icon-foreground.png`) and the background alone (`icon-background.png`), both 1024 × 1024.
  Then the icon can use the layered Liquid Glass style.

## Menu bar icon: `menubar/`
- **Preferred: `capybara.svg`**, a single-colour **black** silhouette on transparent, square-ish.
- Or PNGs: `capybara.png` **18 px tall** and `capybara@2x.png` **36 px tall**, same art.
- Black only. macOS recolours it white/grey for dark menu bars (a "template image").
  Thin details under 1 px disappear, so keep the shape chunky.

## Sprites: `sprites/<pose>/`
- Pixel art, drawn at **18 px tall** (the menu bar height), then exported **2× with
  nearest-neighbour scaling** (no smoothing) to **36 px tall**. Only send the 36 px files.
- **Every frame in every pose uses the same canvas size** (e.g. 36 × 36, or up to 54 × 36 for
  a long capybara) and the capybara stands on the **same baseline in the same spot**.
  Otherwise it jitters.
- Colour is allowed, but check it reads on both a light and a dark menu bar. Black-only
  sprites get auto-tinted like the icon.
- Walk: 6–8 frames, plays at 8 fps. Other poses: 1 frame is fine, 2–4 frames loop at 3 fps.
- If your AI tool outputs big images (e.g. 1024 px), send them anyway with a note saying
  "drawn at N px per pixel" and Claude will downscale exactly. Don't resize them yourself
  with smoothing.

## Optional chime: `sound/chime.wav`
- WAV or AIFF, **under 2 seconds**, 44.1 kHz. If missing, the app uses the macOS "Glass" sound.
