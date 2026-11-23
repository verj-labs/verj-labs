class_name FieldGround
extends RefCounted
## Paints the battlefield floor once per size: speckled night grass, and a packed-earth
## courtyard that grows as rings are unlocked.

const SEED := 7


static func make(size: Vector2, rings: int, battle: Battle) -> ImageTexture:
	var w := int(size.x)
	var h := int(size.y)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Pal.GRASS_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var center := Vector2(w / 2.0, h / 2.0 + 4.0)
	var yard := battle.wall_radius(rings) + 5.0
	for y in h:
		for x in w:
			var d := Vector2(x, y).distance_to(center)
			var roll := rng.randf()
			if d < yard:
				var c := Pal.EARTH
				if roll < 0.12:
					c = Pal.EARTH_LIGHT
				elif roll < 0.18:
					c = Pal.EARTH.darkened(0.25)
				if d > yard - 2.0:
					c = Pal.EARTH.darkened(0.35)
				img.set_pixel(x, y, c)
			elif roll < 0.10:
				img.set_pixel(x, y, Pal.GRASS)
			elif roll < 0.13:
				img.set_pixel(x, y, Pal.GRASS_LIGHT)
			elif roll < 0.1312:
				img.set_pixel(x, y, Color("#e8cf8a"))  # a few flowers
	# vignette so the edges of the field fall into darkness
	for y in h:
		for x in w:
			var dx := absf(x - w / 2.0) / (w / 2.0)
			var dy := absf(y - h / 2.0) / (h / 2.0)
			var v := clampf(maxf(dx, dy) * 1.3 - 0.75, 0.0, 0.6)
			if v > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(v))
	return ImageTexture.create_from_image(img)
