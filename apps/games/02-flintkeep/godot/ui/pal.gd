class_name Pal
extends RefCounted
## Casual cartoon colours: a sunny green field, warm wood panels with cream cards, glossy
## saturated buttons. Dark brown outlines tie the UI to the art (same colour as sprite ink).

const INK := Color("#3a2218")  ## outlines and dark text, same as the sprites' outline
const SKY_TOP := Color("#7fd6ff")
const SKY_BOTTOM := Color("#3b95e6")

const WOOD := Color("#b46a33")  ## panel wood
const WOOD_LIGHT := Color("#d48a48")
const WOOD_DARK := Color("#7a4320")
const CARD := Color("#fff2d4")  ## cream cards inside wood panels
const CARD_EDGE := Color("#e0b97c")

const TEXT := Color("#5a3418")  ## on cream
const TEXT_DIM := Color("#9a7352")
const WHITE := Color("#fffaf0")  ## on wood, buttons and sky (always outlined)
const MUTED := Color("#b9a58c")

const GOLD := Color("#ffcf3a")  ## coins
const CASH := Color("#6fe04a")  ## cash
const RED := Color("#ff5247")
const ORANGE := Color("#ff9a2e")
const CYAN := Color("#3fd8ff")
const ARCANE := Color("#c06bff")

const GRASS := Color("#5cc451")
const GRASS_LIGHT := Color("#74d665")
const GRASS_DARK := Color("#45a742")
const SAND := Color("#f2d79c")
const PATH := Color("#e3bd7c")

## Colour of each weapon's shots and its name in the build list.
const WEAPON_COLORS := {
	"keep": Color("#ffc23a"),  ## the Keep throws firebolts
	"musket": Color("#ffe066"),
	"cannon": Color("#ff8a2a"),
	"volley": Color("#fff0a0"),
	"sniper": Color("#ffffff"),
	"arcane": Color("#d78bff"),
}
## Darker versions for text on cream cards.
const WEAPON_TEXT := {
	"musket": Color("#c2410c"), "cannon": Color("#9a3412"), "volley": Color("#a16207"),
	"sniper": Color("#166534"), "arcane": Color("#7e22ce"),
}
