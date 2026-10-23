class_name Burst
extends RefCounted
## A pop of square confetti: arcade-style particles for resets and victories.

const PARTICLES_PER_COLOR := 14
const LIFETIME := 0.9


static func spawn(parent: Node, at: Vector2, colors: Array[Color], power: float = 1.0) -> void:
	for color in colors:
		var particles := CPUParticles2D.new()
		particles.position = at
		particles.one_shot = true
		particles.emitting = true
		particles.explosiveness = 1.0
		particles.amount = int(PARTICLES_PER_COLOR * power)
		particles.lifetime = LIFETIME
		particles.spread = 180.0
		particles.initial_velocity_min = 180.0 * power
		particles.initial_velocity_max = 520.0 * power
		particles.gravity = Vector2(0, 900)
		particles.scale_amount_min = 6.0
		particles.scale_amount_max = 12.0
		particles.color = color
		var fade := Gradient.new()
		fade.set_color(0, Color.WHITE)
		fade.set_color(1, Color(1, 1, 1, 0))
		particles.color_ramp = fade
		parent.add_child(particles)
		particles.finished.connect(particles.queue_free)
