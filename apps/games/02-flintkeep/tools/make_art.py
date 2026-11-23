#!/usr/bin/env python3
"""Writes the game's vector art (SVG) into godot/assets/art/.

Every sprite is drawn in a 3/4 top-down view, lit from the top left, standing on its "foot"
point at the bottom centre of the canvas (see FOOT in godot/ui/art.gd). Edit a function and
re-run:  python3 tools/make_art.py
An artist can also replace any SVG by hand; keep the canvas size and foot point.
"""
import math
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "godot", "assets", "art")

DEFS = """
<linearGradient id="stone" x1="0" x2="1"><stop offset="0" stop-color="#f4efff"/><stop offset="0.22" stop-color="#f4efff"/><stop offset="0.22" stop-color="#cfc8e6"/><stop offset="0.68" stop-color="#cfc8e6"/><stop offset="0.68" stop-color="#9d93c2"/><stop offset="1" stop-color="#9d93c2"/></linearGradient>
<linearGradient id="stoneDark" x1="0" x2="1"><stop offset="0" stop-color="#8f78d6"/><stop offset="0.3" stop-color="#8f78d6"/><stop offset="0.3" stop-color="#6a52b8"/><stop offset="0.7" stop-color="#6a52b8"/><stop offset="0.7" stop-color="#4a3590"/><stop offset="1" stop-color="#4a3590"/></linearGradient>
<linearGradient id="wood" x1="0" x2="1"><stop offset="0" stop-color="#ffb86a"/><stop offset="0.25" stop-color="#ffb86a"/><stop offset="0.25" stop-color="#e38a3d"/><stop offset="0.7" stop-color="#e38a3d"/><stop offset="0.7" stop-color="#b8602a"/><stop offset="1" stop-color="#b8602a"/></linearGradient>
<linearGradient id="roofRed" x1="0" x2="1"><stop offset="0" stop-color="#ff8a74"/><stop offset="0.35" stop-color="#ff8a74"/><stop offset="0.35" stop-color="#f2463c"/><stop offset="0.75" stop-color="#f2463c"/><stop offset="0.75" stop-color="#c22a2f"/><stop offset="1" stop-color="#c22a2f"/></linearGradient>
<linearGradient id="roofBlue" x1="0" x2="1"><stop offset="0" stop-color="#7cc4ff"/><stop offset="0.35" stop-color="#7cc4ff"/><stop offset="0.35" stop-color="#3a8cff"/><stop offset="0.75" stop-color="#3a8cff"/><stop offset="0.75" stop-color="#2a5fd0"/><stop offset="1" stop-color="#2a5fd0"/></linearGradient>
<linearGradient id="roofGreen" x1="0" x2="1"><stop offset="0" stop-color="#9df06a"/><stop offset="0.35" stop-color="#9df06a"/><stop offset="0.35" stop-color="#4cc23f"/><stop offset="0.75" stop-color="#4cc23f"/><stop offset="0.75" stop-color="#2e8a35"/><stop offset="1" stop-color="#2e8a35"/></linearGradient>
<linearGradient id="iron" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#8f9bb8"/><stop offset="0.35" stop-color="#8f9bb8"/><stop offset="0.35" stop-color="#5b6582"/><stop offset="1" stop-color="#3d4560"/></linearGradient>
<linearGradient id="brass" x1="0" x2="1"><stop offset="0" stop-color="#fff2a0"/><stop offset="0.3" stop-color="#fff2a0"/><stop offset="0.3" stop-color="#ffc93c"/><stop offset="0.75" stop-color="#ffc93c"/><stop offset="0.75" stop-color="#d98a1a"/><stop offset="1" stop-color="#d98a1a"/></linearGradient>
<linearGradient id="floor" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#fff4dc"/><stop offset="0.5" stop-color="#fff4dc"/><stop offset="0.5" stop-color="#e6d3b0"/><stop offset="1" stop-color="#e6d3b0"/></linearGradient>
<radialGradient id="crystal" cx="0.35" cy="0.3" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#aefbff"/><stop offset="0.7" stop-color="#2fd6ff"/><stop offset="1" stop-color="#1c8fe0"/></radialGradient>
<radialGradient id="violet" cx="0.35" cy="0.3" r="0.75"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#f6c8ff"/><stop offset="0.7" stop-color="#c158ff"/><stop offset="1" stop-color="#8a2be2"/></radialGradient>
<radialGradient id="glowCyan"><stop offset="0" stop-color="#7ff6ff" stop-opacity="0.85"/><stop offset="1" stop-color="#7ff6ff" stop-opacity="0"/></radialGradient>
<radialGradient id="glowViolet"><stop offset="0" stop-color="#e3a6ff" stop-opacity="0.85"/><stop offset="1" stop-color="#e3a6ff" stop-opacity="0"/></radialGradient>
<radialGradient id="shadow"><stop offset="0" stop-color="#103a1a" stop-opacity="0.45"/><stop offset="1" stop-color="#103a1a" stop-opacity="0"/></radialGradient>
<linearGradient id="skin" x1="0" x2="1"><stop offset="0" stop-color="#c8f56a"/><stop offset="0.35" stop-color="#c8f56a"/><stop offset="0.35" stop-color="#7fd23a"/><stop offset="1" stop-color="#4fa82a"/></linearGradient>
<linearGradient id="tunicRed" x1="0" x2="1"><stop offset="0" stop-color="#ff7a6a"/><stop offset="0.35" stop-color="#ff7a6a"/><stop offset="0.35" stop-color="#e83a3a"/><stop offset="1" stop-color="#b8222e"/></linearGradient>
<linearGradient id="tunicOrange" x1="0" x2="1"><stop offset="0" stop-color="#ffc06a"/><stop offset="0.35" stop-color="#ffc06a"/><stop offset="0.35" stop-color="#ff8a1f"/><stop offset="1" stop-color="#d0600f"/></linearGradient>
<linearGradient id="plate" x1="0" x2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="#ffffff"/><stop offset="0.3" stop-color="#bfc8e0"/><stop offset="0.72" stop-color="#bfc8e0"/><stop offset="0.72" stop-color="#8590b4"/><stop offset="1" stop-color="#8590b4"/></linearGradient>
<linearGradient id="wyvern" x1="0" x2="1"><stop offset="0" stop-color="#d79bff"/><stop offset="0.35" stop-color="#d79bff"/><stop offset="0.35" stop-color="#a24dff"/><stop offset="1" stop-color="#6d24c9"/></linearGradient>
<linearGradient id="gold" x1="0" x2="1" y1="0" y2="1"><stop offset="0" stop-color="#fff6b0"/><stop offset="0.4" stop-color="#ffd43a"/><stop offset="1" stop-color="#f09a12"/></linearGradient>
"""


OUTLINE = "#3a2218"


def svg(w, h, body, outline=3.2):
    """Cartoon outline: the art is drawn twice, first with a thick dark stroke on every shape,
    then plainly on top, so only the outer silhouette keeps its outline. Shadows and glows sit
    outside the outline (anything before the <!--art--> marker)."""
    back, _, art = body.rpartition("<!--art-->") if "<!--art-->" in body else ("", "", body)
    inked = (f'<g stroke="{OUTLINE}" stroke-width="{outline}" stroke-linejoin="round" stroke-linecap="round">{art}</g>'
             if outline > 0 else "")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="-4 -4 {w + 8} {h + 8}">'
            f"<defs>{DEFS}</defs>{back}{inked}{art}</svg>")


def gloss(cx, cy, rx, ry, rot=-25, opacity=0.55):
    """The glossy highlight casual art puts in the same top-left spot on every object."""
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" transform="rotate({rot} {cx} {cy})" fill="#ffffff" opacity="{opacity}" stroke="none"/>'


def shadow(cx, cy, rx, ry):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#shadow)"/><!--art-->'


def cylinder(x0, x1, top, bottom, fill, ry=None):
    """A round tower body seen from slightly above: straight sides, curved bottom edge."""
    rx = (x1 - x0) / 2
    ry = ry if ry is not None else rx * 0.28
    return (f'<path d="M{x0} {top} L{x0} {bottom} A{rx} {ry} 0 0 0 {x1} {bottom} L{x1} {top} '
            f'A{rx} {ry} 0 0 1 {x0} {top} Z" fill="{fill}"/>')


def courses(x0, x1, ys, ry=None, color="#000", opacity=0.18):
    """Curved mortar lines between stone courses, plus staggered joints."""
    rx = (x1 - x0) / 2
    ry = ry if ry is not None else rx * 0.28
    out = []
    for i, y in enumerate(ys):
        out.append(f'<path d="M{x0} {y} A{rx} {ry} 0 0 0 {x1} {y}" stroke="{color}" stroke-opacity="{opacity}" stroke-width="1.2" fill="none"/>')
    for i in range(len(ys) - 1):
        for k in range(4):
            t = (k + (0.5 if i % 2 else 0.0) + 0.5) / 4.5
            ang = math.pi * t
            x = (x0 + x1) / 2 - rx * math.cos(ang)
            y = ys[i] + ry * math.sin(ang)
            out.append(f'<line x1="{x:.1f}" y1="{y + 1:.1f}" x2="{x:.1f}" y2="{y + (ys[i+1]-ys[i]) - 1:.1f}" stroke="#000" stroke-opacity="{opacity}" stroke-width="1"/>')
    return "".join(out)


def merlons(cx, cy, rx, ry, count, w, h, fill, front=True):
    out = []
    for i in range(count):
        a = math.pi * (i + 0.5) / count if front else math.pi + math.pi * (i + 0.5) / count
        x = cx - rx * math.cos(a)
        y = cy + ry * math.sin(a)
        out.append(f'<rect x="{x - w / 2:.1f}" y="{y - h:.1f}" width="{w}" height="{h + 2}" rx="1" fill="{fill}" stroke="#2a2620" stroke-opacity="0.5" stroke-width="0.8"/>')
    return "".join(out)


# --- Buildings ----------------------------------------------------------------------------------

def keep():
    return svg(120, 150, keep_body())


def keep_body():
    b = shadow(60, 146, 54, 10)
    b += cylinder(20, 100, 56, 138, "url(#stone)", 11)
    b += courses(20, 100, [72, 88, 104, 120], 11)
    # door and arrow slits
    b += '<path d="M50 146 L50 124 A10 10 0 0 1 70 124 L70 146 Z" fill="#c9c3b6"/>'
    b += '<path d="M52.5 146 L52.5 125 A7.5 7.5 0 0 1 67.5 125 L67.5 146 Z" fill="#4a2c18"/>'
    b += '<line x1="60" y1="118" x2="60" y2="146" stroke="#2c1a0e" stroke-width="1"/>'
    b += '<circle cx="64" cy="134" r="1.2" fill="#ffd36b"/>'
    for x in (34, 86):
        b += f'<rect x="{x - 2.5}" y="82" width="5" height="14" rx="2.5" fill="#1d1712"/>'
        b += f'<rect x="{x - 1.2}" y="86" width="2.4" height="7" rx="1.2" fill="#ffb347"/>'
    # brass band under the parapet
    b += '<path d="M20 58 A40 11 0 0 0 100 58" stroke="url(#brass)" stroke-width="3" fill="none"/>'
    # parapet: back merlons, floor, front face, front merlons
    b += merlons(60, 42, 46, 12, 6, 8, 8, "#a8a294", front=False)
    b += '<ellipse cx="60" cy="42" rx="48" ry="13" fill="url(#floor)"/>'
    b += '<ellipse cx="60" cy="42" rx="38" ry="9" fill="#6d675d"/>'
    b += cylinder(12, 108, 42, 54, "url(#stone)", 13)
    b += '<path d="M12 42 A48 13 0 0 0 108 42" stroke="#e6e0d2" stroke-width="1.2" fill="none"/>'
    # arcane crystal on its pedestal
    b += '<circle cx="60" cy="18" r="20" fill="url(#glowCyan)" stroke="none"/>'
    b += cylinder(53, 67, 30, 44, "url(#stoneDark)", 3)
    b += '<polygon points="60,2 69,18 60,34 51,18" fill="url(#crystal)" stroke="#0e5f7d" stroke-width="1"/>'
    b += '<polygon points="60,2 60,34 51,18" fill="#ffffff" opacity="0.35" stroke="none"/>'
    b += gloss(56, 13, 1.6, 4, 30, 0.8)
    b += merlons(60, 42, 46, 12, 7, 9, 10, "url(#stone)")
    # banner
    b += '<line x1="94" y1="6" x2="94" y2="46" stroke="#5b4a32" stroke-width="2"/>'
    b += '<path d="M95 7 L115 10 L110 15 L115 20 L95 22 Z" fill="url(#roofBlue)"/>'
    b += '<circle cx="102" cy="14.5" r="2.4" fill="#ffd36b"/>'
    return b


def tower_base(x0=16, x1=48, top=62, bottom=90):
    return cylinder(x0, x1, top, bottom, "url(#stone)") + courses(x0, x1, [top + 9, top + 18], None)


def musket(raw=False):
    b = shadow(32, 94, 26, 6)
    b += tower_base()
    b += cylinder(12, 52, 38, 63, "url(#wood)")
    for x in (17, 22, 27, 37, 42, 47):
        b += f'<line x1="{x}" y1="40" x2="{x}" y2="{63 + (5 - abs(x - 32) * 0.25):.1f}" stroke="#3a210f" stroke-opacity="0.45" stroke-width="1"/>'
    b += '<rect x="22" y="42" width="20" height="13" rx="2" fill="#1e130b"/>'
    b += '<rect x="28.5" y="43" width="7" height="4" rx="1" fill="#1b1b22"/>'  # shako
    b += '<circle cx="32" cy="49" r="3" fill="#e9b98d"/>'
    b += '<path d="M26 55 Q32 50 38 55 Z" fill="#2f5bb5"/>'
    b += '<line x1="34" y1="51" x2="55" y2="46" stroke="#2a2a2e" stroke-width="2.2" stroke-linecap="round"/>'
    b += '<line x1="34" y1="51" x2="42" y2="49.3" stroke="#7a4a22" stroke-width="2.6" stroke-linecap="round"/>'
    b += '<path d="M7 39 L32 6 L57 39 A25 7 0 0 1 7 39 Z" fill="url(#roofRed)"/>'
    b += '<path d="M7 39 A25 7 0 0 0 57 39" stroke="#8a1a1f" stroke-width="1.5" fill="none"/>'
    b += gloss(20, 26, 4, 9, 35)
    b += '<line x1="32" y1="6" x2="32" y2="0" stroke="#5b4a32" stroke-width="1.5"/>'
    b += '<path d="M32 0.5 L41 2.5 L32 5 Z" fill="#355fae"/>'
    return b if raw else svg(64, 100, b)


def cannon(raw=False):
    b = shadow(32, 94, 30, 6)
    b += cylinder(8, 56, 54, 88, "url(#stone)")
    b += courses(8, 56, [64, 74, 82])
    b += merlons(32, 52, 22, 6, 4, 7, 6, "#a8a294", front=False)
    b += '<ellipse cx="32" cy="52" rx="24" ry="7" fill="url(#floor)"/>'
    # gun carriage and barrel, aiming out over the wall
    b += '<rect x="20" y="44" width="18" height="7" rx="2" fill="url(#wood)"/>'
    b += '<g transform="rotate(-18 30 44)"><rect x="22" y="38" width="30" height="9" rx="4" fill="url(#iron)"/>'
    b += '<rect x="48" y="37" width="5" height="11" rx="2" fill="#2a2d35"/>'
    b += '<rect x="26" y="38" width="3" height="9" fill="url(#brass)"/></g>'
    b += '<circle cx="23" cy="51" r="5" fill="#5a3a1e" stroke="#2c1a0e" stroke-width="1.2"/>'
    b += '<circle cx="23" cy="51" r="1.5" fill="url(#brass)"/>'
    b += merlons(32, 54, 22, 7, 5, 7, 7, "url(#stone)")
    return b if raw else svg(64, 100, b)


def volley(raw=False):
    b = shadow(32, 94, 26, 6)
    b += tower_base(14, 50, 56, 90)
    b += cylinder(11, 53, 46, 58, "url(#wood)")
    b += '<ellipse cx="32" cy="46" rx="21" ry="6" fill="#a8774a"/>'
    b += '<g transform="rotate(35 32 40)">'
    for i in range(5):
        x = 22 + i * 4.4
        b += (f'<rect x="{x:.1f}" y="14" width="4" height="28" rx="1.5" fill="url(#iron)"/>'
              f'<rect x="{x - 0.3:.1f}" y="13" width="4.6" height="3" rx="1" fill="#22252c"/>')
    b += '<rect x="20" y="22" width="25" height="3" fill="url(#brass)"/></g>'
    b += '<rect x="18" y="38" width="24" height="7" rx="3" fill="url(#brass)"/>'
    b += '<circle cx="21" cy="47" r="4" fill="#5a3a1e" stroke="#2c1a0e"/><circle cx="41" cy="47" r="4" fill="#5a3a1e" stroke="#2c1a0e"/>'
    return b if raw else svg(64, 100, b)


def sniper(raw=False):
    b = shadow(32, 95, 20, 5)
    b += cylinder(20, 44, 34, 90, "url(#stone)")
    b += courses(20, 44, [44, 54, 64, 74, 82])
    b += cylinder(16, 48, 24, 36, "url(#wood)")
    b += '<rect x="22" y="26" width="20" height="9" rx="2" fill="#1e130b"/>'
    b += '<circle cx="31" cy="30" r="2.6" fill="#e9b98d"/>'
    b += '<path d="M27 26 L35 26 L33 23.5 L29 23.5 Z" fill="#1b1b22"/>'
    b += '<line x1="33" y1="31" x2="62" y2="26" stroke="#2a2a2e" stroke-width="1.8" stroke-linecap="round"/>'
    b += '<path d="M12 25 L32 2 L52 25 A20 6 0 0 1 12 25 Z" fill="url(#roofGreen)"/>'
    b += '<path d="M12 25 A20 6 0 0 0 52 25" stroke="#1f6a2a" stroke-width="1.3" fill="none"/>'
    b += gloss(22, 16, 3, 7, 40)
    return b if raw else svg(64, 100, b)


def arcane(raw=False):
    b = shadow(32, 95, 22, 5)
    b += '<path d="M18 90 L23 40 L41 40 L46 90 A14 4 0 0 1 18 90 Z" fill="url(#stoneDark)"/>'
    for y in (52, 64, 76):
        b += f'<path d="M{20 + (90 - y) * 0.1:.1f} {y} Q32 {y + 3} {44 - (90 - y) * 0.1:.1f} {y}" stroke="#000" stroke-opacity="0.25" fill="none"/>'
    for (x, y) in ((30, 58), (34, 70), (29, 82)):
        b += f'<path d="M{x} {y} l3 -4 l3 4 l-3 4 Z" fill="#c89bff"/>'
    b += '<ellipse cx="32" cy="40" rx="11" ry="3.5" fill="#3b2a5c" stroke="#c89bff" stroke-width="1"/>'
    b += '<circle cx="32" cy="20" r="18" fill="url(#glowViolet)" stroke="none"/>'
    b += '<polygon points="32,4 40,19 32,34 24,19" fill="url(#violet)" stroke="#4a1f86" stroke-width="1"/>'
    b += '<polygon points="32,4 32,34 24,19" fill="#ffffff" opacity="0.35" stroke="none"/>'
    b += gloss(28.5, 14, 1.5, 4, 30, 0.8)
    return b if raw else svg(64, 100, b)


def slot():
    """A round stone pedestal standing as tall as the walls; towers are built on top of it."""
    b = '<ellipse cx="32" cy="50" rx="27" ry="7" fill="url(#shadow)" stroke="none"/><!--art-->'
    b += cylinder(6, 58, 16, 46, "url(#stone)", 8)
    b += courses(6, 58, [28, 38], 8)
    b += '<ellipse cx="32" cy="16" rx="26" ry="8" fill="url(#floor)"/>'
    b += '<ellipse cx="32" cy="16" rx="18" ry="5.2" fill="none" stroke="#c9b48a" stroke-width="1.2"/>'
    b += '<path d="M27 16 L37 16 M32 13 L32 19" stroke="#b08a4a" stroke-width="2.4" stroke-linecap="round"/>'
    return svg(64, 52, b, 2.6)


# --- Tower upgrade looks ---------------------------------------------------------------------------
# Tier 2 (level 5+) adds a gold band and a banner; tier 3 (level 10+) adds a golden crown
# finial and a gem. One new privilege per step, so each tier reads as an upgrade of the last.
TIER_SPOTS = {  # band y, band half-width, crown point
    "musket": (61, 17, (32, 6)), "cannon": (64, 24, (32, 40)), "volley": (59, 18, (32, 36)),
    "sniper": (37, 12, (32, 2)), "arcane": (46, 10, (32, 3)),
}


def tiered(fn, name, tier):
    """Wraps a tower drawing with the extra details of `tier` (1, 2 or 3)."""
    body = fn(raw=True)
    y, hw, (cx, cy) = TIER_SPOTS[name]
    extra = ""
    if tier >= 2:
        extra += f'<path d="M{32 - hw} {y} A{hw} {hw * 0.28} 0 0 0 {32 + hw} {y}" fill="none" stroke="url(#brass)" stroke-width="3.2"/>'
        extra += (f'<path d="M{27} {y + 3} L{37} {y + 3} L{37} {y + 14} L{32} {y + 11} L{27} {y + 14} Z" fill="url(#roofBlue)"/>'
                  f'<circle cx="32" cy="{y + 7}" r="1.8" fill="#ffd23f"/>')
    if tier >= 3:
        extra += (f'<path d="M{cx - 5} {cy + 2} L{cx - 5} {cy - 4} L{cx - 2.5} {cy - 1} L{cx} {cy - 6} L{cx + 2.5} {cy - 1} L{cx + 5} {cy - 4} L{cx + 5} {cy + 2} Z" fill="url(#gold)"/>'
                  f'<circle cx="32" cy="{y + 7}" r="2.6" fill="url(#crystal)"/>' + gloss(cx - 2, cy - 2, 1, 2, 30, 0.8))
    return svg(64, 100, body + extra)


# --- Enemies (goblin raiders) --------------------------------------------------------------------

def goblin(tunic, weapon, helmet=True, w=40, h=48, step=False, extra=""):
    b = shadow(20, 45, 12, 3)
    if step:  # second walking frame: one leg forward, one back
        b += '<rect x="11" y="33" width="5" height="11" rx="2" fill="#3d5a24" transform="rotate(18 13 34)"/><rect x="23" y="34" width="5" height="11" rx="2" fill="#3d5a24" transform="rotate(-14 25 35)"/>'
    else:
        b += '<rect x="13" y="34" width="5" height="11" rx="2" fill="#3d5a24"/><rect x="22" y="34" width="5" height="11" rx="2" fill="#3d5a24"/>'
    b += extra
    b += f'<path d="M11 22 Q20 17 29 22 L28 37 Q20 40 12 37 Z" fill="url(#{tunic})"/>'
    b += '<rect x="12" y="32" width="16" height="3" fill="#4a2c18"/>'
    b += '<path d="M6 10 L14 13 L13 17 Z" fill="#6fa83d"/><path d="M34 10 L26 13 L27 17 Z" fill="#4f8a2f"/>'
    b += '<ellipse cx="20" cy="14" rx="8" ry="8" fill="url(#skin)"/>'
    b += '<circle cx="17" cy="14" r="1.5" fill="#ffd23f"/><circle cx="23" cy="14" r="1.5" fill="#ffd23f"/>'
    b += '<path d="M17 19 L23 19" stroke="#2c4a17" stroke-width="1"/>'
    if helmet:
        b += '<path d="M11.5 11 A8.5 7 0 0 1 28.5 11 Z" fill="url(#iron)"/>'
    b += weapon
    return svg(w, h, b)


def footman(step=False):
    axe = '<line x1="30" y1="16" x2="33" y2="38" stroke="#5a3a1e" stroke-width="2"/><path d="M29 14 Q38 12 37 22 L31 20 Z" fill="#b7bcc6" stroke="#4a4e58" stroke-width="0.8"/>'
    return goblin("tunicRed", axe, step=step)


def runner(step=False):
    dagger = '<line x1="29" y1="26" x2="35" y2="18" stroke="#c3c8d2" stroke-width="2" stroke-linecap="round"/>'
    hood = '<path d="M11 13 Q20 2 29 13 L27 9 Q20 4 13 9 Z" fill="#7a3f12"/>'
    return goblin("tunicOrange", dagger + hood, helmet=False, step=step)


def sapper(step=False):
    """Carries a big bomb to the wall and blows himself up against it."""
    bomb = ('<circle cx="9" cy="24" r="8" fill="url(#iron)"/>'
            + gloss(6.5, 21, 2, 3, 30, 0.6)
            + '<path d="M13 17 Q16 12 19 13" fill="none" stroke="#7a4a22" stroke-width="1.6"/>'
            + '<circle cx="19.5" cy="12.5" r="2.2" fill="#ffd23f" stroke="none"/><circle cx="19.5" cy="12.5" r="1" fill="#ff6a00" stroke="none"/>')
    goggles = '<rect x="13" y="11" width="14" height="4" rx="2" fill="#7a4a22"/><circle cx="17" cy="13" r="1.8" fill="#9ff4ff"/><circle cx="23" cy="13" r="1.8" fill="#9ff4ff"/>'
    return goblin("wood", goggles, helmet=False, step=step, extra=bomb)


def shaman(step=False):
    """Heals the raiders around him."""
    staff = ('<line x1="32" y1="8" x2="30" y2="42" stroke="#6b4524" stroke-width="2.2"/>'
             '<circle cx="32" cy="7" r="4.5" fill="#7dff9a"/>' + gloss(30.5, 5.5, 1.2, 2, 30, 0.8))
    robe = '<path d="M11 22 Q20 17 29 22 L31 42 Q20 45 9 42 Z" fill="url(#wyvern)"/>'
    feathers = '<path d="M14 7 L11 -1 L16 5 Z M20 5 L20 -3 L22 5 Z M26 7 L29 -1 L24 5 Z" fill="#ffcf3a"/>'
    return goblin("wyvern", staff + feathers, helmet=False, step=step, extra=robe)


def brute(step=False):
    b = shadow(30, 61, 20, 4)
    if step:
        b += '<rect x="15" y="45" width="10" height="15" rx="3" fill="url(#iron)" transform="rotate(14 20 46)"/><rect x="35" y="46" width="10" height="15" rx="3" fill="url(#iron)" transform="rotate(-10 40 47)"/>'
    else:
        b += '<rect x="17" y="46" width="10" height="15" rx="3" fill="url(#iron)"/><rect x="33" y="46" width="10" height="15" rx="3" fill="url(#iron)"/>'
    b += '<ellipse cx="9" cy="34" rx="6" ry="10" fill="url(#skin)"/><ellipse cx="51" cy="34" rx="6" ry="10" fill="url(#skin)"/>'
    b += '<path d="M10 22 Q30 12 50 22 L48 50 Q30 56 12 50 Z" fill="url(#plate)" stroke="#3a3e48" stroke-width="1"/>'
    b += '<path d="M30 18 L30 52" stroke="#e7ebf2" stroke-opacity="0.5" stroke-width="2"/>'
    b += '<circle cx="18" cy="30" r="1.6" fill="#e7ebf2"/><circle cx="42" cy="30" r="1.6" fill="#e7ebf2"/>'
    b += '<ellipse cx="30" cy="13" rx="9" ry="8" fill="url(#skin)"/>'
    b += '<path d="M20 12 A10 8 0 0 1 40 12 L38 8 L30 3 L22 8 Z" fill="url(#iron)"/>'
    b += '<path d="M21 8 L15 1 L23 6 Z M39 8 L45 1 L37 6 Z" fill="#e8dcc0"/>'
    b += '<rect x="25" y="13" width="10" height="2" fill="#1e2026"/><circle cx="27" cy="14" r="1" fill="#ff5a3c"/><circle cx="33" cy="14" r="1" fill="#ff5a3c"/>'
    b += '<line x1="54" y1="20" x2="52" y2="44" stroke="#5a3a1e" stroke-width="4" stroke-linecap="round"/><ellipse cx="54" cy="18" rx="4" ry="6" fill="#6b4524"/>'
    return svg(60, 64, b)


def balloon():
    b = '<defs><clipPath id="env"><ellipse cx="24" cy="24" rx="20" ry="22"/></clipPath></defs>'
    b += '<ellipse cx="24" cy="24" rx="20" ry="22" fill="#c8392f"/>'
    b += '<g clip-path="url(#env)">'
    for x in (8, 22, 36):
        b += f'<rect x="{x - 3}" y="0" width="6" height="48" fill="#f1dca4"/>'
    b += '<ellipse cx="15" cy="12" rx="7" ry="5" fill="#fff" opacity="0.5" stroke="none"/>'
    b += '</g>'
    b += '<ellipse cx="24" cy="24" rx="20" ry="22" fill="none" stroke="#5e1a16" stroke-width="1.2"/>'
    b += '<line x1="12" y1="42" x2="17" y2="56" stroke="#4a2c18"/><line x1="36" y1="42" x2="31" y2="56" stroke="#4a2c18"/>'
    b += '<ellipse cx="24" cy="54" rx="6" ry="5" fill="url(#skin)"/><circle cx="22" cy="53" r="1" fill="#ffd23f"/><circle cx="26" cy="53" r="1" fill="#ffd23f"/>'
    b += '<rect x="15" y="56" width="18" height="10" rx="2" fill="url(#wood)" stroke="#3a210f" stroke-width="0.8"/>'
    b += '<circle cx="35" cy="64" r="3" fill="#1e2026"/><line x1="35" y1="61" x2="37" y2="58" stroke="#ffb347" stroke-width="1.2"/>'
    return svg(48, 72, b)


def wyvern(up):
    b = ""
    if up:
        wing_l = '<path d="M26 22 Q14 2 2 6 Q10 14 8 22 Q16 20 26 26 Z" fill="url(#wyvern)" stroke="#2d1452" stroke-width="0.8"/>'
        wing_r = '<path d="M38 22 Q50 2 62 6 Q54 14 56 22 Q48 20 38 26 Z" fill="url(#wyvern)" stroke="#2d1452" stroke-width="0.8"/>'
    else:
        wing_l = '<path d="M26 24 Q12 36 2 32 Q10 28 8 22 Q16 22 26 20 Z" fill="url(#wyvern)" stroke="#2d1452" stroke-width="0.8"/>'
        wing_r = '<path d="M38 24 Q52 36 62 32 Q54 28 56 22 Q48 22 38 20 Z" fill="url(#wyvern)" stroke="#2d1452" stroke-width="0.8"/>'
    b += wing_l + wing_r
    b += '<path d="M32 30 Q34 40 40 42 Q34 42 30 34 Z" fill="#5a2f94"/>'
    b += '<ellipse cx="32" cy="24" rx="7" ry="10" fill="url(#wyvern)"/>'
    b += '<ellipse cx="32" cy="12" rx="5" ry="5" fill="#8a5ad0"/>'
    b += '<path d="M28 9 L26 4 L30 8 Z M36 9 L38 4 L34 8 Z" fill="#e8dcc0"/>'
    b += '<circle cx="30" cy="12" r="1.1" fill="#ffdd55"/><circle cx="34" cy="12" r="1.1" fill="#ffdd55"/>'
    b += '<path d="M29 22 L35 22 M29.5 26 L34.5 26" stroke="#d8c2ff" stroke-opacity="0.6"/>'
    return svg(64, 44, b)


def juggernaut():
    b = shadow(36, 77, 26, 5)
    b += '<rect x="20" y="58" width="13" height="19" rx="3" fill="url(#iron)"/><rect x="39" y="58" width="13" height="19" rx="3" fill="url(#iron)"/>'
    b += '<rect x="2" y="26" width="13" height="30" rx="6" fill="url(#iron)"/><rect x="57" y="26" width="13" height="30" rx="6" fill="url(#iron)"/>'
    b += '<path d="M10 22 Q36 10 62 22 L58 62 Q36 70 14 62 Z" fill="url(#iron)" stroke="#111" stroke-width="1"/>'
    b += '<path d="M12 24 Q36 14 60 24" stroke="#9aa1ae" stroke-width="2" fill="none"/>'
    b += '<circle cx="36" cy="42" r="9" fill="#ff7a1a"/><circle cx="36" cy="42" r="5" fill="#ffe08a"/>'
    b += '<circle cx="36" cy="42" r="14" fill="#ff7a1a" opacity="0.25" stroke="none"/>'
    for (x, y) in ((18, 30), (54, 30), (20, 56), (52, 56)):
        b += f'<circle cx="{x}" cy="{y}" r="1.6" fill="#c3c8d2"/>'
    b += '<rect x="25" y="2" width="22" height="18" rx="5" fill="url(#iron)" stroke="#111"/>'
    b += '<rect x="28" y="9" width="16" height="4" rx="2" fill="#2a0c08"/><circle cx="32" cy="11" r="1.6" fill="#ff4d2e"/><circle cx="40" cy="11" r="1.6" fill="#ff4d2e"/>'
    return svg(72, 80, b)


# --- Meadow decorations ------------------------------------------------------------------------------

def decor_bush():
    b = '<ellipse cx="16" cy="22" rx="14" ry="3.5" fill="url(#shadow)" stroke="none"/><!--art-->'
    b += '<circle cx="9" cy="15" r="6.5" fill="#3fae3c"/><circle cx="23" cy="15" r="6" fill="#2e9a35"/><circle cx="16" cy="11" r="8" fill="#56c84a"/>'
    b += gloss(12.5, 7.5, 2.4, 1.6, -20, 0.5) + '<circle cx="19" cy="13" r="1.2" fill="#ff5a6a" stroke="none"/><circle cx="11" cy="16" r="1.1" fill="#ff5a6a" stroke="none"/>'
    return svg(32, 26, b, 2.4)


def decor_tuft():
    b = '<path d="M6 16 Q4 8 1 4 Q7 8 8 14 Q9 5 11 1 Q12 9 11 15 Q14 7 18 5 Q14 11 13 16 Z" fill="#3fae3c"/>'
    b += '<path d="M8 15 Q9 8 11 3" fill="none" stroke="#8fe06a" stroke-width="1" />'
    return svg(20, 18, b, 2.0)


def decor_flowers():
    b = '<path d="M4 16 Q5 10 8 8 M12 16 Q12 9 14 6 M18 16 Q18 11 20 9" fill="none" stroke="#2e9a35" stroke-width="1.6"/>'
    for (x, y, c) in ((8, 8, "#ffffff"), (14, 6, "#ffe066"), (20, 9, "#ff8ab3")):
        b += ''.join(f'<circle cx="{x + 2.2 * math.cos(a)}" cy="{y + 2.2 * math.sin(a)}" r="1.9" fill="{c}"/>' for a in (0, 1.57, 3.14, 4.71))
        b += f'<circle cx="{x}" cy="{y}" r="1.5" fill="#ffb020"/>'
    return svg(24, 18, b, 1.8)


def decor_rock():
    b = '<ellipse cx="12" cy="17" rx="11" ry="3" fill="url(#shadow)" stroke="none"/><!--art-->'
    b += '<path d="M3 15 Q2 8 8 5 Q14 2 19 7 Q23 11 21 15 Z" fill="url(#stone)"/>'
    b += gloss(9, 7.5, 2.5, 1.4, -20, 0.6)
    return svg(24, 20, b, 2.2)


def decor_mushroom():
    b = '<rect x="7" y="9" width="5" height="8" rx="2" fill="#fff4dc"/>'
    b += '<path d="M2 10 Q3 2 9.5 2 Q16 2 17 10 Z" fill="#f2463c"/>'
    b += '<circle cx="7" cy="6" r="1.4" fill="#fff" stroke="none"/><circle cx="12.5" cy="5" r="1.1" fill="#fff" stroke="none"/><circle cx="13.5" cy="8.2" r="0.9" fill="#fff" stroke="none"/>'
    return svg(20, 19, b, 1.8)


# --- Icons ----------------------------------------------------------------------------------------

def coin():
    b = '<circle cx="16" cy="16.5" r="14" fill="#c97d0a"/><circle cx="16" cy="15" r="14" fill="url(#gold)"/>'
    b += '<circle cx="16" cy="15" r="10" fill="none" stroke="#e09a12" stroke-width="1.5"/>'
    b += '<path d="M11 18 L11 12 L13.5 14.5 L16 10 L18.5 14.5 L21 12 L21 18 Z" fill="#c97d0a" stroke="none"/>'
    b += gloss(10, 9, 3, 5, 35, 0.6)
    return svg(32, 32, b)


def cash():
    b = '<rect x="1" y="7" width="34" height="20" rx="3" fill="#2f6b2c"/><rect x="1" y="5" width="34" height="20" rx="3" fill="#6cc25a"/>'
    b += '<rect x="4" y="8" width="28" height="14" rx="2" fill="none" stroke="#2f6b2c" stroke-width="1.2"/>'
    b += '<circle cx="18" cy="15" r="5" fill="#2f6b2c"/><circle cx="18" cy="15" r="3" fill="#9ee08a"/>'
    return svg(36, 30, b)


def heart():
    b = '<path d="M16 28 C4 19 2 12 6 7 C10 2 15 5 16 9 C17 5 22 2 26 7 C30 12 28 19 16 28 Z" fill="#e5534b" stroke="#7d2522" stroke-width="1.5"/>'
    b += '<ellipse cx="10" cy="10" rx="3.5" ry="2.2" fill="#fff" opacity="0.6" stroke="none"/>'
    return svg(32, 32, b)


ART = {
    "keep": keep, "musket": musket, "cannon": cannon, "volley": volley, "sniper": sniper, "arcane": arcane,
    "musket_2": lambda: tiered(musket, "musket", 2), "musket_3": lambda: tiered(musket, "musket", 3),
    "cannon_2": lambda: tiered(cannon, "cannon", 2), "cannon_3": lambda: tiered(cannon, "cannon", 3),
    "volley_2": lambda: tiered(volley, "volley", 2), "volley_3": lambda: tiered(volley, "volley", 3),
    "sniper_2": lambda: tiered(sniper, "sniper", 2), "sniper_3": lambda: tiered(sniper, "sniper", 3),
    "arcane_2": lambda: tiered(arcane, "arcane", 2), "arcane_3": lambda: tiered(arcane, "arcane", 3),
    "slot": slot, "footman": footman, "runner": runner, "brute": brute, "balloon": balloon,
    "footman_b": lambda: footman(True), "runner_b": lambda: runner(True), "brute_b": lambda: brute(True),
    "sapper": sapper, "sapper_b": lambda: sapper(True), "shaman": shaman, "shaman_b": lambda: shaman(True),
    "decor_bush": decor_bush, "decor_tuft": decor_tuft, "decor_flowers": decor_flowers,
    "decor_rock": decor_rock, "decor_mushroom": decor_mushroom,
    "wyvern": lambda: wyvern(True), "wyvern_b": lambda: wyvern(False), "juggernaut": juggernaut,
    "coin": coin, "cash": cash, "heart": heart,
}

def app_icon():
    """The launcher icon: the Keep on a night-blue tile with a cyan glow."""
    b = '<radialGradient id="night" cx="0.5" cy="0.35" r="0.8"><stop offset="0" stop-color="#8fe0ff"/><stop offset="1" stop-color="#2f8be0"/></radialGradient>'
    b += '<rect width="256" height="256" fill="url(#night)"/>'
    b += '<circle cx="128" cy="70" r="90" fill="url(#glowCyan)" opacity="0.6"/>'
    b += '<ellipse cx="128" cy="240" rx="140" ry="34" fill="#5ccf4a"/>'
    sh, _, art = keep_body().partition("<!--art-->")
    b += f'<g transform="translate(38 22) scale(1.5)">{sh}</g><!--art--><g transform="translate(38 22) scale(1.5)">{art}</g>'
    return svg(256, 256, b, outline=3.2)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, fn in ART.items():
        with open(os.path.join(OUT, name + ".svg"), "w") as f:
            f.write(fn())
    with open(os.path.join(OUT, "..", "..", "icon.svg"), "w") as f:
        f.write(app_icon())
    print("wrote %d sprites to %s, and godot/icon.svg" % (len(ART), os.path.normpath(OUT)))
