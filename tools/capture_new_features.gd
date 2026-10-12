## Run only in a disposable project copy with application/config/name=Sokoban Art QA.
## Captures actual scenes and verifies that the new PNGs override procedural art.
extends SceneTree

const HATS := ["straw", "mandarin", "flower", "leaf", "chef", "beanie", "grad", "crown"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Sokoban Art QA":
		push_error("Use an isolated Sokoban Art QA project copy to protect real progress")
		quit(1)
		return
	await process_frame
	var g = root.get_node("Global")
	var assets = root.get_node("Assets")
	var achievements = root.get_node("Achievements")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	g.settings["fullscreen"] = false
	g.settings["lang"] = "ko"
	g.settings["vibrate"] = false
	for n in 200:
		g.progress["easy/%d" % n] = {"stars": 3, "moves": 1, "time": 20.0}
	for entry in achievements.LIST:
		g.achievements[entry[0]] = 1
	for h in HATS:
		g.hats_seen.append(h)
	for t in ["rule_color", "rule_ice", "rule_oneway", "rule_mix"]:
		g.seen_rules[t] = true
		for n in 10:
			g.progress[t + "/" + str(n)] = {"stars": 3, "moves": 1, "time": 20.0}
	var sprites: Array = ["box_c1", "box_on_goal_c1", "ice", "oneway"]
	for h in HATS:
		sprites.append("hat_" + h)
	var verified := 0
	for folder in ["sprites", "ui"]:
		var names: Array = sprites if folder == "sprites" else ["rule_color", "rule_ice", "rule_oneway", "rule_mix", "daily", "trophy", "hanger"]
		for name in names:
			var path := "res://assets/%s/%s.png" % [folder, name]
			var expected := Image.load_from_file(ProjectSettings.globalize_path(path))
			var tex: Texture2D = assets.tex(name) if folder == "sprites" else assets.art(folder, name)
			var actual := tex.get_image()
			expected.convert(Image.FORMAT_RGBA8)
			actual.convert(Image.FORMAT_RGBA8)
			# Importer fixes RGB around alpha borders; verify the resource identity
			# and dimensions instead of requiring byte-identical border colors.
			if expected.get_size() != actual.get_size() or tex.resource_path != path:
				push_error("PNG override mismatch: " + name)
				quit(1)
				return
			verified += 1
	print("New feature PNG overrides verified: ", verified)
	var out := "res://docs/screenshots"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-output="):
			out = arg.trim_prefix("--art-output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for h in ["straw", "beanie", "crown"]:
		g.hat = h
		await _scene("Wardrobe", out + "/new_art_wardrobe_" + h + ".png")
	await _scene("RuleSelect", out + "/new_art_rules.png")
	for tier in [4, 5, 6, 7]:
		g.current_mode = "tier"
		g.current_tier = tier
		g.current_level = 0
		g.hat = "straw"
		change_scene_to_file("res://scenes/Game.tscn")
		await create_timer(0.6).timeout
		current_scene.dismiss_tutorial()
		await create_timer(0.4).timeout
		await _shot(out + "/new_art_rule_%d.png" % tier)
	print("New feature scene captures complete")
	quit()

func _scene(scene: String, path: String) -> void:
	change_scene_to_file("res://scenes/" + scene + ".tscn")
	await create_timer(0.8).timeout
	await _shot(path)

func _shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Capture failed: " + path)
		quit(1)
	print("Captured: ", path)
