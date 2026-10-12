## AchievementsScreen.gd — list of all achievements with progress.
extends Control

var _scroll: ScrollContainer


func _ready() -> void:
	add_to_group("localized")
	add_child(UIKit.background(0.3))
	_build()


func refresh_texts() -> void:
	for c in get_children():
		if not (c is TextureRect or c is ColorRect):
			c.queue_free()
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ins := Global.safe_insets()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24 + int(ins[side]))
	add_child(margin)
	var col := UIKit.vbox(14)
	margin.add_child(col)

	var header := UIKit.hbox(20)
	var back := UIKit.button(Global.T("back"), 140)
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title := UIKit.title(Global.T("achievements"), 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count := UIKit.label(Global.T("ach_count") % [Achievements.unlocked_count(), Achievements.LIST.size()], 20, UITheme.ACCENT)
	count.custom_minimum_size.x = 160
	header.add_child(count)
	col.add_child(header)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(center)
	var list := GridContainer.new()
	list.columns = 2
	list.add_theme_constant_override("h_separation", 12)
	list.add_theme_constant_override("v_separation", 10)
	center.add_child(list)

	var s := Achievements.stats()
	# unlocked first, then the closest to completion
	var entries: Array = Achievements.LIST.duplicate()
	entries.sort_custom(func(a, b):
		var ua := Achievements.is_unlocked(a[0])
		var ub := Achievements.is_unlocked(b[0])
		if ua != ub:
			return ua
		return float(Achievements.progress_of(a, s)) / Achievements.goal_of(a) > float(Achievements.progress_of(b, s)) / Achievements.goal_of(b))
	var i := 0
	for e in entries:
		var row := _row(e, s)
		list.add_child(row)
		Juice.fade_in(row, i * 0.015)
		i += 1
	back.grab_focus()


func _row(e: Array, s: Dictionary) -> PanelContainer:
	var unlocked := Achievements.is_unlocked(e[0])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 78)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 6)
	panel.add_child(m)
	var row := UIKit.hbox(14)
	m.add_child(row)
	var icon := UIKit.icon("star_on" if unlocked else "lock", 46)
	row.add_child(icon)
	var text := UIKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_child(UIKit.panel_label(Achievements.entry_name(e), 21, UITheme.ACCENT if unlocked else UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var desc := UIKit.panel_label(Achievements.entry_desc(e), 15, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(desc)
	row.add_child(text)
	var goal := Achievements.goal_of(e)
	var prog := UIKit.panel_label("%d / %d" % [Achievements.progress_of(e, s), goal], 16, UITheme.TEXT_DIM)
	prog.custom_minimum_size.x = 80
	row.add_child(prog)
	if not unlocked:
		panel.modulate = Color(1, 1, 1, 0.75)
	return panel


func _go_back() -> void:
	Transition.go("res://scenes/MainMenu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_scroll.scroll_vertical += 90
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_scroll.scroll_vertical -= 90
