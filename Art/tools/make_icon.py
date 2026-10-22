#!/usr/bin/env python3
"""
Builds the app icon and the menu bar icon from the logo SVGs (the originals are not changed).

App icon (Art/app-icon/CapyDoro_App_Logo.svg):

1. Copies the SVG without the light rounded frame (macOS draws its own rounded shape)
   and with a square viewBox centred on the capybara.
2. Renders it to 1024 px with QuickLook (built into macOS).
3. Writes every size macOS wants into CapyDoro/Assets.xcassets/AppIcon.appiconset.

Menu bar icon (Art/menubar/CapyDoro_App_Logo_B&W_Menu_Logo.svg):
   Crops the empty margin, sizes it to MENUBAR_PT points and saves it as a vector
   *template* image in Assets.xcassets/MenuBarIcon.imageset (macOS tints it for
   light/dark menu bars).

Run from the CapyDoro folder:  python3 Art/tools/make_icon.py
Needs Pillow (pip install pillow). Dev-only; nothing here ships in the app.
"""
import json, re, subprocess, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "Art/app-icon/CapyDoro_App_Logo.svg"
OUT_SVG = ROOT / "Art/app-icon/generated/icon-square.svg"
ICONSET = ROOT / "CapyDoro/Assets.xcassets/AppIcon.appiconset"

FRAME_FILL = "#ffeac5"       # the rounded frame ring, drawn as one path on top
SQUARE_VIEWBOX = "0 15.5 1367 1367"   # 1367 wide; centred vertically on the art (1398 tall)

MENUBAR_SRC = ROOT / "Art/menubar/CapyDoro_App_Logo_B&W_Menu_Logo.svg"
MENUBAR_SET = ROOT / "CapyDoro/Assets.xcassets/MenuBarIcon.imageset"
MENUBAR_VIEWBOX = "105.5 107 290 290"   # the capybara (measured at 108–393 × 108–396) + ~2 units
MENUBAR_PT = 18                         # menu bar icons are ~16–18 pt tall


def square_svg() -> str:
    svg = SRC.read_text()
    frame = re.findall(rf'\s*<path d="[^"]*" fill="{FRAME_FILL}"\s*/>', svg)
    assert len(frame) == 1, f"expected exactly one frame path, found {len(frame)}"
    svg = svg.replace(frame[0], "")
    svg = re.sub(r'width="\d+" height="\d+" viewBox="[^"]*"',
                 f'width="1024" height="1024" viewBox="{SQUARE_VIEWBOX}"', svg, count=1)
    return svg


def render_1024(svg_path: Path) -> Image.Image:
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", tmp, str(svg_path)],
                       check=True, capture_output=True)
        png = Path(tmp) / (svg_path.name + ".png")
        img = Image.open(png).convert("RGB")   # opaque: macOS applies the rounded mask
        img.load()
    assert img.size == (1024, 1024), img.size
    return img


def write_iconset(master: Image.Image):
    images = []
    for points in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            px = points * scale
            name = f"icon_{points}x{points}{'@2x' if scale == 2 else ''}.png"
            master.resize((px, px), Image.LANCZOS).save(ICONSET / name)
            images.append({"filename": name, "idiom": "mac",
                           "scale": f"{scale}x", "size": f"{points}x{points}"})
    (ICONSET / "Contents.json").write_text(json.dumps(
        {"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def write_menubar_icon():
    svg = MENUBAR_SRC.read_text()
    svg, n = re.subn(r'viewBox="[^"]*"', f'viewBox="{MENUBAR_VIEWBOX}"', svg, count=1)
    assert n == 1
    svg, n = re.subn(r'width="\d+" height="\d+"', f'width="{MENUBAR_PT}" height="{MENUBAR_PT}"', svg, count=1)
    assert n == 1
    MENUBAR_SET.mkdir(exist_ok=True)
    (MENUBAR_SET / "menubar-capybara.svg").write_text(svg)
    (MENUBAR_SET / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "menubar-capybara.svg", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "preserves-vector-representation": True,   # stays sharp at any size
            "template-rendering-intent": "template",    # macOS recolours it for light/dark
        },
    }, indent=2) + "\n")


if __name__ == "__main__":
    OUT_SVG.parent.mkdir(exist_ok=True)
    OUT_SVG.write_text(square_svg())
    master = render_1024(OUT_SVG)
    master.save(OUT_SVG.with_name("icon-1024.png"))
    write_iconset(master)
    write_menubar_icon()
    print("Wrote", OUT_SVG.parent, ICONSET, "and", MENUBAR_SET)
