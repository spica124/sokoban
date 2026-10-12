## Achievements.gd — achievements, hat rewards and unlock toasts (autoload "Achievements").
##
## Everything is derived from saved progress, so achievements also unlock
## retroactively for old saves. Call `evaluate()` after anything that changes
## progress; it saves, shows toasts and (when GodotSteam is installed) mirrors
## the unlock to Steam with the same id.
extends CanvasLayer

## id, stat, goal, Korean / English name and description
const LIST := [
	["first_clear", "clears", 1, "첫 배달", "First Delivery", "스테이지를 처음으로 클리어", "Clear your first stage"],
	["clears_25", "clears", 25, "부지런한 일꾼", "Hard Worker", "스테이지 25개 클리어", "Clear 25 stages"],
	["clears_100", "clears", 100, "창고 관리인", "Pantry Keeper", "스테이지 100개 클리어", "Clear 100 stages"],
	["clears_300", "clears", 300, "창고 대장", "Pantry Boss", "스테이지 300개 클리어", "Clear 300 stages"],
	["clears_800", "clears", 800, "창고의 전설", "Pantry Legend", "네 난이도의 800판을 모두 클리어", "Clear all 800 difficulty stages"],
	["stars_50", "stars", 50, "별 모으기", "Star Collector", "별 50개 모으기", "Collect 50 stars"],
	["stars_300", "stars", 300, "별 부자", "Star Hoarder", "별 300개 모으기", "Collect 300 stars"],
	["stars_1000", "stars", 1000, "별의 바다", "Sea of Stars", "별 1000개 모으기", "Collect 1000 stars"],
	["perfect_50", "perfect", 50, "완벽주의 카피바라", "Perfectionist", "별 3개로 50판 클리어", "Clear 50 stages with 3 stars"],
	["tier_easy", "tier_easy", -1, "쉬움 정복", "Easy Mastered", "쉬움 200판을 모두 클리어", "Clear every Easy stage"],
	["tier_normal", "tier_normal", -1, "보통 정복", "Normal Mastered", "보통 200판을 모두 클리어", "Clear every Normal stage"],
	["tier_hard", "tier_hard", -1, "어려움 정복", "Hard Mastered", "어려움 200판을 모두 클리어", "Clear every Hard stage"],
	["tier_expert", "tier_expert", -1, "극한 정복", "Expert Mastered", "극한 200판을 모두 클리어", "Clear every Expert stage"],
	["starcraft", "starcraft", 24, "원작의 맛", "The Original", "어려움 앞쪽 원작 24판 클리어", "Clear the 24 original stages in Hard"],
	["noundo_hard", "noundo_hard", 1, "한 번에 쭉", "No Take-backs", "어려움·극한 판을 되돌리기 없이 클리어", "Clear a Hard or Expert stage without undo"],
	["nohint_expert", "nohint_expert", 10, "스스로 해냈다", "All By Myself", "극한 10판을 힌트 없이 클리어", "Clear 10 Expert stages without hints"],
	["fast", "fast", 1, "번개 배달", "Express Delivery", "보통 이상 판을 30초 안에 클리어", "Clear a Normal+ stage in under 30 s"],
	["daily_1", "daily", 1, "오늘의 첫 퍼즐", "First Daily", "오늘의 퍼즐을 처음으로 클리어", "Clear your first Daily Puzzle"],
	["daily_30", "daily", 30, "꾸준한 일꾼", "Regular", "오늘의 퍼즐 30번 클리어", "Clear 30 Daily Puzzles"],
	["streak_3", "streak", 3, "사흘 연속", "Three in a Row", "오늘의 퍼즐 3일 연속", "Daily Puzzle 3 days in a row"],
	["streak_7", "streak", 7, "일주일 개근", "Perfect Week", "오늘의 퍼즐 7일 연속", "Daily Puzzle 7 days in a row"],
	["streak_30", "streak", 30, "한 달 개근", "Perfect Month", "오늘의 퍼즐 30일 연속", "Daily Puzzle 30 days in a row"],
	["rule_color", "rule_color", 10, "짝꿍 찾기", "Perfect Match", "짝 맞추기 10판 클리어", "Clear 10 Matching Pairs stages"],
	["rule_ice", "rule_ice", 10, "얼음 위의 카피바라", "Capybara on Ice", "미끄러운 얼음 10판 클리어", "Clear 10 Slippery Ice stages"],
	["rule_oneway", "rule_oneway", 10, "길치 탈출", "Way Finder", "한 방향 길 10판 클리어", "Clear 10 One-Way Paths stages"],
	["rule_mix", "rule_mix", -1, "규칙 마스터", "Rule Master", "섞어서 장을 모두 클리어", "Clear every Mixed stage"],
]

## Hats: id, Korean / English name, requirement ["stars", n] or ["ach", id]
const HATS := [
	["straw", "밀짚모자", "Straw Hat", ["stars", 15]],
	["mandarin", "귤", "Mandarin", ["ach", "daily_1"]],
	["flower", "꽃 화관", "Flower Crown", ["stars", 60]],
	["leaf", "나뭇잎", "Leaf", ["ach", "rule_ice"]],
	["chef", "요리사 모자", "Chef Hat", ["stars", 200]],
	["beanie", "털모자", "Beanie", ["ach", "streak_7"]],
	["grad", "학사모", "Graduation Cap", ["ach", "nohint_expert"]],
	["crown", "왕관", "Crown", ["stars", 600]],
]

var _queue: Array = []
var _showing := false


func _ready() -> void:
	layer = 95
	# retroactive unlocks for saves made before achievements existed (silent)
	evaluate.call_deferred(false)


## ---------- stats ----------
func stats() -> Dictionary:
	var s := {"clears": 0, "stars": 0, "perfect": 0, "starcraft": 0, "noundo_hard": 0,
		"nohint_expert": 0, "fast": 0, "daily": Global.daily_count(), "streak": max(Global.best_streak, Global.daily_streak())}
	for t in Levels.tier_count():
		s["tier_" + Levels.tier_id(t)] = 0
		s[Levels.tier_id(t)] = 0
	for k in Global.progress.keys():
		var parts := str(k).split("/")
		if parts.size() != 2 or parts[0] == "daily":
			continue
		var id := parts[0]
		var idx := int(parts[1])
		var t := Levels.tier_index(id)
		if t < 0:
			continue
		var rec: Dictionary = Global.progress[k]
		s[id] = int(s.get(id, 0)) + 1
		s["tier_" + id] = int(s.get("tier_" + id, 0)) + 1
		if Levels.tier_group(t) != "main":
			continue
		s["clears"] += 1
		s["stars"] += int(rec.get("stars", 0))
		if int(rec.get("stars", 0)) >= 3:
			s["perfect"] += 1
		if id == "hard" and idx < 24:
			s["starcraft"] += 1
		if (id == "hard" or id == "expert") and bool(rec.get("noundo", false)):
			s["noundo_hard"] += 1
		if id == "expert" and bool(rec.get("nohint", false)):
			s["nohint_expert"] += 1
		if id != "easy" and float(rec.get("time", INF)) < 30.0:
			s["fast"] += 1
	return s


## Goal of an achievement (-1 in LIST means "the whole tier")
func goal_of(entry: Array) -> int:
	if int(entry[2]) >= 0:
		return int(entry[2])
	var id: String = str(entry[1]).trim_prefix("tier_")
	return max(1, Levels.count(Levels.tier_index(id)))


func progress_of(entry: Array, s: Dictionary) -> int:
	return min(int(s.get(entry[1], 0)), goal_of(entry))


func is_unlocked(id: String) -> bool:
	return Global.achievements.has(id)


func entry_name(entry: Array) -> String:
	return entry[3] if Global.settings["lang"] == "ko" else entry[4]


func entry_desc(entry: Array) -> String:
	return entry[5] if Global.settings["lang"] == "ko" else entry[6]


func unlocked_count() -> int:
	var n := 0
	for e in LIST:
		if is_unlocked(e[0]):
			n += 1
	return n


## Check everything; unlock, toast and save what is new. Returns the new ids.
func evaluate(toast := true) -> Array:
	var s := stats()
	var fresh: Array = []
	for e in LIST:
		if is_unlocked(e[0]):
			continue
		if int(s.get(e[1], 0)) >= goal_of(e):
			Global.achievements[e[0]] = int(Time.get_unix_time_from_system())
			fresh.append(e[0])
			_steam_unlock(e[0])
			if toast:
				_push_toast("star_on", Global.T("ach_unlocked"), entry_name(e))
	for h in HATS:
		if hat_unlocked(h[0]) and not (h[0] in Global.hats_seen):
			Global.hats_seen.append(h[0])
			if toast:
				_push_toast("", Global.T("hat_unlocked"), hat_name(h[0]), "hat_" + h[0])
	if not fresh.is_empty() or toast:
		Global.save()
	if toast and not fresh.is_empty():
		Global.give_hint_passes(fresh.size(), Global.T("hint_pass_from_ach"))
	return fresh


## ---------- hats ----------
func hat_entry(id: String) -> Array:
	for h in HATS:
		if h[0] == id:
			return h
	return []


func hat_name(id: String) -> String:
	var h := hat_entry(id)
	if h.is_empty():
		return Global.T("hat_none")
	return h[1] if Global.settings["lang"] == "ko" else h[2]


func hat_unlocked(id: String) -> bool:
	var h := hat_entry(id)
	if h.is_empty():
		return id == ""
	var req: Array = h[3]
	if req[0] == "stars":
		return int(stats()["stars"]) >= int(req[1])
	return is_unlocked(req[1])


func hat_requirement(id: String) -> String:
	var h := hat_entry(id)
	if h.is_empty():
		return ""
	var req: Array = h[3]
	if req[0] == "stars":
		return Global.T("req_stars") % int(req[1])
	for e in LIST:
		if e[0] == req[1]:
			return Global.T("req_ach") % entry_name(e)
	return ""


## ---------- Steam ----------
## Works once the GodotSteam add-on is installed; achievement ids match LIST.
func _steam_unlock(id: String) -> void:
	if Engine.has_singleton("Steam"):
		var steam := Engine.get_singleton("Steam")
		steam.call("setAchievement", id)
		steam.call("storeStats")


## ---------- toasts ----------
## Same corner toast for other rewards (hint passes)
func notify(title: String, body: String, icon_ui := "star_on") -> void:
	_push_toast(icon_ui, title, body)


func _push_toast(icon_ui: String, title: String, body: String, sprite := "") -> void:
	_queue.append([icon_ui, title, body, sprite])
	if not _showing:
		_next_toast()


func _next_toast() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var item: Array = _queue.pop_front()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# a CanvasLayer cuts theme inheritance, so hand the shared theme over explicitly
	panel.theme = get_window().theme
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var row := UIKit.hbox(14)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Assets.tex(item[3]) if item[3] != "" else Assets.art("ui", item[0])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(52, 52)
	row.add_child(icon)
	var col := UIKit.vbox(0)
	col.add_child(UIKit.panel_label(item[1], 16, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	col.add_child(UIKit.panel_label(item[2], 24, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_LEFT))
	row.add_child(col)
	add_child(panel)
	await get_tree().process_frame
	# top-right corner: the centre is taken by the result panel that opens on a clear
	var vw := get_viewport().get_visible_rect().size.x
	var ins := Global.safe_insets()
	panel.position = Vector2(vw - panel.size.x - 16 - float(ins["right"]), -panel.size.y - 10)
	Juice.haptic(30, 0.5)
	var tw := create_tween()
	tw.tween_property(panel, "position:y", 14.0 + float(ins["top"]), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.3)
	tw.tween_property(panel, "position:y", -panel.size.y - 10, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	panel.queue_free()
	_next_toast()
