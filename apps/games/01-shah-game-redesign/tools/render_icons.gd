extends SceneTree
## Turns the SVG icons written by tools/make_icon.py into the PNGs the exporters need.
##   godot --headless --path godot -s ../tools/render_icons.gd

const JOBS := [
	["res://icon.svg", "res://assets/icon/icon_1024.png", 1024],
	["res://icon.svg", "res://assets/icon/play_store_512.png", 512],
	["res://icon.svg", "res://assets/icon/main_192.png", 192],
	["res://assets/icon/android_background.svg", "res://assets/icon/android_background_432.png", 432],
	["res://assets/icon/android_foreground.svg", "res://assets/icon/android_foreground_432.png", 432],
	["res://assets/icon/android_monochrome.svg", "res://assets/icon/android_monochrome_432.png", 432],
]


func _initialize() -> void:
	for job in JOBS:
		var text := FileAccess.get_file_as_string(job[0])
		if text.is_empty():
			push_error("missing " + job[0])
			continue
		var source_size := 1024.0 if str(job[0]).ends_with("icon.svg") else 432.0
		var image := Image.new()
		var error := image.load_svg_from_string(text, float(job[2]) / source_size)
		if error != OK:
			push_error("could not render %s (error %d)" % [job[0], error])
			continue
		image.save_png(job[1])
		print("wrote %s (%dx%d)" % [job[1], image.get_width(), image.get_height()])
	quit()
