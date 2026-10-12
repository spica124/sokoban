## DevTools.gd — developer helpers (autoload "DevTools"). Does nothing in a
## normal run. Command-line flags (after "--"):
##   --shot=NAME     save a screenshot to user://shots/NAME.png after ~1s and quit
##   --level=N       start Game.tscn at level N (0-based) instead of the main menu
##   --tier=N        with --level: which tier (0 easy .. 3 expert, 4.. rule chapters)
##   --daily[=DATE]  open the daily puzzle (today, or YYYY-MM-DD)
##   --scene=NAME    open res://scenes/NAME.tscn (e.g. StageSelect)
##   --solve         play the level's stored solution (if present) before the shot
##   --steps=N       with --solve: play only the first N moves (to see a mid-game board)
##   --wait=S        seconds before the shot / auto-play starts (default 1.0)
##   --after=S       with --solve: seconds after the last move before the shot (default 1.0)
##   --tut=N         advance the stage-1 tutorial to step N (1-based) before the shot
##   --dpad=RRDL     press/release the on-screen D-pad (one step per letter); 'H' holds RIGHT 0.5 s
##   --hint          press the hint button (after --solve/--steps), wait --hintwait=S (2.5)
##   --settings      open the settings panel on top of the current scene
##   --pause         open the pause panel (Game scene only)
## Example:
##   Godot.exe --path . -- --level=3 --shot=level3
extends Node

var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var eq := a.find("=")
		if eq > 0:
			args[a.substr(2, eq - 2)] = a.substr(eq + 1)
		else:
			args[a.trim_prefix("--")] = true
	if args.has("tier"):
		Global.current_tier = int(args["tier"])
	if args.has("daily"):
		Global.current_mode = "daily"
		Global.daily_date = Global.today() if str(args["daily"]) == "true" else str(args["daily"])
		call_deferred("_open_scene", "Game")
	elif args.has("level"):
		Global.current_level = int(args["level"])
		call_deferred("_open_scene", "Game")
	elif args.has("scene"):
		call_deferred("_open_scene", str(args["scene"]))
	if args.has("shot"):
		_screenshot_later.call_deferred()


func _open_scene(scene_name: String) -> void:
	var path := "res://scenes/%s.tscn" % scene_name
	if not ResourceLoader.exists(path):
		push_error("DevTools: scene not found: " + path)
		get_tree().quit(1)
		return
	get_tree().change_scene_to_file(path)


func _screenshot_later() -> void:
	# --wait=S : seconds before acting (default 1.0; small values catch intros)
	await get_tree().create_timer(float(args.get("wait", 1.0))).timeout
	if args.has("solve"):
		await _play_solution()
	if args.has("dpad"):
		await _press_dpad(str(args["dpad"]))
	var scene := get_tree().current_scene
	if args.has("tut") and scene.has_method("_tut_next"):
		for i in int(args["tut"]) - 1:
			scene._tut_next()
	if args.has("hint") and scene.has_method("request_hint"):
		if scene.has_method("dismiss_tutorial"):
			scene.dismiss_tutorial()
		scene._input_lock = 0.0
		scene.request_hint()
		await get_tree().create_timer(float(args.get("hintwait", 2.5))).timeout
	if args.has("settings"):
		scene.add_child(SettingsPanel.new())
	elif args.has("pause") and scene.has_method("_open_pause"):
		scene._open_pause()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots"))
	var path := "user://shots/%s.png" % args["shot"]
	img.save_png(path)
	print("screenshot saved: ", ProjectSettings.globalize_path(path))
	get_tree().quit()


## Drives the D-pad handler like the on-screen buttons do
func _press_dpad(letters: String) -> void:
	var game := get_tree().current_scene
	if game == null or not game.has_method("set_pad_dir"):
		return
	if game.has_method("dismiss_tutorial"):
		game.dismiss_tutorial()
		await get_tree().create_timer(0.35).timeout
	var dirs := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for ch in letters:
		if ch == "H":   # hold RIGHT for half a second: expect several repeated steps
			game.set_pad_dir(Vector2i.RIGHT, true)
			await get_tree().create_timer(0.5).timeout
			game.set_pad_dir(Vector2i.RIGHT, false)
		elif dirs.has(ch):
			game.set_pad_dir(dirs[ch], true)
			await get_tree().process_frame
			game.set_pad_dir(dirs[ch], false)
			await get_tree().create_timer(0.12).timeout
	print("dpad result: player=%s moves=%d pushes=%d" % [game.board.player, game.board.moves, game.board.pushes])
	await get_tree().create_timer(0.3).timeout


## Feeds the level's solution string (e.g. "RRDL") as simulated key presses
func _play_solution() -> void:
	var game := get_tree().current_scene
	if game == null or not game.has_method("_do_move"):
		return
	if game.has_method("dismiss_tutorial"):
		game.dismiss_tutorial()
	var sol: String = game.level.get("solution", "")
	if args.has("steps"):
		sol = sol.substr(0, int(args["steps"]))
	var map := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
	for ch in sol:
		if game.get("_completed"):
			break
		if map.has(ch):
			game._do_move(map[ch])
			await get_tree().create_timer(0.03).timeout
	# --after=S : seconds to wait after the last move (small values catch effects)
	await get_tree().create_timer(float(args.get("after", 1.0))).timeout
