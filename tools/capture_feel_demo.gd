## Deterministic visual demo of real easy stage 2. No progress writes.
extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var global = root.get_node("Global")
	global.current_tier = 0
	global.current_level = 1
	global.settings["anim"] = true
	global.settings["vibrate"] = false
	var game = load("res://tools/feel_test_game.gd").new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_scene = game
	await create_timer(1.0).timeout
	game._do_move(Vector2i.UP)
	await create_timer(0.3).timeout
	game._do_move(Vector2i.UP) # wall bump
	await create_timer(0.45).timeout
	game._do_undo()
	await create_timer(0.35).timeout
	var dirs := {"R": Vector2i.RIGHT, "L": Vector2i.LEFT, "D": Vector2i.DOWN, "U": Vector2i.UP}
	for letter in game.level["solution"]:
		game._do_move(dirs[letter])
		await create_timer(0.28).timeout
	await create_timer(0.75).timeout
	game._open_complete(3, false)
	await create_timer(1.8).timeout
	quit()
