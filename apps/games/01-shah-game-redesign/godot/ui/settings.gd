class_name Settings
extends RefCounted
## Tiny persistent key/value store (user://settings.cfg). Every write re-reads the file first, so
## different parts of the game can save their own sections without erasing each other.

const PATH := "user://settings.cfg"


static func read(section: String, key: String, fallback: Variant) -> Variant:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return fallback
	return config.get_value(section, key, fallback)


static func write(section: String, key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(PATH)  # fine if it does not exist yet
	config.set_value(section, key, value)
	config.save(PATH)
