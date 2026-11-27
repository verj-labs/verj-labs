class_name DayNight
extends RefCounted
## Time of day on the battlefield. Purely visual: the rules never read it, because players can
## pick a fixed time (an effect that made nights harder would just make everyone pick Day).
##
## A day is a loop of `phase` from 0 to 1: sunrise at 0, full day from 0.1 to 0.45, sunset at
## 0.55, night from 0.65 to 0.92, then back to sunrise. look() blends the keyframes below into
## what the view needs: a tint for the ground and everything standing, how strongly lights glow,
## how dark it is (for lanterns and fireflies), a haze at the screen's edges and the sun's
## direction and height (for shadows).

const CYCLE_SECONDS := 300.0  ## "Auto": a full sunrise-to-sunrise loop every 5 minutes (real time)
const MODES := ["cycle", "clock", "sunrise", "day", "sunset", "night"]
const MODE_NAMES := {"cycle": "Auto", "clock": "My clock", "sunrise": "Sunrise", "day": "Day", "sunset": "Sunset", "night": "Night"}
const FIXED_PHASE := {"sunrise": 0.02, "day": 0.3, "sunset": 0.55, "night": 0.78}

## [phase, tint, glow, night, haze]
const KEYS := [
	[0.0, Color(1.0, 0.89, 0.8), 1.35, 0.15, Color(1.0, 0.55, 0.65, 0.24)],
	[0.1, Color(1.0, 1.0, 1.0), 1.0, 0.0, Color(1.0, 1.0, 1.0, 0.0)],
	[0.45, Color(1.0, 1.0, 1.0), 1.0, 0.0, Color(1.0, 1.0, 1.0, 0.0)],
	[0.55, Color(1.0, 0.83, 0.68), 1.45, 0.2, Color(0.7, 0.25, 0.55, 0.28)],
	[0.65, Color(0.42, 0.5, 0.8), 2.3, 1.0, Color(0.04, 0.07, 0.25, 0.5)],
	[0.92, Color(0.42, 0.5, 0.8), 2.3, 1.0, Color(0.04, 0.07, 0.25, 0.5)],
	[1.0, Color(1.0, 0.89, 0.8), 1.35, 0.15, Color(1.0, 0.55, 0.65, 0.24)],
]


## Where in the day `mode` is: real time for Auto, the phone's clock for "My clock".
static func phase(mode: String, unix_seconds: float, local_hour: float) -> float:
	match mode:
		"cycle":
			return fposmod(unix_seconds / CYCLE_SECONDS, 1.0)
		"clock":
			return clock_phase(local_hour)
	return FIXED_PHASE.get(mode, FIXED_PHASE["day"])


## Maps the hour of the day (0-24) onto the loop: sunrise around 6:00, day 7-17,
## sunset around 18:30, night from 20:00 to 5:00.
static func clock_phase(hour: float) -> float:
	var points := [[0.0, 0.8], [5.0, 0.92], [6.5, 1.0], [7.5, 1.1], [17.0, 1.45], [18.5, 1.55], [20.0, 1.65], [24.0, 1.8]]
	for i in points.size() - 1:
		var a: Array = points[i]
		var b: Array = points[i + 1]
		if hour <= b[0]:
			var t: float = (hour - a[0]) / (b[0] - a[0])
			return fposmod(lerpf(float(a[1]), float(b[1]), t), 1.0)
	return 0.8


## Everything the view draws differently at this point of the day.
static func look(p: float) -> Dictionary:
	p = fposmod(p, 1.0)
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if p <= b[0]:
			var t := smoothstep(0.0, 1.0, (p - a[0]) / maxf(b[0] - a[0], 0.0001))
			return {
				"tint": (a[1] as Color).lerp(b[1], t),
				"glow": lerpf(a[2], b[2], t),
				"night": lerpf(a[3], b[3], t),
				"haze": (a[4] as Color).lerp(b[4], t),
				"sun": sun(p),
			}
	return look(0.0)


## The direction towards the sun on the ground (shadows point the other way) and its height (0 = on the
## horizon: long shadows; 1 = overhead: short ones). At night the moon casts faint short ones.
static func sun(p: float) -> Dictionary:
	var day := clampf(p / 0.62, 0.0, 1.0)  # 0 at sunrise, 1 at sunset
	# rises in the east (right), passes behind the Keep (north), sets in the west (left), so
	# shadows swing from left, to towards the camera at noon, to the right
	var angle := lerpf(-PI * 0.05, -PI * 0.95, day)
	var height := sin(day * PI)
	var strength := 1.0
	if p >= 0.62:  # moonlight: faint, shortish shadows
		height = 0.6
		strength = 0.35
	return {"dir": Vector2.from_angle(angle), "height": height, "strength": strength}
