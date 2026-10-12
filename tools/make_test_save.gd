## make_test_save.gd — writes a save with Easy+Normal cleared at 3 stars (1200 stars,
## most hats unlocked) for checking the wardrobe/achievement screens.
## Run: Godot --headless --path . --script res://tools/make_test_save.gd [-- --hat=crown]
## Overwrites the real save.json — delete it afterwards.
extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var g = root.get_node("Global")
	var levels = root.get_node("Levels")
	for t in 2:
		for i in levels.count(t):
			g.record_result(t, i, 20.0, 50, 10, 3, {})
	var hat := "crown"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hat="):
			hat = a.substr(6)
	g.hat = hat
	g.save()
	root.get_node("Achievements").evaluate(false)
	print("save ready, stars=", root.get_node("Achievements").stats()["stars"])
	quit()
