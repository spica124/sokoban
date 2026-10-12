## Run with --script res://tools/verify_game_feel.gd -- --touch.
## Test-only scene overrides record saving; Global settings change in memory only.
extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var global = root.get_node("Global")
	var assets = root.get_node("Assets")
	global.settings["anim"] = true
	global.settings["vibrate"] = false
	for name in ["arrow", "star_on", "star_off", "lock", "tier_easy", "tier_normal", "tier_hard", "tier_expert"]:
		check(assets.art("ui", name) != null, "UI texture " + name)
	for name in ["sparkle", "dust", "leaf"]:
		check(assets.art("fx", name) != null, "FX texture " + name)
	var game = load("res://tools/feel_test_game.gd").new()
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_scene = game
	game.dismiss_tutorial()
	game._input_lock = 0.0
	game.level = {"rows": ["########", "# @$. .#", "# $    #", "########"], "par": 10}
	game._load_level()
	await create_timer(0.8).timeout
	check(game._tile > 0 and game._board_area.size.x > 0, "test scene has a visible board layout")
	var start: Vector2i = game.board.player
	game._do_move(Vector2i.UP)
	check(game.board.player == start and game.board.moves == 0, "blocked move preserves board and count")
	check(game._player.texture == assets.tex("player_bump"), "blocked expression appears")
	game._do_move(Vector2i.RIGHT)
	check(game._player.texture == assets.tex("player_right"), "new input immediately replaces bump expression")
	check(game.board.pushes == 1 and game.board.boxes_on_goals() == 1, "push lands on target")
	game._do_undo()
	await create_timer(0.4).timeout
	check(game.board.player == start and game.board.moves == 0 and game.board.pushes == 0, "rapid undo restores board counters")
	check(game._player.position.distance_to(game._cell_pos(start)) < 0.01, "rapid move/undo settles on correct cell")
	var sparkles := 0
	for node in game._board_root.get_children():
		if node is CPUParticles2D and node.texture == assets.art("fx", "sparkle"):
			sparkles += 1
	check(sparkles == 0, "undo cancels delayed target sparkles")
	game._do_move(Vector2i.UP)
	game._load_level()
	game._set_facing(Vector2i.LEFT)
	await create_timer(0.8).timeout
	check(game._player.texture == assets.tex("player_left"), "restart invalidates old expression timer")
	game._open_pause()
	game.set_pad_dir(Vector2i.RIGHT, true)
	game._do_move(Vector2i.RIGHT)
	game._do_undo()
	check(game.board.moves == 0 and game._pad_dir == Vector2i.ZERO, "pause rejects move and held pad input")
	game._close_overlay()
	game._input_lock = 0.0
	game.set_pad_dir(Vector2i.RIGHT, true)
	check(game.board.moves == 1, "pad press acts immediately")
	game.set_pad_dir(Vector2i.RIGHT, false)
	await create_timer(0.35).timeout
	check(game.board.moves == 1 and game._pad_dir == Vector2i.ZERO, "pad release prevents extra moves")
	# Turning motion off in pause must stop already running goal shimmer.
	game._open_pause()
	global.settings["anim"] = false
	game._close_overlay()
	var calm := true
	for node in game._box_nodes.values():
		calm = calm and not node.has_meta("glow_fx") and node.self_modulate == Color.WHITE
	check(calm, "disabling effects stops existing goal shimmer")
	game._do_undo()
	game._do_move(Vector2i.UP)
	check(game._player.texture == assets.tex("player_up"), "motion off skips transient bump expression")
	check(game._player.position.distance_to(game._cell_pos(game.board.player)) < 0.01, "motion off snaps movement exactly")
	global.settings["anim"] = true
	game._load_level()
	await create_timer(0.8).timeout
	game._do_move(Vector2i.RIGHT)
	await create_timer(0.18).timeout
	await shot("feel_goal")
	game._do_move(Vector2i.UP)
	await create_timer(0.04).timeout
	await shot("feel_bump")
	game._completed = true
	game._celebrate()
	await create_timer(0.25).timeout
	check(game._player.texture == assets.tex("player_happy"), "celebration uses happy capybara")
	var leaf_count := 0
	for node in game.get_children():
		if node is CPUParticles2D and node.texture == assets.art("fx", "leaf"):
			leaf_count += 1
	check(leaf_count == 1, "celebration emits textured autumn leaves")
	await shot("feel_celebration")
	var count: int = game.board.moves
	game.set_pad_dir(Vector2i.LEFT, true)
	game._do_undo()
	check(game.board.moves == count, "completion locks further moves and undo")
	await create_timer(0.1).timeout
	check(game._player.texture == assets.tex("player_happy"), "old bump timer cannot overwrite happy face")
	game._load_level()
	await create_timer(0.8).timeout
	check(game._board_area.scale == Vector2.ONE and game._board_root.position == Vector2.ZERO, "restart resets board transform")
	print("GAME FEEL CHECKS COMPLETE; failures=", failures)
	quit(1 if failures > 0 else 0)

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "res://docs/screenshots/" + name + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)
