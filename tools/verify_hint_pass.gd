## verify_hint_pass.gd — hint passes + rewarded-ad unlock flow (phone rules on PC).
## Run: Godot --headless --path . --script res://tools/verify_hint_pass.gd -- --fakeads --touch
## Writes save.json — delete it afterwards.
extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var g = root.get_node("Global")
	var ads = root.get_node("Ads")
	check(ads.enabled(), "--fakeads turns the hint economy on")
	g.settings["anim"] = false
	g.settings["vibrate"] = false
	g.progress = {}
	g.hint_passes = 0
	g.hint_pass_day = ""
	g.hint_open = {}

	# --- daily top-up ---
	g.refill_hint_passes()
	check(g.hint_passes == g.FREE_HINT_PASSES, "first top-up of the day gives the free passes")
	g.hint_passes = 1
	g.refill_hint_passes()
	check(g.hint_passes == 1, "a second top-up on the same day changes nothing")
	g.hint_pass_day = "2000-01-01"
	g.hint_passes = 7
	g.refill_hint_passes()
	check(g.hint_passes == 7, "top-up never takes passes away")
	g.give_hint_passes(2, "test")
	check(g.hint_passes == 9, "rewards add passes")

	# --- game scene: first hint opens the offer ---
	g.current_mode = "tier"
	g.current_tier = 1
	g.current_level = 3
	g.seen_rules = {"color": true, "ice": true, "oneway": true, "mix": true}
	g.progress["easy/0"] = {"stars": 1}      # skip the how-to overlay
	g.hint_passes = 2
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.5).timeout
	game.dismiss_tutorial()
	var key: String = game._level_key()
	check(key == "normal/3", "level key matches progress keys")
	check(game._hint_btn != null and game._hint_btn.text == g.T("hint_btn_count") % 2, "touch hint button shows the pass count")
	game.request_hint()
	check(game._overlay != null, "first hint on a stage opens the unlock offer")
	check(game._hint_nodes.is_empty(), "no hint is shown before unlocking")
	game._unlock_hints(true)
	check(g.hint_passes == 1 and g.hint_open.has(key), "using a pass spends one and unlocks the stage")
	check(game._overlay == null and not game._hint_nodes.is_empty(), "the hint appears right after unlocking")
	check(game._hint_btn.text == g.T("hint_btn"), "button drops the count once unlocked")
	game._clear_hint()
	game.request_hint()
	check(game._overlay == null and g.hint_passes == 1, "later hints on the same stage are free")

	# --- next stage, no passes: rewarded ad ---
	g.hint_passes = 0
	game.level_index = 4
	game.level = root.get_node("Levels").get_level(1, 4)
	game._load_level()
	await create_timer(0.3).timeout
	game.request_hint()
	check(game._overlay != null, "stage 5 asks again")
	var buttons: Array = []
	_collect_buttons(game._overlay, buttons)
	var texts := buttons.map(func(b): return b.text)
	check(not texts.has(g.T("hint_use_pass") % 0), "no pass button with zero passes")
	check(texts.has(g.T("hint_watch_ad")), "ad button offered while an ad is ready")
	for b in buttons:
		if b.text == g.T("hint_watch_ad"):
			b.pressed.emit()
	await create_timer(0.2).timeout
	check(game._overlay != null and not ads.is_ready(), "offer stays open while the ad plays")
	await create_timer(ads.FAKE_AD_SECONDS + 0.8).timeout
	check(g.hint_open.has("normal/4"), "finished ad unlocks the stage")
	check(game._overlay == null and not game._hint_nodes.is_empty(), "hint shows after the ad")

	# --- ad not available ---
	ads._fake = "fail"
	game.level_index = 5
	game.level = root.get_node("Levels").get_level(1, 5)
	game._load_level()
	await create_timer(0.3).timeout
	game.request_hint()
	buttons.clear()
	_collect_buttons(game._overlay, buttons)
	var ad_btn: Button = null
	for b in buttons:
		if b.text == g.T("hint_ad_loading"):
			ad_btn = b
	check(ad_btn != null and ad_btn.disabled, "ad button waits ('loading') when no ad is ready")
	game._close_overlay()
	check(not g.hint_open.has("normal/5"), "cancel leaves the stage locked")

	# --- star cap still applies after an unlock ---
	ads._fake = "ok"
	game.level_index = 4
	game.level = root.get_node("Levels").get_level(1, 4)
	game._load_level()
	await create_timer(0.3).timeout
	game.request_hint()
	check(game._hint_used, "using a hint marks the stage")

	# --- desktop rule: no economy ---
	ads._fake = ""
	check(not ads.enabled() and g.hints_unlocked("normal/9"), "PC builds keep hints free")

	print("HINT PASS CHECKS COMPLETE; failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _collect_buttons(node: Node, out: Array) -> void:
	for c in node.get_children():
		if c is Button:
			out.append(c)
		_collect_buttons(c, out)
