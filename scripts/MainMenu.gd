## MainMenu.gd — title screen: Play, Daily Puzzle, New Rules, Achievements,
## Wardrobe, Settings, Quit.
extends Control

var _settings_btn: Button


func _ready() -> void:
	add_to_group("localized")
	_build()


## Called by SettingsPanel when the language changes: rebuild everything
func refresh_texts() -> void:
	# Rebuild the menu but keep an open SettingsPanel alive and on top
	var panel: Control = null
	for c in get_children():
		if c is SettingsPanel:
			panel = c
		else:
			c.queue_free()
	_build()
	if panel:
		move_child(panel, get_child_count() - 1)


func _build() -> void:
	add_child(UIKit.background())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := UIKit.vbox(14)
	center.add_child(root)

	# Logo image if provided, else text title
	if Assets.has_file("logo"):
		var logo := TextureRect.new()
		logo.texture = Assets.tex("logo")
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(520, 200)
		root.add_child(logo)
		Juice.breathe(logo)
	else:
		root.add_child(UIKit.title(Global.T("title"), 84))
	root.add_child(UIKit.label(Global.T("subtitle"), 22, UITheme.TEXT_DIM))
	root.add_child(UIKit.spacer(18))

	var has_progress := not Global.progress.is_empty()
	var play := UIKit.button(Global.T("continue") if has_progress else Global.T("play"), 452)
	play.pressed.connect(_on_play)
	var play_row := CenterContainer.new()
	play_row.add_child(play)
	root.add_child(play_row)

	# secondary actions in a two-column grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var grid_center := CenterContainer.new()
	grid_center.add_child(grid)
	root.add_child(grid_center)
	var today := Global.today()
	var daily_text := Global.T("daily")
	if Global.is_daily_done(today):
		daily_text += " · " + Global.T("daily_done")
	elif Global.daily_streak() > 0:
		daily_text += " · " + Global.T("daily_streak") % Global.daily_streak()
	for spec in [[daily_text, _on_daily], [Global.T("rules_menu"), func(): _go("RuleSelect")],
			[Global.T("achievements"), func(): _go("AchievementsScreen")], [Global.T("wardrobe"), func(): _go("Wardrobe")],
			[Global.T("settings"), _open_settings], [Global.T("quit"), func(): get_tree().quit()]]:
		var b := UIKit.button(spec[0], 220)
		b.pressed.connect(spec[1])
		grid.add_child(b)
		if spec[1] == _open_settings:
			_settings_btn = b
	play.grab_focus()

	_build_footer()


## Play always goes through the difficulty picker first
## Android back button on the title screen: close an open settings panel, else quit
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	for c in get_children():
		if c is SettingsPanel:
			c._close()
			return
	get_tree().quit()


func _on_play() -> void:
	if Transition.is_busy():
		return
	Global.current_mode = "tier"
	Transition.go("res://scenes/DifficultySelect.tscn")


func _on_daily() -> void:
	if Transition.is_busy():
		return
	Global.current_mode = "daily"
	Global.daily_date = Global.today()
	Transition.go("res://scenes/Game.tscn")


func _go(scene: String) -> void:
	if Transition.is_busy():
		return
	Transition.go("res://scenes/%s.tscn" % scene)


func _open_settings() -> void:
	var p := SettingsPanel.new()
	add_child(p)
	# the menu may have been rebuilt (language change) while the panel was open,
	# so look the button up again instead of capturing the old node
	p.closed.connect(func():
		if is_instance_valid(_settings_btn):
			_settings_btn.grab_focus())


## Footer: progress (bottom-left) and version (bottom-right)
func _build_footer() -> void:
	var done := Global.total_done()
	var bar := MarginContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.add_theme_constant_override("margin_left", 20)
	bar.add_theme_constant_override("margin_right", 20)
	bar.add_theme_constant_override("margin_bottom", 14)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var row := UIKit.hbox()
	bar.add_child(row)
	var left := UIKit.label("%s  %d / %d" % [Global.T("progress"), done, Levels.total_count()], 18, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var version: String = ProjectSettings.get_setting("application/config/version", "0.0")
	row.add_child(UIKit.label("v" + version, 16, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT))
