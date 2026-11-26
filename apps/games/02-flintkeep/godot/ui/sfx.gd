class_name Sfx
extends RefCounted
## Static front door to the "Sound" autoload, so any script (even ones compiled before the
## autoload exists, like the dev tools) can play a sound.


static func play(name: String, jitter: float = 0.04) -> void:
	var node := _node()
	if node != null:
		node.play(name, jitter)


static func music(scene: String) -> void:
	var node := _node()
	if node != null:
		node.music(scene)


static func intensity(value: float) -> void:
	var node := _node()
	if node != null:
		node.set_intensity(value)


static func boss(on: bool) -> void:
	var node := _node()
	if node != null:
		node.set_boss(on)


static func node() -> Node:
	return _node()


static func _node() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("Sound")
