class_name TestCase
extends RefCounted
## Base for tests run by tools/run_tests.gd. Asserts record failures instead of stopping.

var failures: Array[String] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [message, str(expected), str(actual)])


func near(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s expected ~%s, got %s" % [message, str(expected), str(actual)])
