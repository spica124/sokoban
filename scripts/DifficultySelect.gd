## DifficultySelect.gd — pick a tier of one group, then go to its stage select.
## group "main": easy / normal / hard / expert (after "Play" on the main menu)
## group "rule": the new-rule chapters (RuleSelect.gd sets the group). A rule
## chapter opens once RULE_UNLOCK stages of the previous chapter are cleared.
extends Control

const RULE_UNLOCK := 8

var group := "main"
var _content: Control


func _ready() -> void:
	add_to_group("localized")
	add_child(UIKit.background(0.18))
	_build()


func refresh_texts() -> void:
	if _content:
		_content.queue_free()
	_build()


func _build() -> void:
	_content = CenterContainer.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_content)
	var col := UIKit.vbox(10)
	_content.add_child(col)
	var rules := group == "rule"
	col.add_child(UIKit.title(Global.T("rules_title" if rules else "difficulty"), 40))
	var desc := Global.T("rules_desc") % RULE_UNLOCK if rules else Global.T("difficulty_desc")
	col.add_child(UIKit.label(desc, 20, UITheme.TEXT_DIM))
	col.add_child(UIKit.spacer(4))

	var first: Button = null
	var target: Button = null
	var tiers := Levels.group_tiers(group)
	for k in tiers.size():
		var t: int = tiers[k]
		var card := _make_card(t, k)
		col.add_child(card)
		Juice.fade_in(card, 0.05 + k * 0.06)
		if first == null and not card.disabled:
			first = card
		if t == Global.current_tier and not card.disabled:
			target = card
	col.add_child(UIKit.spacer(4))
	var back := UIKit.button(Global.T("back"), 200)
	back.pressed.connect(_go_back)
	col.add_child(back)
	# focus the tier the player last played (when it belongs to this group)
	if target:
		target.grab_focus()
	elif first:
		first.grab_focus()


## One wide button per tier: name, description and progress on three lines
## A rule chapter is locked until the previous one has RULE_UNLOCK clears
func _locked(t: int, k: int) -> bool:
	if group != "rule" or k == 0:
		return false
	var prev: int = Levels.group_tiers(group)[k - 1]
	return Global.tier_done(prev) < min(RULE_UNLOCK, Levels.count(prev))


func _make_card(t: int, k := 0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(680, 104 if Global.settings["lang"] == "en" else 92)
	var done := Global.tier_done(t)
	var total := Levels.count(t)
	var stars := Global.tier_stars(t)
	b.tooltip_text = Levels.tier_name(t) + ": " + Levels.tier_desc(t)
	var row := UIKit.hbox(18)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = 8
	row.offset_bottom = -8
	b.add_child(row)
	var id := Levels.tier_id(t)
	row.add_child(UIKit.icon(id if group == "rule" else "tier_" + id, 68))
	var copy := UIKit.vbox(2)
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(UIKit.label(Levels.tier_name(t), 25, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_LEFT))
	var locked := _locked(t, k)
	var desc_text := Levels.tier_desc(t)
	if locked:
		var prev: int = Levels.group_tiers(group)[k - 1]
		desc_text = Global.T("rule_locked") % [Levels.tier_name(prev), RULE_UNLOCK]
	var description := UIKit.label(desc_text, 17, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	var progress := UIKit.vbox(2)
	progress.alignment = BoxContainer.ALIGNMENT_CENTER
	var score := UIKit.hbox(4)
	score.alignment = BoxContainer.ALIGNMENT_CENTER
	score.add_child(UIKit.icon("star_on", 28))
	score.add_child(UIKit.label("%d / %d" % [stars, total * 3], 17, UITheme.ACCENT))
	progress.add_child(score)
	progress.add_child(UIKit.label("%s %d / %d" % [Global.T("progress"), done, total], 15, UITheme.TEXT_DIM))
	row.add_child(progress)
	if locked:
		row.add_child(UIKit.icon("lock", 40))
		b.disabled = true
		row.modulate.a = 0.6
	UIKit.ignore_mouse(row)
	b.pressed.connect(func(): _pick(t))
	return b


func _pick(t: int) -> void:
	if Transition.is_busy():
		return
	Global.current_mode = "tier"
	Global.current_tier = t
	Global.current_level = Global.next_unfinished_level(t)
	Global.save()
	Transition.go("res://scenes/StageSelect.tscn")


func _go_back() -> void:
	Transition.go("res://scenes/MainMenu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
