#!/usr/bin/env python3
"""Draws the Shah Exchange app icon as SVG (no dependencies), then render_icons.gd turns the SVGs into PNGs.

    python3 tools/make_icon.py                      # writes godot/icon.svg and godot/assets/icon/*.svg
    godot --headless --path godot -s ../tools/render_icons.gd    # writes the PNGs next to them

The icon: a synthwave night sky and neon grid floor, with a cream playing card holding a pixel crown
(Shah = king) in front of a second, cyan-edged card. Everything is rectangles, so it stays crisp at any size.
iOS gets one full-bleed 1024 icon (the system rounds the corners). Android gets an adaptive icon: a background
layer and a foreground layer whose artwork stays inside the central 66% so no launcher shape can cut it.
"""
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "godot")
ASSETS = os.path.join(OUT, "assets", "icon")

INK = "#120A2E"
CREAM = "#FFF6DC"
PINK = "#FF2E93"
CYAN = "#22E5FF"
YELLOW = "#FFE14D"
ORANGE = "#FF9A1F"
PURPLE = "#B084FF"
RED = "#E0194A"

CROWN = [
    ".X.....X.....X.",
    ".XX...XXX...XX.",
    ".XXX.XXXXX.XXX.",
    ".XXXXXXXXXXXXX.",
    ".XXXXXXXXXXXXX.",
    ".XXXXXXXXXXXXX.",
    ".XXXXXXXXXXXXX.",
    ".XXXXXXXXXXXXX.",
]
JEWELS = {(5, 3), (5, 7), (5, 11)}  # (row, column) cells painted pink
BAND_ROWS = {6, 7}  # lower rows shaded orange

LETTER_K = ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"]


def rect(x, y, w, h, fill, extra=""):
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" fill="{fill}"{extra}/>'


def pixel_art(grid, cell, ox, oy, colour, outline=None, outline_size=0.0, override=None):
    """Rectangles for every '#'/'X' cell; optional sticker-style outline drawn underneath."""
    parts = []
    filled = [(r, c) for r, row in enumerate(grid) for c, ch in enumerate(row) if ch in "#X"]
    if outline:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)):
            for r, c in filled:
                parts.append(rect(ox + c * cell + dx * outline_size, oy + r * cell + dy * outline_size, cell, cell, outline))
    for r, c in filled:
        fill = override(r, c) if override else colour
        parts.append(rect(ox + c * cell, oy + r * cell, cell, cell, fill))
    return "".join(parts)


def crown(cell, ox, oy):
    def colour(r, c):
        if (r, c) in JEWELS:
            return PINK
        return ORANGE if r in BAND_ROWS else YELLOW
    glow = ""
    centre = (ox + len(CROWN[0]) * cell / 2, oy + len(CROWN) * cell / 2)
    for i, opacity in enumerate((0.10, 0.14, 0.18)):
        radius = cell * (9 - i * 2)
        glow += f'<circle cx="{centre[0]:.1f}" cy="{centre[1]:.1f}" r="{radius:.1f}" fill="{PINK}" opacity="{opacity}"/>'
    return glow + pixel_art(CROWN, cell, ox, oy, YELLOW, outline=INK, outline_size=cell * 0.4, override=colour)


def card(width, height, rotation, cx, cy, body):
    """A card centred on (cx, cy), rotated, with chunky ink border and pixel-cut corners."""
    x, y = cx - width / 2, cy - height / 2
    border = width * 0.035
    notch = width * 0.06
    shape = (
        rect(x + notch, y, width - 2 * notch, height, INK)
        + rect(x, y + notch, width, height - 2 * notch, INK)
        + rect(x + border + notch, y + border, width - 2 * border - 2 * notch, height - 2 * border, CREAM)
        + rect(x + border, y + border + notch, width - 2 * border, height - 2 * border - 2 * notch, CREAM)
    )
    return f'<g transform="rotate({rotation} {cx} {cy})">{shape}{body}</g>'


def card_back(width, height, rotation, cx, cy):
    x, y = cx - width / 2, cy - height / 2
    notch = width * 0.06
    border = width * 0.05
    shape = (
        rect(x + notch, y, width - 2 * notch, height, CYAN)
        + rect(x, y + notch, width, height - 2 * notch, CYAN)
        + rect(x + border + notch, y + border, width - 2 * border - 2 * notch, height - 2 * border, "#2A1478")
        + rect(x + border, y + border + notch, width - 2 * border, height - 2 * border - 2 * notch, "#2A1478")
    )
    cell = width * 0.07
    pattern = ""
    cols = int((width - 2 * border) / cell) - 1
    rows = int((height - 2 * border) / cell) - 1
    for r in range(rows):
        for c in range(cols):
            if (r + c) % 2 == 0:
                pattern += rect(x + border + cell * 0.5 + c * cell, y + border + cell * 0.5 + r * cell, cell, cell, "#4A32B8")
    return f'<g transform="rotate({rotation} {cx} {cy})">{shape}{pattern}</g>'


def background(size):
    """Night sky, a pink horizon glow, stars and a neon perspective grid."""
    s = size
    horizon = s * 0.62
    parts = [
        f'<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="#08031C"/><stop offset="0.6" stop-color="#2B0F73"/>'
        f'<stop offset="1" stop-color="#5A1A9E"/></linearGradient></defs>',
        rect(0, 0, s, s, "url(#sky)"),
    ]
    # horizon glow: stacked translucent bands
    for i in range(8):
        h = s * 0.012 * (8 - i)
        parts.append(rect(0, horizon - h, s, h * 2, PINK, f' opacity="{0.05 + 0.03 * i:.2f}"'))
    parts.append(rect(0, horizon - s * 0.004, s, s * 0.008, "#FF7AC0"))
    # floor
    parts.append(rect(0, horizon, s, s - horizon, "#1A0B47"))
    for i in range(-9, 10):
        x_bottom = s / 2 + i * s * 0.14
        parts.append(
            f'<line x1="{s / 2:.1f}" y1="{horizon:.1f}" x2="{x_bottom:.1f}" y2="{s:.1f}" stroke="{PURPLE}" stroke-width="{s * 0.006:.1f}" opacity="0.55"/>'
        )
    for i in range(1, 7):
        t = (i / 7) ** 2
        y = horizon + (s - horizon) * t
        parts.append(rect(0, y, s, s * 0.005, PURPLE, ' opacity="0.5"'))
    # stars
    stars = [(0.12, 0.10), (0.30, 0.22), (0.80, 0.12), (0.90, 0.30), (0.20, 0.45), (0.68, 0.06), (0.52, 0.30), (0.93, 0.50), (0.07, 0.30)]
    for sx, sy in stars:
        d = s * (0.012 if (sx * 10) % 2 < 1 else 0.007)
        parts.append(rect(sx * s, sy * s, d, d, "#FFFFFF", ' opacity="0.85"'))
    return "".join(parts)


def hero(size, scale=1.0, offset=(0.0, 0.0)):
    """The two cards and the crown, drawn for a canvas of `size`, shrunk by `scale` about the centre."""
    s = size
    cx, cy = s / 2 + offset[0], s / 2 + offset[1]
    cw, ch = s * 0.50 * scale, s * 0.68 * scale
    back = card_back(cw, ch, 11, cx + s * 0.09 * scale, cy - s * 0.01 * scale)
    cell = cw * 0.056
    crown_w, crown_h = len(CROWN[0]) * cell, len(CROWN) * cell
    front_cx, front_cy = cx - s * 0.04 * scale, cy + s * 0.01 * scale
    k_cell = cw * 0.026
    body = (
        crown(cell, front_cx - crown_w / 2, front_cy - crown_h / 2 + ch * 0.02)
        + pixel_art(LETTER_K, k_cell, front_cx - cw / 2 + cw * 0.09, front_cy - ch / 2 + ch * 0.07, PINK)
        + pixel_art(LETTER_K, k_cell, front_cx + cw / 2 - cw * 0.09 - 5 * k_cell, front_cy + ch / 2 - ch * 0.07 - 7 * k_cell, PINK)
    )
    front = card(cw, ch, -7, front_cx, front_cy, body)
    return back + front


def svg(size, content):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">{content}</svg>\n'


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as handle:
        handle.write(text)
    print("wrote", os.path.relpath(path, os.path.join(HERE, "..")))


def main():
    full = svg(1024, background(1024) + hero(1024, 1.0))
    write(os.path.join(OUT, "icon.svg"), full)
    # Android adaptive icon: 432 canvas (108 dp), artwork inside the central 66% (the 72 dp safe zone).
    write(os.path.join(ASSETS, "android_background.svg"), svg(432, background(432)))
    write(os.path.join(ASSETS, "android_foreground.svg"), svg(432, hero(432, 0.66)))
    # One-colour version for Android 13 themed icons.
    mono = hero(432, 0.66).replace(CREAM, "#FFFFFF").replace(INK, "#FFFFFF").replace(PINK, "#FFFFFF")
    for colour in (YELLOW, ORANGE, CYAN, "#2A1478", "#4A32B8"):
        mono = mono.replace(colour, "#FFFFFF")
    write(os.path.join(ASSETS, "android_monochrome.svg"), svg(432, mono))


if __name__ == "__main__":
    main()
