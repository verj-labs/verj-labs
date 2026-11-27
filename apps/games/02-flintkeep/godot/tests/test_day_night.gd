extends TestCase
## Time of day: purely visual, but the modes, the 5-minute loop and the clock mapping matter.


func test_fixed_modes_show_their_time() -> void:
	check(DayNight.look(DayNight.phase("night", 0.0, 12.0))["night"] > 0.9, "Night is night at noon")
	near(DayNight.look(DayNight.phase("day", 0.0, 23.0))["night"], 0.0, 0.001, "Day is day at midnight")
	var dawn: Color = DayNight.look(DayNight.phase("sunrise", 0.0, 0.0))["tint"]
	check(dawn.r > dawn.b, "sunrise is warm")


func test_auto_loops_every_five_minutes() -> void:
	var a := DayNight.phase("cycle", 1000.0, 0.0)
	near(DayNight.phase("cycle", 1000.0 + DayNight.CYCLE_SECONDS, 0.0), a, 0.0001, "back where it started")
	check(absf(DayNight.phase("cycle", 1000.0 + DayNight.CYCLE_SECONDS / 2.0, 0.0) - a) > 0.4, "half a loop later it is the other half of the day")


func test_my_clock_follows_the_hour() -> void:
	check(DayNight.look(DayNight.clock_phase(23.0))["night"] > 0.9, "11 pm is night")
	near(DayNight.look(DayNight.clock_phase(12.0))["night"], 0.0, 0.001, "noon is day")
	var dusk: Color = DayNight.look(DayNight.clock_phase(18.5))["tint"]
	check(dusk.r > dusk.b + 0.2, "6:30 pm is sunset")


func test_the_loop_has_no_jumps() -> void:
	var prev: Color = DayNight.look(0.0)["tint"]
	for i in range(1, 401):
		var now: Color = DayNight.look(i / 400.0)["tint"]
		check(absf(now.r - prev.r) + absf(now.g - prev.g) + absf(now.b - prev.b) < 0.08, "smooth at %d/400" % i)
		prev = now
