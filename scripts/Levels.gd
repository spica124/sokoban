## Levels.gd — loads every difficulty tier (autoload "Levels").
##
## Tiers are fixed in TIERS (id + file). Each file uses the standard sokoban
## text format: levels separated by blank lines, metadata as "; key: value".
##   ; name: 첫 걸음
##   ; name_en: First Steps
##   ; par: 6            <- optimal move count, written by tools/validate_*.py
##   ; solution: RRUL    <- used by DevTools --solve
##   #######
##   # @$. #
##   #######
## Level names default to "Stage N" when a file gives none (e.g. Boxoban sets).
##
## Tiers come in two groups: "main" (the four difficulties) and "rule" (the
## rule-variant chapters from tools/variants.py). Both use the same stage
## select, progress keys ("<tier id>/<index>") and game screen.
## The daily puzzle pool (levels/daily.txt, meta "band" 0-6) is loaded lazily.
extends Node

const TIERS := [
	{"id": "easy", "file": "res://levels/easy.txt", "group": "main"},
	{"id": "normal", "file": "res://levels/normal.txt", "group": "main"},
	{"id": "hard", "file": "res://levels/hard.txt", "group": "main"},
	{"id": "expert", "file": "res://levels/expert.txt", "group": "main"},
	{"id": "rule_color", "file": "res://levels/rule_color.txt", "group": "rule"},
	{"id": "rule_ice", "file": "res://levels/rule_ice.txt", "group": "rule"},
	{"id": "rule_oneway", "file": "res://levels/rule_oneway.txt", "group": "rule"},
	{"id": "rule_mix", "file": "res://levels/rule_mix.txt", "group": "rule"},
]
const DAILY_FILE := "res://levels/daily.txt"
const DAILY_BANDS := 7

var tiers: Array = []   # each: {"id": String, "group": String, "levels": Array}
var _daily: Array = []  # DAILY_BANDS arrays of levels, filled on first use


func _ready() -> void:
	for t in TIERS:
		tiers.append({"id": t["id"], "group": t["group"], "levels": _load_file(t["file"])})


## Tier indices of one group, in display order
func group_tiers(group: String) -> Array:
	var out: Array = []
	for i in tiers.size():
		if tiers[i]["group"] == group:
			out.append(i)
	return out


func tier_group(t: int) -> String:
	return tiers[clamp(t, 0, tiers.size() - 1)]["group"]


func tier_index(id: String) -> int:
	for i in tiers.size():
		if tiers[i]["id"] == id:
			return i
	return -1


## ---------- daily puzzle ----------
## Monday = band 0 (gentlest) ... Sunday = band 6 (toughest). The pick inside the
## band is a stable hash of the date, so everyone gets the same puzzle that day.
func daily_level(date: String) -> Dictionary:
	if _daily.is_empty():
		for i in DAILY_BANDS:
			_daily.append([])
		for lv in _load_file(DAILY_FILE):
			_daily[clamp(int(lv.get("band", 0)), 0, DAILY_BANDS - 1)].append(lv)
	var band := daily_band(date)
	var list: Array = _daily[band]
	if list.is_empty():
		return _empty_level()
	var lv: Dictionary = list[posmod(date.hash(), list.size())].duplicate()
	lv["name"] = date
	lv["name_en"] = date
	return lv


func daily_band(date: String) -> int:
	var unix := Time.get_unix_time_from_datetime_string(date + "T12:00:00")
	var wd: int = Time.get_datetime_dict_from_unix_time(unix)["weekday"]   # 0 = Sunday
	return (wd + 6) % 7


## ---------- queries ----------
func tier_count() -> int:
	return tiers.size()


func tier_id(t: int) -> String:
	return tiers[clamp(t, 0, tiers.size() - 1)]["id"]


func count(t: int) -> int:
	if t < 0 or t >= tiers.size():
		return 0
	return tiers[t]["levels"].size()


func total_count() -> int:
	var n := 0
	for t in tiers:
		n += t["levels"].size()
	return n


func get_level(t: int, i: int) -> Dictionary:
	if count(t) == 0:
		return _empty_level()
	var list: Array = tiers[t]["levels"]
	return list[clamp(i, 0, list.size() - 1)]


## Display name in the current language
func display_name(t: int, i: int) -> String:
	var lv := get_level(t, i)
	if Global.settings["lang"] == "en" and lv["name_en"] != "":
		return lv["name_en"]
	return lv["name"]


## Tier name / description in the current language (keys tier_<id>, tier_<id>_desc)
func tier_name(t: int) -> String:
	return Global.T("tier_" + tier_id(t))


func tier_desc(t: int) -> String:
	return Global.T("tier_" + tier_id(t) + "_desc")


## ---------- parsing ----------
func _load_file(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("level file not found: " + path)
		return out
	var current := _empty_level()
	for raw_line in f.get_as_text().split("\n"):
		var line := raw_line.trim_suffix("\r")
		if line.strip_edges() == "":
			_flush(current, out)
			current = _empty_level()
		elif line.begins_with(";"):
			_parse_meta(line, current)
		else:
			current["rows"].append(line)
	_flush(current, out)
	return out


func _empty_level() -> Dictionary:
	return {"name": "", "name_en": "", "par": 0, "solution": "", "rows": []}


## Metadata keys copied verbatim into the level dictionary (rule variants, daily band)
const PASS_META := ["rules", "boxcolor", "goalcolor", "ice", "oneway", "band", "source"]


func _flush(level: Dictionary, out: Array) -> void:
	if level["rows"].is_empty():
		return
	if level["name"] == "":
		level["name"] = "%s %d" % [Global.T("level"), out.size() + 1]
		level["name_en"] = "Stage %d" % (out.size() + 1)
	out.append(level)


func _parse_meta(line: String, level: Dictionary) -> void:
	var body := line.trim_prefix(";").strip_edges()
	var sep := body.find(":")
	if sep < 0:
		return
	var key := body.substr(0, sep).strip_edges()
	var value := body.substr(sep + 1).strip_edges()
	match key:
		"name": level["name"] = value
		"name_en": level["name_en"] = value
		"par": level["par"] = int(value)
		"solution": level["solution"] = value
		_:
			if key in PASS_META:
				level[key] = value
