class_name CrtOverlay
extends ColorRect
## Faint scanlines and a darkened vignette over the whole screen: the arcade monitor look.
## Purely decorative; it never blocks input.

const SHADER_CODE := """
shader_type canvas_item;
uniform float line_strength = 0.10;
uniform float vignette = 0.45;
void fragment() {
	float line = step(0.5, fract(UV.y * 426.0));
	float edge = distance(UV, vec2(0.5));
	float shade = line * line_strength + smoothstep(0.42, 0.95, edge) * vignette;
	COLOR = vec4(0.0, 0.0, 0.0, shade);
}
"""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material
