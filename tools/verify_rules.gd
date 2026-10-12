## verify_rules.gd — cross-checks the game's rules against the Python generator.
## Run: Godot --headless --path . --script res://tools/verify_rules.gd [-- --vchain=N --vdaily=N]
##
## 1. Every stored solution (all tiers + rule chapters + a daily sample) must solve
##    its level when replayed through Board.gd.
## 2. Following the hint solver push by push must solve the level with the same
##    number of pushes as the stored (push-optimal) solution — on every rule level
##    and on a sample of the others.
extends SceneTree

var failures := 0
var checked := 0


func _initialize() -> void:
	_run.call_deferred()


func fail(msg: String) -> void:
	failures += 1
	printerr("FAIL: ", msg)


func _run() -> void:
	var levels = root.get_node("Levels")
	var args := {}
	for a in OS.get_cmdline_user_args():
		var eq := a.find("=")
		if eq > 0:
			args[a.substr(2, eq - 2)] = a.substr(eq + 1)
	var chain_every := int(args.get("vchain", "10"))     # hint-chain every Nth main level
	var daily_n := int(args.get("vdaily", "200"))
	var started := Time.get_ticks_msec()

	# 1 + 2 on tiers
	for t in levels.tier_count():
		var id: String = levels.tier_id(t)
		var rule: bool = levels.tier_group(t) == "rule"
		var n: int = levels.count(t)
		if n == 0:
			fail("tier %s has no levels" % id)
		for i in n:
			var lv: Dictionary = levels.get_level(t, i)
			var pushes := _replay(lv, "%s/%d" % [id, i])
			if pushes >= 0 and (rule or i % chain_every == 0):
				_chain(lv, pushes, "%s/%d" % [id, i])
		print("%s: %d levels ok so far (failures=%d, %ds)" % [id, n, failures, (Time.get_ticks_msec() - started) / 1000])

	# daily sample: one per band per date over a range of dates
	var unix := int(Time.get_unix_time_from_system())
	for k in daily_n:
		var d := Time.get_date_dict_from_unix_time(unix + k * 86400)
		var date := "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
		var lv: Dictionary = levels.daily_level(date)
		if lv["rows"].is_empty():
			fail("daily %s empty" % date)
			continue
		var pushes := _replay(lv, "daily " + date)
		if pushes >= 0 and k % chain_every == 0:
			_chain(lv, pushes, "daily " + date)
	print("daily: %d dates ok so far" % daily_n)
	print("RULE CHECKS COMPLETE; levels=%d failures=%d time=%ds" % [checked, failures, (Time.get_ticks_msec() - started) / 1000])
	quit(1 if failures > 0 else 0)


## Replays the stored solution; returns its push count or -1 on failure
func _replay(lv: Dictionary, label: String) -> int:
	checked += 1
	var b := Board.from_rows(lv["rows"], lv)
	var sol: String = lv.get("solution", "")
	if sol == "":
		fail(label + ": no stored solution")
		return -1
	for ch in sol:
		if not b.try_move(Board.LETTER[ch])["moved"]:
			fail("%s: move %s rejected at %d" % [label, ch, b.moves])
			return -1
	if not b.is_solved():
		fail(label + ": stored solution does not solve it")
		return -1
	if int(lv.get("par", 0)) != sol.length():
		fail(label + ": par mismatch")
	return b.pushes


## Follows the hint solver until solved; push count must equal the optimum
func _chain(lv: Dictionary, optimal: int, label: String) -> void:
	var b := Board.from_rows(lv["rows"], lv)
	var used := 0
	while not b.is_solved():
		var r := Solver.first_push(b.snapshot(), 400000, 30000)
		if r["status"] != "ok":
			fail("%s: hint status %s after %d pushes" % [label, r["status"], used])
			return
		var box: Vector2i = r["box"]
		var dir: Vector2i = r["dir"]
		var stand := box - dir
		if stand != b.player:
			var path := b.walk_path(stand)
			if path.is_empty():
				fail("%s: hint asks for an unreachable stand cell" % label)
				return
			for cell in path:
				var step: Vector2i = cell - b.player
				if not b.try_move(step)["moved"]:
					fail("%s: walking path blocked" % label)
					return
		var res := b.try_move(dir)
		if not res["pushed"]:
			fail("%s: hinted push was not a push" % label)
			return
		used += 1
		if used > optimal + 5:
			fail("%s: hint chain too long" % label)
			return
	if used != optimal:
		fail("%s: hints used %d pushes, optimum %d" % [label, used, optimal])
