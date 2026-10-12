## StageSelect.gd — paged grid of level cards for the current tier
## (Global.current_tier). 50 cards per page; Q/E or shoulder buttons flip pages.
extends Control

const COLUMNS := 10
const ROWS := 5
const PER_PAGE := COLUMNS * ROWS

var _content: Control
var _page := 0
var _tier := 0


func _ready() -> void:
	add_to_group("localized")
	add_child(UIKit.background(0.24))
	_tier = clamp(Global.current_tier, 0, Levels.tier_count() - 1)
	# open on the page that holds the next unfinished stage
	_page = int(Global.next_unfinished_level(_tier) / float(_per_page()))
	_build()


func refresh_texts() -> void:
	_build()


func _page_count() -> int:
	return max(1, ceili(float(Levels.count(_tier)) / _per_page()))


func _per_page() -> int:
	return 24 if Global.is_touch_device() else PER_PAGE


func _build() -> void:
	if _content:
		_content.queue_free()
	_page = clamp(_page, 0, _page_count() - 1)
	_content = MarginContainer.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var insets := Global.safe_insets()
	for side in ["left", "right", "top", "bottom"]:
		_content.add_theme_constant_override("margin_" + side, 24 + int(insets[side]))
	add_child(_content)
	var col := UIKit.vbox(14)
	_content.add_child(col)
	col.add_child(_build_header())

	# --- grid for this page ---
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 6 if Global.is_touch_device() else COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	center.add_child(grid)

	var first_idx := _page * _per_page()
	var last_idx: int = min(first_idx + _per_page(), Levels.count(_tier))
	var focus_target: Button = null
	var next_unfinished := Global.next_unfinished_level(_tier)
	for i in range(first_idx, last_idx):
		var card := _make_card(i)
		grid.add_child(card)
		Juice.fade_in(card, (i - first_idx) * 0.006)
		if i == next_unfinished:
			focus_target = card
	if focus_target == null and grid.get_child_count() > 0:
		focus_target = grid.get_child(0)

	col.add_child(_build_pager())
	if focus_target:
		await get_tree().process_frame
		if is_instance_valid(focus_target):
			focus_target.grab_focus()


func _build_header() -> HBoxContainer:
	var header := UIKit.hbox(20)
	var back := UIKit.button(Global.T("back"), 140)
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title := UIKit.title("%s · %s" % [Levels.tier_name(_tier), Global.T("stage_select")], 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var stars := UIKit.hbox(6)
	stars.add_child(UIKit.icon("star_on", 32))
	stars.add_child(UIKit.label("%d / %d" % [Global.tier_stars(_tier), Levels.count(_tier) * 3], 22, UITheme.ACCENT))
	stars.custom_minimum_size.x = 150
	header.add_child(stars)
	return header


## "◀  1 / 4  ▶" row under the grid
func _build_pager() -> HBoxContainer:
	var row := UIKit.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var touch := Global.is_touch_device()
	var prev := UIKit.button("◀" if touch else "◀  Q", 110)
	prev.disabled = _page == 0
	prev.pressed.connect(func(): _flip(-1))
	row.add_child(prev)
	var lbl := UIKit.label("%d / %d" % [_page + 1, _page_count()], 22)
	lbl.custom_minimum_size.x = 120
	row.add_child(lbl)
	var next := UIKit.button("▶" if touch else "E  ▶", 110)
	next.disabled = _page >= _page_count() - 1
	next.pressed.connect(func(): _flip(1))
	row.add_child(next)
	return row


func _flip(delta: int) -> void:
	var np: int = clamp(_page + delta, 0, _page_count() - 1)
	if np == _page:
		return
	_page = np
	_build()


func _make_card(i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 102) if Global.is_touch_device() else Vector2(108, 84)
	var content := CenterContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(content)
	var col := UIKit.vbox(0)
	content.add_child(col)
	col.add_child(UIKit.label(str(i + 1), 22))
	# Reserve identical icon and time rows in every state. Otherwise completed
	# cards grow an extra line and their stage numbers jump above the neighbours.
	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(72, 26)
	col.add_child(icon_slot)
	var time_label := UIKit.label(" ", 13, UITheme.TEXT_DIM)
	col.add_child(time_label)
	b.tooltip_text = "%s %d" % [Global.T("stage_select"), i + 1]
	if not Global.is_unlocked(_tier, i):
		icon_slot.add_child(UIKit.icon("lock", 26))
		b.disabled = true
		content.modulate.a = 0.6
		UIKit.ignore_mouse(content)
		return b
	var rec := Global.record_for(_tier, i)
	if rec.is_empty():
		icon_slot.add_child(UIKit.stars(0, 21))
	else:
		icon_slot.add_child(UIKit.stars(Global.stars_for(_tier, i), 21))
		time_label.text = Global.format_time(float(rec["time"]))
	UIKit.ignore_mouse(content)
	b.pressed.connect(func(): _start_level(i))
	return b


func _start_level(i: int) -> void:
	if Transition.is_busy():
		return
	Global.current_mode = "tier"
	Global.current_level = i
	Global.save()
	Transition.go("res://scenes/Game.tscn")


func _go_back() -> void:
	if Levels.tier_group(_tier) == "rule":
		Transition.go("res://scenes/RuleSelect.tscn")
	else:
		Transition.go("res://scenes/DifficultySelect.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
	elif event.is_action_pressed("page_prev"):
		get_viewport().set_input_as_handled()
		_flip(-1)
	elif event.is_action_pressed("page_next"):
		get_viewport().set_input_as_handled()
		_flip(1)
