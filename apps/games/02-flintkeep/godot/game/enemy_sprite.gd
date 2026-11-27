class_name EnemySprite
extends Node2D
## One raider on the field, made of sprites so that moving it costs nothing to draw: each frame
## the view only sets positions, the walking frame and the tint. The health bar redraws only when
## the health shown changes. Pooled by the view and reused for new enemies.

const AIR_DEPTH := 60.0  ## flyers sort as if this much nearer the camera (they are high up)
const BAR_STEPS := 40.0

var shadow := Sprite2D.new()
var body := Sprite2D.new()
var bar := Node2D.new()
var _bar_key := -1
var _bar_width := 0.0
var _bar_boss := false
var _bar_share := 1.0


func _init(soft: Texture2D) -> void:
	shadow.centered = false
	shadow.texture = soft
	body.centered = false
	add_child(shadow)
	add_child(body)
	add_child(bar)
	bar.draw.connect(_draw_bar)


## Places and dresses the sprite for enemy `e` (frozen: tinted blue).
func show_enemy(e: Entities.Enemy, frozen: bool) -> void:
	var name := e.kind
	if e.kind == "wyvern" or e.kind == "dragon":  # wings up, wings down
		name = e.kind + "_b" if int(e.age * (6.0 if e.kind == "wyvern" else 3.5)) % 2 == 1 else e.kind
	elif not e.air and e.attacking == -1 and Art.WALKERS.has(e.kind) and int(e.age * 6.0) % 2 == 1:
		name = e.kind + "_b"  # second walking frame
	var p := BattleView.proj(e.pos())
	var depth := AIR_DEPTH if e.air else 0.5
	position = p + Vector2(0.0, depth)
	var base := Vector2(0.0, -depth)  # children draw back at the enemy's real spot
	var lift := 0.0
	if e.air:
		lift = 16.0 + sin(e.age * 3.0) * 1.5
		_place(shadow, Rect2(base + Vector2(-4, -1.2), Vector2(8, 2.6)))
		shadow.modulate = Color(0.05, 0.25, 0.1, 0.45)
	else:
		_place(shadow, Rect2(base + Vector2(-3.5, -1.0), Vector2(7, 2.2)))
		shadow.modulate = Color(0.05, 0.25, 0.1, 0.35)
		if e.attacking == -1:
			lift = absf(sin(e.age * 9.0)) * 0.7
	var tex := Art.tex(name)
	var r := Art.rect(name, base + Vector2(0, 0.5 - lift))
	if e.attacking >= 0:
		r.position += Vector2.from_angle(e.angle + PI) * (0.6 if int(e.age * 8.0) % 2 == 0 else 0.0)
	body.texture = tex
	_place(body, r)
	body.flip_h = p.x > 0.0  # face the Keep
	body.modulate = Color(2.2, 2.2, 2.2) if e.hit_flash > 0.0 else (Color(0.7, 0.9, 1.4) if frozen else Color.WHITE)
	if e.hp < e.max_hp:
		var w := maxf(r.size.x * 0.8, 6.0)
		bar.visible = true
		bar.position = Vector2(base.x - w / 2.0, r.position.y - 2.0)
		var share := clampf(e.hp / e.max_hp, 0.0, 1.0)
		var key := int(share * BAR_STEPS)
		if key != _bar_key or w != _bar_width or e.boss != _bar_boss:
			_bar_key = key
			_bar_width = w
			_bar_boss = e.boss
			_bar_share = share
			bar.queue_redraw()
	else:
		bar.visible = false


static func _place(sprite: Sprite2D, rect: Rect2) -> void:
	var size := sprite.texture.get_size()
	sprite.scale = rect.size / size
	sprite.position = rect.position


func _draw_bar() -> void:
	var bar_rect := Rect2(Vector2.ZERO, Vector2(_bar_width, 1.1))
	bar.draw_rect(bar_rect.grow(0.4), Pal.INK)
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(_bar_width * _bar_share, 1.1)), Pal.RED if not _bar_boss else Pal.ORANGE)
