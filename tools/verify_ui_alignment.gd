## Real UI geometry and pointer dispatch audit. Fixtures stay in memory.
extends SceneTree

var failures := 0
var checks := 0
var juice

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func buttons(node: Node, result: Array) -> void:
	if node is BaseButton and node.is_visible_in_tree():
		result.append(node)
	for child in node.get_children():
		buttons(child, result)

func _run() -> void:
	juice = load("res://scripts/Juice.gd")
	var global = root.get_node("Global")
	global.settings["anim"] = true
	global.settings["vibrate"] = false
	global.current_tier = 0
	global.progress = {"easy/0": {"stars": 3, "time": 12.34}, "easy/1": {"stars": 2, "time": 25.67}}
	for scene in ["MainMenu", "DifficultySelect", "StageSelect"]:
		change_scene_to_file("res://scenes/%s.tscn" % scene)
		await create_timer(1.0).timeout
		await audit(current_scene, scene)
		if scene == "StageSelect":
			check_stage_rows()
			await pointer_test()
	change_scene_to_file("res://scenes/MainMenu.tscn")
	await create_timer(0.5).timeout
	var panel = load("res://scripts/SettingsPanel.gd").new()
	current_scene.add_child(panel)
	await create_timer(0.6).timeout
	await audit(panel, "settings")
	panel._ask_reset() # open only; never confirm deletion
	await process_frame
	await audit(panel._confirm, "confirm")
	panel.queue_free()
	global.current_tier = 2
	global.current_level = 8
	change_scene_to_file("res://scenes/Game.tscn")
	await create_timer(1.0).timeout
	current_scene.dismiss_tutorial()
	await audit(current_scene, "game")
	current_scene._open_pause()
	await create_timer(0.6).timeout
	await audit(current_scene._overlay, "pause")
	current_scene._close_overlay()
	current_scene._open_complete(2, false)
	await create_timer(0.9).timeout
	await audit(current_scene._overlay, "clear")
	print("UI ALIGNMENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check_stage_rows() -> void:
	var list: Array = []
	buttons(current_scene, list)
	var baseline := -1.0
	var count := 0
	for b in list:
		if b is Button and b.text == "":
			var number: Label = b.get_child(0).get_child(0).get_child(0)
			if baseline < 0:
				baseline = number.global_position.y
			check(absf(number.global_position.y - baseline) < 0.1, "completed, current and locked stage numbers share a baseline")
			count += 1
			if count == 4:
				break

func audit(scope: Node, label: String) -> void:
	var list: Array = []
	buttons(scope, list)
	var rects: Array = []
	for b in list:
		rects.append(b.get_global_rect())
		check(b.get_global_rect().end.y <= root.get_visible_rect().size.y + 1, label + ": button below viewport")
		if not b is CheckButton:
			var normal = b.get_theme_stylebox("normal")
			for state in ["hover", "pressed", "disabled"]:
				var style = b.get_theme_stylebox(state)
				check(style is StyleBoxTexture and normal.texture == style.texture, label + ": state silhouette differs")
	for target in [1.05, 0.92, 1.0]:
		for b in list:
			juice._button_to(b, target, 0.04)
		await create_timer(0.08).timeout
		for i in list.size():
			check(list[i].scale == Vector2.ONE and list[i].get_global_rect().is_equal_approx(rects[i]), label + ": hit area moved during feedback")
	await RenderingServer.frame_post_draw
	var suffix := "touch" if "--touch" in OS.get_cmdline_user_args() else "desktop"
	check(root.get_texture().get_image().save_png("res://docs/screenshots/alignment_%s_%s.png" % [label, suffix]) == OK, "capture " + label)
	print("PASS: ", label, " (", list.size(), " controls)")

func pointer_test() -> void:
	var list: Array = []
	buttons(current_scene, list)
	var target: Button
	for b in list:
		if b is Button and b.text == "" and not b.disabled:
			target = b
			break
	check(target != null, "stage card target exists")
	if target == null:
		return
	# Isolate navigation so actual pointer events cannot write player progress.
	var connections := target.pressed.get_connections()
	for connection in connections:
		target.pressed.disconnect(connection.callable)
	var clicks := {"count": 0}
	var spy := func(): clicks["count"] += 1
	target.pressed.connect(spy)
	var rect := target.get_global_rect()
	for point in [rect.get_center(), Vector2(rect.end.x - 2, rect.get_center().y)]:
		await click_at(point)
	check(clicks["count"] == 2, "center and right edge each activate exactly once")
	await click_at(Vector2(rect.end.x + 3, rect.get_center().y))
	check(clicks["count"] == 2, "card gap does not activate the card")
	check(target.get_global_rect().is_equal_approx(rect), "real pointer press leaves geometry fixed")
	target.pressed.disconnect(spy)
	for connection in connections:
		target.pressed.connect(connection.callable)
	print("PASS: real stage-card pointer dispatch")

func click_at(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	root.push_input(move, true)
	await process_frame
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
