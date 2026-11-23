class_name Pal
extends RefCounted
## Night battlefield, dark-walnut panels with brass trim, parchment text. Accents: gold for
## coins, green for cash, cyan for the Keep's arcane bolts, violet for magic.

const BG := Color("#10131a")
const PANEL := Color("#2a2019")  ## dark walnut
const PANEL_LIGHT := Color("#3a2c21")
const PANEL_DEEP := Color("#1b1510")
const LINE := Color("#5e4630")  ## wood edge
const BRASS := Color("#d8a750")
const BRASS_DIM := Color("#8c6a3a")
const SHADOW := Color(0, 0, 0, 0.45)

const PARCHMENT := Color("#f5ead3")
const DIM := Color("#c4b293")
const MUTED := Color("#7f6e58")

const GOLD := Color("#ffcc4d")  ## coins
const CASH := Color("#8fdc6a")  ## cash
const CASH_DARK := Color("#2f6b2c")
const RED := Color("#e5534b")
const ORANGE := Color("#ff9a3c")
const CYAN := Color("#6fe3ff")
const ARCANE := Color("#b98cff")
const INK := Color("#22180f")  ## dark text on bright buttons

const GRASS_DARK := Color("#1a3324")
const GRASS_LIGHT := Color("#3a6440")
const EARTH := Color("#8a6a44")

## Colour of each weapon's shots and its name in the build list.
const WEAPON_COLORS := {
	"keep": Color("#6fe3ff"),
	"musket": Color("#ffe27a"),
	"cannon": Color("#ff9a3c"),
	"volley": Color("#fff2b0"),
	"sniper": Color("#e8fbff"),
	"arcane": Color("#c89bff"),
}
