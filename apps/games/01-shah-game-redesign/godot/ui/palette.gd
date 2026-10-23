class_name Palette
extends RefCounted
## Arcade colours: a deep indigo night with neon accents. Cards keep a clean cream face so the
## game stays readable; everything around them is loud.

const BG_DEEP := Color("#08031C")
const BG_MID := Color("#1A0B47")
const PANEL := Color("#1F1058")
const PANEL_LIGHT := Color("#33208A")
const LINE := Color("#4A32B8")
const FELT := Color("#0E2F4A")

const CREAM := Color("#FFF6DC")
const DIM := Color("#A99FD9")

const PINK := Color("#FF2E93")
const CYAN := Color("#22E5FF")
const YELLOW := Color("#FFE14D")
const LIME := Color("#7CFF5B")
const ORANGE := Color("#FF9A1F")
const PURPLE := Color("#B084FF")
const RED := Color("#FF4455")

const INK := Color("#120A2E")  ## Dark text on bright buttons and card faces.

## One accent per seat so players are easy to tell apart at a glance. Seat 0 is you.
const SEAT_COLORS := [YELLOW, CYAN, PINK, LIME, ORANGE, PURPLE, Color("#5AA0FF"), Color("#FF7A7A")]


static func seat_color(seat: int) -> Color:
	return SEAT_COLORS[seat % SEAT_COLORS.size()]
