## Captures the actual game at 1920x1080 without changing saved settings/progress.
## Godot.exe --path . --script res://tools/capture_assets.gd -- --asset-tier=2 --asset-level=0 --asset-output=res://assets/store/screenshots/stage1.png
## Omit --asset-level for a main-menu screenshot.
extends SceneTree

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	var output := "res://docs/screenshots/assets_menu.png"
	var level_index := -1
	var tier_index := 0
	var facing := "down"
	var overlay := "none"
	var scene_name := "MainMenu"
	var language := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--asset-output="):
			output = argument.trim_prefix("--asset-output=")
		elif argument.begins_with("--asset-level="):
			level_index = int(argument.trim_prefix("--asset-level="))
		elif argument.begins_with("--asset-tier="):
			tier_index = int(argument.trim_prefix("--asset-tier="))
		elif argument.begins_with("--asset-facing="):
			facing = argument.trim_prefix("--asset-facing=")
		elif argument.begins_with("--asset-overlay="):
			overlay = argument.trim_prefix("--asset-overlay=")
		elif argument.begins_with("--asset-scene="):
			scene_name = argument.trim_prefix("--asset-scene=")
		elif argument.begins_with("--asset-lang="):
			language = argument.trim_prefix("--asset-lang=")
	# Apply only to this capture process, after Global has read saved settings.
	root.mode = Window.MODE_FULLSCREEN
	root.size = Vector2i(1920, 1080)
	await process_frame
	if language in ["ko", "en"]:
		root.get_node("Global").settings["lang"] = language
	if level_index >= 0:
		root.get_node("Global").current_tier = tier_index
		root.get_node("Global").current_level = level_index
		change_scene_to_file("res://scenes/Game.tscn")
	else:
		change_scene_to_file("res://scenes/%s.tscn" % scene_name)
	await create_timer(1.3).timeout
	if level_index >= 0:
		if current_scene.has_method("dismiss_tutorial"):
			current_scene.dismiss_tutorial()
		var directions := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT, "right": Vector2i.RIGHT}
		if not directions.has(facing):
			push_error("Invalid asset facing: " + facing)
			quit(1)
			return
		current_scene._set_facing(directions[facing])
		await process_frame
	# Open UI directly for visual checks; completing a board would write progress.
	match overlay:
		"settings":
			var settings_script = load("res://scripts/SettingsPanel.gd")
			current_scene.add_child(settings_script.new())
		"pause":
			current_scene._open_pause()
		"tutorial":
			current_scene._open_tutorial()
		"clear":
			current_scene._open_complete(3, true)
		"none":
			pass
		_:
			push_error("Invalid asset overlay: " + overlay)
			quit(1)
			return
	# Let panel/star entrance tweens settle before taking a still image.
	await create_timer(1.2).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != Vector2i(1920, 1080):
		push_error("Expected 1920x1080 capture, got %s" % screenshot.get_size())
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var error := screenshot.save_png(output)
	if error != OK:
		push_error("Screenshot save failed: %s" % error)
		quit(1)
		return
	print("Asset screenshot saved: ", ProjectSettings.globalize_path(output))
	quit()
