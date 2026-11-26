class_name SafeMargin
extends MarginContainer
## A full-screen margin that also keeps clear of the phone's notch, Dynamic Island, rounded
## corners and home bar. `base` is the normal padding on every side; the device's unsafe area is
## added on top. On desktop the safe area is the whole window, so only `base` applies.

## Pass `--fake-notch` after `--` to preview a notch on desktop (godot --path . -- --fake-notch).
const FAKE_INSETS := Vector4(0.0, 70.0, 0.0, 40.0)

var base: int = 28


func _init(p_base: int = 28) -> void:
	base = p_base
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_apply()
	get_viewport().size_changed.connect(_apply)


func _exit_tree() -> void:
	if get_viewport().size_changed.is_connected(_apply):
		get_viewport().size_changed.disconnect(_apply)


func _apply() -> void:
	var insets := SafeMargin.insets(get_viewport())
	add_theme_constant_override("margin_left", base + ceili(insets.x))
	add_theme_constant_override("margin_top", base + ceili(insets.y))
	add_theme_constant_override("margin_right", base + ceili(insets.z))
	add_theme_constant_override("margin_bottom", base + ceili(insets.w))


## Unsafe space (left, top, right, bottom) in layout units, i.e. what the 540-wide layout sees.
static func insets(viewport: Viewport) -> Vector4:
	if "--fake-notch" in OS.get_cmdline_user_args():
		return FAKE_INSETS
	var window_size := DisplayServer.window_get_size()
	var layout_size := viewport.get_visible_rect().size
	if window_size.x <= 0 or layout_size.x <= 0.0:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var pixels_per_unit := window_size.x / layout_size.x
	return Vector4(
		maxf(safe.position.x, 0) / pixels_per_unit,
		maxf(safe.position.y, 0) / pixels_per_unit,
		maxf(window_size.x - safe.end.x, 0) / pixels_per_unit,
		maxf(window_size.y - safe.end.y, 0) / pixels_per_unit,
	)
