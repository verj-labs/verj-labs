class_name Num
extends RefCounted
## Short number formatting for an idle game: 950, 1.25K, 12.5K, 125K, 1.25M ... Q, then aa, ab ...
## Digits are cut, never rounded up, so a number never shows more than you have.
## Values below 100 that are not whole show one decimal so early numbers (6.5 damage) still read.

const SUFFIXES := ["", "K", "M", "B", "T", "Q"]


static func fmt(value: float) -> String:
	var negative := value < 0.0
	var v := absf(value)
	var text: String
	if v < 1000.0:
		if v < 100.0 and absf(v - roundf(v)) >= 0.05:
			text = "%.1f" % v
		else:
			text = str(int(floor(v)))
	else:
		var tier := int(floor(log(v) / log(1000.0)))
		var scaled := v / pow(1000.0, tier)
		if scaled < 1.0:  # log() landed a hair below a power of 1000
			tier -= 1
			scaled *= 1000.0
		text = _three_digits(scaled) + _suffix(tier)
	return ("-" if negative else "") + text


## Money with a sign in front, in whole dollars: $19, $1.25K.
static func cash(value: float) -> String:
	if absf(value) < 1000.0:
		return ("-$" if value < 0.0 else "$") + str(int(floor(absf(value))))
	return "$" + fmt(value)


## A price, rounded up so the button never shows less than it costs.
static func price(value: float) -> String:
	return cash(ceilf(value) if value < 1000.0 else value)


## A percentage from a fraction: 0.125 -> "12.5%".
static func pct(fraction: float) -> String:
	var p := fraction * 100.0
	if absf(p - roundf(p)) < 0.05:
		return "%d%%" % int(roundf(p))
	return "%.1f%%" % p


## Time left as "1H 05M", "4M 10S" or "9S".
static func duration(seconds: float) -> String:
	var s := int(ceil(maxf(seconds, 0.0)))
	if s >= 86400:
		return "%dD %02dH" % [s / 86400, (s % 86400) / 3600]
	if s >= 3600:
		return "%dH %02dM" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dM %02dS" % [s / 60, s % 60]
	return "%dS" % s


static func _three_digits(scaled: float) -> String:
	if scaled >= 100.0:
		return str(int(floor(scaled)))
	if scaled >= 10.0:
		return "%.1f" % (floor(scaled * 10.0) / 10.0)
	return "%.2f" % (floor(scaled * 100.0) / 100.0)


static func _suffix(tier: int) -> String:
	if tier < SUFFIXES.size():
		return SUFFIXES[tier]
	# After Q: aa, ab, ... az, ba ...
	var n := tier - SUFFIXES.size()
	var first := char(97 + (n / 26) % 26)
	var second := char(97 + n % 26)
	return first + second
