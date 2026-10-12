## Game.gd — gameplay screen.
##
## Layout
##   HUD (top bar)        : level name | timer | moves / pushes / boxes
##   BoardArea (middle)   : Node2D with sprites, auto-fitted to the window
##   Hint (bottom)        : controls reminder
##   Overlays             : pause panel, level-complete panel, settings
##
## Rules live in Board.gd; this file only renders and animates.
## Modes: "tier" (difficulty and rule chapters) and "daily" (Global.daily_date).
extends Control

const TILE_MAX := 96.0
const TILE_MAX_TOUCH := 140.0  # phones: let small boards fill the screen
const MOVE_TIME := 0.11        # seconds per step animation
const HOLD_DELAY := 0.22       # delay before key auto-repeat starts
const HOLD_REPEAT := 0.09      # auto-repeat interval
const UNDO_TINT := Color(0.72, 0.86, 1.35)   # quick "rewind" blue flash on undo
const PAD_SIZE := 88.0         # on-screen D-pad button size (logical px)
## Hat anchor (head top) per facing, in 256-px player-texture space
# The front sprite's forehead is below the top of its rounded back.
const HAT_ANCHOR := {"down": Vector2(0, -66), "up": Vector2(0, -92), "left": Vector2(-45, -74), "right": Vector2(44, -77)}
const DIRS := {
	"move_up": Vector2i.UP, "move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT, "move_right": Vector2i.RIGHT,
}

var board: Board
var mode := "tier"
var tier := 0
var level_index := 0
var level: Dictionary

# --- nodes ---
var _board_area: Control
var _board_root: Node2D
var _box_nodes := {}          # Vector2i -> Sprite2D
var _static_nodes: Array = []  # floor / goal sprites (meta "cell")
var _player: Sprite2D
var _hud_name: Label
var _hud_time: Label
var _hud_stats: Label
var _hint: Label
var _overlay: Control = null   # currently open pause / complete panel

# --- state ---
var _tile := 64.0
var _origin := Vector2.ZERO
var _elapsed := 0.0
var _running := false          # timer started (first move)
var _completed := false
var _paused := false
var _hold_dir := Vector2i.ZERO
var _hold_timer := 0.0
var _facing := "down"
var _tutorial_open := false
var _input_lock := 0.0         # seconds to ignore movement after closing a panel
var _pad_dir := Vector2i.ZERO     # direction of the D-pad button being held
var _pad_repeat := 0.0
var _tut_layer: Control = null
var _tut_steps: Array = []     # each: {"key": String, "cells": Array}
var _tut_index := 0
var _tut_text: Label
var _tut_counter: Label
var _tut_marks: Array = []     # highlight Panels
var _tut_panel: Control = null # message box (taps inside it go to its Skip button)
var _pause_texts: Array = []   # [node, string key] pairs for live language switch
var _goal_tiles := {}          # Vector2i -> Sprite2D of the pantry spot (for flashes)
var _last_bump := 0.0          # rate limit for wall-bump shake / vibration
var _expression_version := 0  # invalidates a delayed expression after move/restart
var _level_version := 0       # cancels an old completion delay after restart
# --- hints ---
var _hint_used := false        # any hint this attempt (caps the stars at 2)
var _undo_used := false
var _hint_nodes: Array = []    # dots / arrow / ring of the hint on screen
var _hint_last := {}           # last shown hint (redrawn on resize)
var _hint_version := 0         # bumps on every move so stale results are dropped
var _hint_task := -1           # WorkerThreadPool task id, -1 when idle
var _hint_box := {}            # the worker writes "result" here
var _hint_pending := false     # a request arrived while an outdated search was still running
var _hint_btn: Button = null    # touch bar hint button (shows the pass count)
var _hint_banner: PanelContainer
var _hint_label: Label
var _banner_version := 0
var _path_index := {}          # Board.state_key() -> [box, dir] along the stored solution
var _hat: Sprite2D = null


func _ready() -> void:
	add_to_group("localized")
	# The root control must not swallow touches: with the default STOP filter the
	# GUI consumes every tap/drag on the board and _unhandled_input never sees them
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode = Global.current_mode
	if Ads.enabled():
		Global.refill_hint_passes()
	if mode == "daily":
		if Global.daily_date == "":
			Global.daily_date = Global.today()
		level = Levels.daily_level(Global.daily_date)
		tier = -1
		level_index = 0
		if level["rows"].is_empty():
			push_error("Daily pool is empty")
			Transition.go("res://scenes/MainMenu.tscn")
			return
	else:
		tier = clamp(Global.current_tier, 0, Levels.tier_count() - 1)
		if Levels.count(tier) == 0:
			push_error("No levels loaded for tier %d" % tier)
			Transition.go("res://scenes/MainMenu.tscn")
			return
		level_index = clamp(Global.current_level, 0, Levels.count(tier) - 1)
		level = Levels.get_level(tier, level_index)
	_build_ui()
	_load_level(true)
	resized.connect(_layout)
	# A rule the player has not met yet gets its own short explanation; otherwise
	# the very first stage shows the how-to steps until anything has been cleared.
	var rule_steps := _rule_steps()
	if not rule_steps.is_empty():
		_open_tutorial(rule_steps)
	elif mode == "tier" and level_index == 0 and Global.total_done() == 0:
		_open_tutorial()


func _exit_tree() -> void:
	if _hint_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_hint_task)
		_hint_task = -1


## ---------- UI construction ----------
func _build_ui() -> void:
	add_child(UIKit.background(0.22))

	# top bar
	var ins: Dictionary = Global.safe_insets()
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = ins["top"]
	top.custom_minimum_size.y = 64
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0, 0, 0, 0.25)
	top_style.content_margin_left = 24 + ins["left"]
	top_style.content_margin_right = 24 + ins["right"]
	top.add_theme_stylebox_override("panel", top_style)
	add_child(top)
	var row := UIKit.hbox(20)
	top.add_child(row)
	_hud_name = UIKit.label("", 24, UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_hud_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_hud_name)
	_hud_time = UIKit.label("00:00.00", 30, UITheme.ACCENT)
	_hud_time.custom_minimum_size.x = 180
	row.add_child(_hud_time)
	_hud_stats = UIKit.label("", 22, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_hud_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_hud_stats)

	# board area (between top bar and hint)
	_board_area = Control.new()
	_board_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board_area.offset_top = 80 + ins["top"]
	_board_area.offset_bottom = -56 - ins["bottom"]
	_board_area.offset_left = 24 + ins["left"]
	_board_area.offset_right = -24 - ins["right"]
	_board_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_board_area)
	_board_root = Node2D.new()
	_board_area.add_child(_board_root)

	# bottom: keyboard hint, or on-screen buttons on touch devices
	_hint = UIKit.label("", 17, UITheme.TEXT_DIM)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -44
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_hint)
	_build_hint_banner(ins)
	if Global.is_touch_device():
		_hint.visible = false
		# Phones are wide and short: keep the D-pad (left) and action buttons (right)
		# in the side columns and give the board nearly the full height.
		top.custom_minimum_size.y = 52
		var side := 24 + PAD_SIZE * 3 + 24
		_board_area.offset_left = side + ins["left"]
		_board_area.offset_right = -side - ins["right"]
		_board_area.offset_top = 58 + ins["top"]
		_board_area.offset_bottom = -8 - ins["bottom"]
		_build_touch_bar()
	refresh_texts()


## Undo / Restart / Pause buttons along the bottom edge for touch play
func _build_touch_bar() -> void:
	var ins: Dictionary = Global.safe_insets()
	# action buttons stacked in the bottom-right corner
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	col.offset_right = -16 - ins["right"]
	col.offset_left = col.offset_right - 170
	col.offset_bottom = -16 - ins["bottom"]
	col.offset_top = col.offset_bottom - (60 * 4 + 30)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(col)
	for pair in [["hint_btn", request_hint], ["undo", _do_undo], ["restart", _load_level], ["paused", _open_pause]]:
		var b := UIKit.button(Global.T(pair[0]), 170)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(pair[1])
		col.add_child(b)
		if pair[0] == "hint_btn":
			_hint_btn = b
	_build_dpad(ins)


## Four large arrow buttons in the bottom-left corner; hold to keep walking
func _build_dpad(ins: Dictionary) -> void:
	var gap := 6.0
	var span := PAD_SIZE * 3 + gap * 2
	var pad := Control.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	pad.offset_left = 20 + ins["left"]
	pad.offset_right = pad.offset_left + span
	pad.offset_top = -(span + 16 + ins["bottom"])
	pad.offset_bottom = -16 - ins["bottom"]
	pad.grow_vertical = Control.GROW_DIRECTION_BEGIN
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pad)
	var layout := {"▲": [1, 0, Vector2i.UP], "◀": [0, 1, Vector2i.LEFT], "▶": [2, 1, Vector2i.RIGHT], "▼": [1, 2, Vector2i.DOWN]}
	for glyph in layout:
		var spec: Array = layout[glyph]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 30)
		b.position = Vector2(spec[0] * (PAD_SIZE + gap), spec[1] * (PAD_SIZE + gap))
		b.size = Vector2(PAD_SIZE, PAD_SIZE)
		b.modulate.a = 0.9
		var dir: Vector2i = spec[2]
		var arrow := UIKit.icon("arrow", 58)
		arrow.position = Vector2(15, 15)
		arrow.size = Vector2(58, 58)
		arrow.pivot_offset = Vector2(29, 29)
		arrow.rotation = Vector2.UP.angle_to(Vector2(dir))
		b.add_child(arrow)
		b.button_down.connect(func(): set_pad_dir(dir, true))
		b.button_up.connect(func(): set_pad_dir(dir, false))
		pad.add_child(b)


## Small message strip under the HUD (hint status)
func _build_hint_banner(ins: Dictionary) -> void:
	_hint_banner = PanelContainer.new()
	_hint_banner.anchor_left = 0.5
	_hint_banner.anchor_right = 0.5
	_hint_banner.offset_top = 70 + ins["top"]
	_hint_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	_hint_banner.add_child(margin)
	_hint_label = UIKit.panel_label("", 19, UITheme.TEXT)
	margin.add_child(_hint_label)
	_hint_banner.visible = false
	add_child(_hint_banner)


func _show_banner(text: String, auto_hide := true) -> void:
	_banner_version += 1
	var version := _banner_version
	_hint_label.text = text
	_hint_banner.visible = true
	Juice.pop_in(_hint_banner, 0.0, 0.9)
	if auto_hide:
		await get_tree().create_timer(3.5).timeout
		if version == _banner_version and is_instance_valid(_hint_banner):
			_hint_banner.visible = false


func _hide_banner() -> void:
	_banner_version += 1
	if _hint_banner:
		_hint_banner.visible = false


## "10월 6일 월요일" for the daily puzzle header
func _date_label() -> String:
	var parts := Global.daily_date.split("-")
	if parts.size() != 3:
		return Global.daily_date
	var md := Global.T("date_fmt") % [int(parts[1]), int(parts[2])]
	return "%s %s" % [md, Global.T("weekday_%d" % Levels.daily_band(Global.daily_date))]


func refresh_texts() -> void:
	if mode == "daily":
		_hud_name.text = "%s · %s" % [Global.T("daily"), _date_label()]
	else:
		_hud_name.text = "%s %d. %s" % [Levels.tier_name(tier), level_index + 1, Levels.display_name(tier, level_index)]
	_hint.text = Global.T("hint")
	_update_hint_button()
	_update_stats()
	for e in _pause_texts:
		if is_instance_valid(e[0]):
			e[0].text = Global.T(e[1])


## ---------- level setup ----------
## intro = true on first entry (whole board rises in); restarts only drop the
## moving pieces back in so retrying stays snappy.
func _load_level(intro := false) -> void:
	_level_version += 1
	_expression_version += 1
	Juice.stop(_board_root, "shake_fx")
	_board_root.position = Vector2.ZERO
	Juice.stop(_board_area, "scale_fx")
	_board_area.scale = Vector2.ONE
	board = Board.from_rows(level["rows"], level)
	_update_hint_button()
	_hint_used = false
	_undo_used = false
	_clear_hint()
	_hide_banner()
	for c in _board_root.get_children():
		c.free()
	_box_nodes.clear()
	_static_nodes.clear()
	_goal_tiles.clear()

	# floor + goals. If the artist provided goal_tile.png (a full tile with the
	# marker baked in) use it as the goal cell's floor; otherwise draw floor + goal ring.
	var has_goal_tile := Assets.has_file("goal_tile")
	for cell in board.floors.keys():
		if has_goal_tile and board.goals.has(cell):
			var spot := _sprite("goal_tile", cell)
			_static_nodes.append(spot)
			_goal_tiles[cell] = spot
		else:
			_static_nodes.append(_sprite("floor", cell))
	if not has_goal_tile:
		for cell in board.goals.keys():
			if board.floors.has(cell):
				var ring := _sprite("goal", cell)
				_static_nodes.append(ring)
				_goal_tiles[cell] = ring
	# rule overlays: ice sheets, one-way arrows, color markers on goals
	for cell in board.ice.keys():
		_static_nodes.append(_sprite("ice", cell))
	for cell in board.arrows.keys():
		var arrow := _sprite("oneway", cell)
		arrow.rotation = Vector2.UP.angle_to(Vector2(board.arrows[cell]))
		arrow.set_meta("frac", 0.8)
		arrow.self_modulate = Color(1, 1, 1, 0.9)
		_static_nodes.append(arrow)
	if board.has_rule("color"):
		for cell in board.goals.keys():
			var mark := _sprite("box_c1" if int(board.goals[cell]) == 1 else "box", cell)
			mark.set_meta("frac", 0.5)
			mark.self_modulate = Color(1, 1, 1, 0.8)
			_static_nodes.append(mark)
	# walls: only those touching the interior look nicer, but drawing all is simpler
	for cell in board.walls.keys():
		if _touches_floor(cell):
			_static_nodes.append(_sprite("wall", cell))
	# boxes
	for cell in board.boxes.keys():
		var s := _sprite(_box_tex_name(cell), cell)
		_box_nodes[cell] = s
		Juice.glow(s, board.box_home(cell))
	# player (on top)
	_player = _sprite(_player_tex_name(), board.player)
	_attach_hat()
	_build_path_index()

	_elapsed = 0.0
	_running = false
	_completed = false
	_hold_dir = Vector2i.ZERO
	_pad_dir = Vector2i.ZERO
	_hud_time.text = Global.format_time(0.0)
	_update_stats()
	_layout()
	_play_intro(intro)


## Level entrance. Offsets / alpha only, so it never fights the layout code.
func _play_intro(full: bool) -> void:
	var t0 := 0.0
	if full:
		for s in _static_nodes:
			var c: Vector2i = s.get_meta("cell")
			Juice.rise_in(s, (c.x + c.y) * 0.012)
		t0 = (board.width + board.height) * 0.012 * 0.6
	var keys := _box_nodes.keys()
	keys.sort_custom(func(a, b): return a.x + a.y < b.x + b.y)
	var i := 0
	for cell in keys:
		Juice.drop_in(_box_nodes[cell], t0 + i * 0.04)
		i += 1
	Juice.drop_in(_player, t0 + i * 0.04 + 0.05)


func _touches_floor(cell: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if board.floors.has(cell + Vector2i(dx, dy)):
				return true
	return false


func _sprite(tex_name: String, cell: Vector2i) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Assets.tex(tex_name)
	s.set_meta("cell", cell)
	_board_root.add_child(s)
	return s


func _box_tex_name(cell: Vector2i) -> String:
	var base := "box_on_goal" if board.box_home(cell) else "box"
	return base + "_c1" if int(board.boxes.get(cell, 0)) == 1 else base


## Hat chosen in the wardrobe, worn as a child of the player sprite so it
## follows squash/stretch and fades; its position follows the hop offset.
func _attach_hat() -> void:
	_hat = null
	if Global.hat == "" or not Achievements.hat_unlocked(Global.hat):
		return
	_hat = Sprite2D.new()
	_hat.texture = Assets.tex("hat_" + Global.hat)
	_player.add_child(_hat)
	_update_hat()


func _update_hat() -> void:
	if _hat == null or not is_instance_valid(_player):
		return
	var pw: float = _player.texture.get_width()
	var front := _player.texture == Assets.tex("player_happy") or _player.texture == Assets.tex("player_bump")
	var anchor: Vector2 = HAT_ANCHOR["down" if front else _facing] * (pw / 256.0)
	var hs := pw * 0.46 / _hat.texture.get_width()
	_hat.scale = Vector2.ONE * hs
	# the hat art's bottom edge sits ~36/128 below its centre; sink it a little into the head
	_hat.position = anchor - Vector2(0, _hat.texture.get_height() * 0.28 * hs) + Vector2(0, pw * 0.04) + _player.offset


## Uses directional sprites only when the artist provided them
func _player_tex_name() -> String:
	var tex_name := "player_" + _facing
	return tex_name if Assets.has_file(tex_name) else "player"


## ---------- layout (fit board to available area) ----------
func _layout() -> void:
	if board == null:
		return
	var area := _board_area.size
	var cap := TILE_MAX_TOUCH if Global.is_touch_device() else TILE_MAX
	_tile = min(area.x / board.width, area.y / board.height, cap)
	var board_px := Vector2(board.width, board.height) * _tile
	_origin = (area - board_px) / 2.0
	for s in _static_nodes:
		_place(s, s.get_meta("cell"))
	for cell in _box_nodes.keys():
		_place(_box_nodes[cell], cell)
	_place(_player, board.player)
	if _tutorial_open:
		_tut_show_step()
	if not _hint_last.is_empty():
		_draw_hint(_hint_last)


func _cell_pos(cell: Vector2i) -> Vector2:
	return _origin + Vector2(cell) * _tile + Vector2(_tile, _tile) / 2.0


func _place(s: Sprite2D, cell: Vector2i) -> void:
	s.position = _cell_pos(cell)
	var tex_size: float = s.texture.get_width()
	s.scale = Vector2.ONE * (_tile / tex_size) * float(s.get_meta("frac", 1.0))


## ---------- input ----------
func _process(delta: float) -> void:
	_update_hat()
	_poll_hint()
	if _paused or _completed or _overlay != null or _tutorial_open:
		return
	if _input_lock > 0.0:
		_input_lock -= delta
		_hold_dir = Vector2i.ZERO
		return
	# held D-pad button: first step on press, then repeats
	if _pad_dir != Vector2i.ZERO:
		_pad_repeat -= delta
		if _pad_repeat <= 0.0:
			_pad_repeat = HOLD_REPEAT
			_do_move(_pad_dir)
	var dir := _read_dir()
	if dir == Vector2i.ZERO:
		_hold_dir = Vector2i.ZERO
	elif dir != _hold_dir:
		_hold_dir = dir
		_hold_timer = HOLD_DELAY
		_do_move(dir)
	else:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_hold_timer = HOLD_REPEAT
			_do_move(dir)
	if _running:
		_elapsed += delta
		_hud_time.text = Global.format_time(_elapsed)


## Newly pressed direction wins over a held one, so turning while holding feels instant
func _read_dir() -> Vector2i:
	for action in DIRS:
		if Input.is_action_just_pressed(action):
			return DIRS[action]
	# keep the current hold direction while its key is down, so an older held
	# key does not steal the repeat one frame later
	for action in DIRS:
		if DIRS[action] == _hold_dir and Input.is_action_pressed(action):
			return _hold_dir
	for action in DIRS:
		if Input.is_action_pressed(action):
			return DIRS[action]
	return Vector2i.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null or _completed or _tutorial_open:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_open_pause()
	elif event.is_action_pressed("undo"):
		_do_undo()
	elif event.is_action_pressed("restart"):
		_load_level()
	elif event.is_action_pressed("hint"):
		get_viewport().set_input_as_handled()
		request_hint()


## D-pad buttons call this on press / release
func set_pad_dir(dir: Vector2i, pressed: bool) -> void:
	if pressed:
		if _paused or _completed or _overlay != null or _tutorial_open:
			return
		if dir != _pad_dir:
			_pad_dir = dir
			_pad_repeat = HOLD_DELAY
			if _input_lock <= 0.0:
				_do_move(dir)
	elif _pad_dir == dir:
		_pad_dir = Vector2i.ZERO


## ---------- moves ----------
func _do_move(dir: Vector2i) -> void:
	if _paused or _completed or _overlay != null or _tutorial_open:
		return
	_set_facing(dir)
	var r := board.try_move(dir)
	if not r["moved"]:
		_bump(dir)
		return
	_clear_hint()
	_running = true
	_animate(_player, r["to"])
	_juice_step(dir)
	if r["pushed"]:
		var node: Sprite2D = _box_nodes[r["box_from"]]
		_box_nodes.erase(r["box_from"])
		_box_nodes[r["box_to"]] = node
		node.texture = Assets.tex(_box_tex_name(r["box_to"]))
		var steps: int = 1 + int(r["slid"])
		_animate(node, r["box_to"], steps)
		_juice_push(node, dir, r["box_to"])
		if steps > 1:
			_juice_slide(r["box_from"], r["box_to"], dir)
		if board.box_home(r["box_to"]):
			_juice_goal(node, r["box_to"])
		else:
			Juice.glow(node, false)
	_update_stats()
	if board.is_solved():
		_on_solved()


func _do_undo() -> void:
	if _paused or _completed or _overlay != null or _tutorial_open:
		return
	var r := board.undo()
	if r.is_empty():
		return
	_undo_used = true
	_clear_hint()
	_restore_expression()
	_animate(_player, r["player_to"])
	Juice.flash(_player, UNDO_TINT)
	if r["box_from"] != null:
		var node: Sprite2D = _box_nodes[r["box_from"]]
		_box_nodes.erase(r["box_from"])
		_box_nodes[r["box_to"]] = node
		node.texture = Assets.tex(_box_tex_name(r["box_to"]))
		_animate(node, r["box_to"])
		Juice.flash(node, UNDO_TINT)
		Juice.stop(node, "scale_fx")
		node.scale = _base_scale(node)
		node.set_meta("goal_version", int(node.get_meta("goal_version", 0)) + 1)
		Juice.glow(node, board.box_home(r["box_to"]))
	_update_stats()


func _set_facing(dir: Vector2i) -> void:
	match dir:
		Vector2i.UP: _facing = "up"
		Vector2i.DOWN: _facing = "down"
		Vector2i.LEFT: _facing = "left"
		Vector2i.RIGHT: _facing = "right"
	_restore_expression()


func _restore_expression() -> void:
	_expression_version += 1
	_player.texture = Assets.tex(_player_tex_name())


func _show_bump_expression() -> void:
	_expression_version += 1
	var version := _expression_version
	_player.texture = Assets.tex("player_bump")
	await get_tree().create_timer(0.26).timeout
	if version == _expression_version and is_instance_valid(_player):
		_player.texture = Assets.tex(_player_tex_name())


## ---------- animation ----------
## Tween a sprite to its cell. A previous tween on the same node is cancelled,
## so mashing keys never desyncs the visuals from the board state.
func _animate(node: Sprite2D, cell: Vector2i, steps := 1) -> void:
	_kill_tween(node)
	var target := _cell_pos(cell)
	if not Global.settings["anim"]:
		node.position = target
		return
	var tw := create_tween()
	if steps > 1:   # sliding on ice: longer and gliding
		tw.tween_property(node, "position", target, MOVE_TIME * (1.0 + 0.55 * (steps - 1))) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(node, "position", target, MOVE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	node.set_meta("tween", tw)


## Small nudge when walking into a wall / stuck box
func _bump(dir: Vector2i) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_bump > 0.3:   # holding a key into a wall must not buzz nonstop
		_last_bump = now
		Juice.haptic(12, 0.35)
	if not Global.settings["anim"]:
		return
	_show_bump_expression()
	Juice.squash(_player, _base_scale(_player), dir, -0.1, 0.16)
	_kill_tween(_player)
	var home := _cell_pos(board.player)
	var tw := create_tween()
	tw.tween_property(_player, "position", home + Vector2(dir) * _tile * 0.12, 0.05)
	tw.tween_property(_player, "position", home, 0.07)
	_player.set_meta("tween", tw)


## Rest scale of a board sprite for the current tile size
func _base_scale(s: Sprite2D) -> Vector2:
	return Vector2.ONE * (_tile / s.texture.get_width())


## Every step: small hop + stretch in the walking direction
func _juice_step(dir: Vector2i) -> void:
	Juice.hop(_player, _player.texture.get_height() * 0.07, MOVE_TIME + 0.03)
	Juice.squash(_player, _base_scale(_player), dir, 0.1, 0.18)


## Pushing: the food squashes against the push and kicks up dust behind it
func _juice_push(node: Sprite2D, dir: Vector2i, to: Vector2i) -> void:
	node.set_meta("goal_version", int(node.get_meta("goal_version", 0)) + 1)
	Juice.squash(node, _base_scale(node), dir, -0.12, 0.22)
	var behind := _cell_pos(to) - Vector2(dir) * _tile * 0.45 + Vector2(0, _tile * 0.22)
	Juice.burst(_board_root, behind, {
		"amount": 7, "life": 0.35, "dir": -Vector2(dir), "spread": 70.0,
		"speed": _tile * 1.6, "gravity": _tile * 2.0, "damping": _tile * 2.0,
		"size": _tile / 64.0 * 0.3, "texture": "dust"})
	Juice.haptic(10, 0.3)


## Sliding on ice: a frosty trail along the way
func _juice_slide(from: Vector2i, to: Vector2i, dir: Vector2i) -> void:
	var cell := from + dir
	var i := 0
	while cell != to + dir and i < 32:
		Juice.burst_later(_board_root, _cell_pos(cell) + Vector2(0, _tile * 0.25), {
			"amount": 4, "life": 0.35, "dir": -Vector2(dir), "spread": 50.0,
			"speed": _tile * 0.8, "damping": _tile, "size": _tile / 64.0 * 0.22,
			"texture": "sparkle", "colors": [Color(0.8, 0.95, 1.0)]}, i * MOVE_TIME * 0.55)
		cell += dir
		i += 1
	Juice.haptic(18, 0.4)


## Food lands on a pantry spot: pop, shimmer, sparkles, spot flash, HUD punch
func _juice_goal(node: Sprite2D, cell: Vector2i) -> void:
	Juice.pop(node, _base_scale(node), 1.2, MOVE_TIME)
	Juice.glow(node, true)
	Juice.burst_later(_board_root, _cell_pos(cell), {
		"amount": 10, "life": 0.5, "dir": Vector2.UP, "spread": 150.0,
		"speed": _tile * 1.8, "gravity": _tile * 2.0, "damping": _tile,
		"size": _tile / 64.0 * 0.3, "texture": "sparkle",
		"source": weakref(node), "version": node.get_meta("goal_version", 0)}, MOVE_TIME)
	if _goal_tiles.has(cell):
		Juice.flash(_goal_tiles[cell], Color(1.6, 1.45, 1.1), 0.4)
	Juice.punch(_hud_stats, 1.12)
	Juice.haptic(25, 0.6)


## Stage cleared: everyone hops in a wave, the board punches, confetti flies
func _celebrate() -> void:
	_expression_version += 1
	_player.texture = Assets.tex("player_happy")
	Juice.haptic(70, 0.8)
	var keys := _box_nodes.keys()
	keys.sort_custom(func(a, b): return a.x + a.y < b.x + b.y)
	var i := 0
	for cell in keys:
		var s: Sprite2D = _box_nodes[cell]
		Juice.hop(s, s.texture.get_height() * 0.3, 0.32, 0.12 + i * 0.07)
		i += 1
	Juice.hop(_player, _player.texture.get_height() * 0.35, 0.36, 0.12 + i * 0.07)
	Juice.punch(_board_area, 1.035, 0.35)
	var board_px := Vector2(board.width, board.height) * _tile
	var top_mid := _board_area.position + _origin + Vector2(board_px.x * 0.5, board_px.y * 0.35)
	Juice.burst(self, top_mid, {
		"amount": 40, "life": 1.8, "dir": Vector2.UP, "spread": 65.0,
		"speed": 580.0, "gravity": 650.0, "damping": 60.0, "spin": 180.0,
		"size": 0.5, "texture": "leaf", "explosiveness": 0.95,
		"rect": Vector2(board_px.x * 0.3, 4), "z": 0})


func _kill_tween(node: Node) -> void:
	if node.has_meta("tween"):
		var tw: Tween = node.get_meta("tween")
		if tw and tw.is_valid():
			tw.kill()


## ---------- HUD ----------
func _update_stats() -> void:
	if board == null:
		return
	_hud_stats.text = "%s %d   %s %d   %d/%d" % [
		Global.T("moves"), board.moves, Global.T("pushes"), board.pushes,
		board.boxes_on_goals(), board.boxes.size()]


## ---------- level complete ----------
func _on_solved() -> void:
	_completed = true
	_pad_dir = Vector2i.ZERO
	_hold_dir = Vector2i.ZERO
	var version := _level_version
	_running = false
	_clear_hint()
	var stars := Global.stars_from_moves(board.moves, int(level.get("par", 0)))
	if _hint_used:
		stars = min(stars, 2)
	var flags := {"hint": _hint_used, "undo": _undo_used}
	var is_new: bool
	if mode == "daily":
		is_new = Global.record_daily(Global.daily_date, _elapsed, board.moves, board.pushes, stars, flags)
	else:
		is_new = Global.record_result(tier, level_index, _elapsed, board.moves, board.pushes, stars, flags)
	Achievements.evaluate()
	_celebrate()
	# give the celebration a moment before the result panel covers the board
	await get_tree().create_timer(0.9 if Juice.enabled() else 0.45).timeout
	# a restart or scene change during the delay cancels the panel
	if version != _level_version or not _completed or _overlay != null or not is_inside_tree():
		return
	_open_complete(stars, is_new)


func _open_complete(stars: int, is_new: bool) -> void:
	var box := _open_overlay()
	var daily := mode == "daily"
	var is_last := daily or level_index >= Levels.count(tier) - 1
	if daily:
		box.add_child(UIKit.panel_title(Global.T("daily_clear"), 40))
		box.add_child(UIKit.panel_label(_date_label(), 22, UITheme.TEXT_DIM))
	else:
		box.add_child(UIKit.panel_title(Global.T("all_clear") if is_last else Global.T("clear"), 44))
		box.add_child(UIKit.panel_label(Levels.display_name(tier, level_index), 22, UITheme.TEXT_DIM))
	var star_row := UIKit.hbox(4)
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(star_row)
	for k in 3:
		var earned := k < stars
		var st := UIKit.icon("star_on" if earned else "star_off", 72)
		star_row.add_child(st)
		Juice.pop_in(st, 0.22 + k * 0.16, 0.1)
	if is_new:
		var rec := UIKit.panel_label(Global.T("new_record"), 20, UITheme.ACCENT)
		box.add_child(rec)
		Juice.pop_in(rec, 0.75, 1.6)
	if _hint_used:
		box.add_child(UIKit.panel_label(Global.T("hint_used"), 17, UITheme.TEXT_DIM))
	if daily:
		var streak := UIKit.panel_label(Global.T("daily_streak") % Global.daily_streak(), 24, UITheme.ACCENT)
		box.add_child(streak)
		Juice.pop_in(streak, 0.9, 1.5)
		box.add_child(UIKit.panel_label(Global.T("daily_come_back"), 18, UITheme.TEXT_DIM))
	elif is_last:
		box.add_child(UIKit.panel_label(Global.T("all_clear_desc"), 20, UITheme.TEXT_DIM))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	_stat_row(grid, Global.T("time"), Global.format_time(_elapsed))
	_stat_row(grid, Global.T("moves"), "%d  (%s %d)" % [board.moves, Global.T("par"), int(level.get("par", 0))])
	_stat_row(grid, Global.T("pushes"), str(board.pushes))
	box.add_child(grid)
	box.add_child(UIKit.spacer(8))

	var first: Button = null
	if not is_last:
		first = UIKit.button(Global.T("next"))
		first.pressed.connect(func(): _goto_level(level_index + 1))
		box.add_child(first)
	var retry := UIKit.button(Global.T("retry"))
	retry.pressed.connect(func(): _close_overlay(); _load_level())
	box.add_child(retry)
	if first == null:
		first = retry
	if daily:
		var menu := UIKit.button(Global.T("main_menu"))
		menu.pressed.connect(func(): Transition.go("res://scenes/MainMenu.tscn"))
		box.add_child(menu)
	else:
		var select := UIKit.button(Global.T("stage_select"))
		select.pressed.connect(func(): Transition.go("res://scenes/StageSelect.tscn"))
		box.add_child(select)
	UIKit.trap_focus_in(box)
	first.grab_focus()


func _stat_row(grid: GridContainer, key: String, value: String) -> void:
	grid.add_child(UIKit.panel_label(key, 20, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(UIKit.panel_label(value, 20, UITheme.TEXT, HORIZONTAL_ALIGNMENT_RIGHT))


func _goto_level(i: int) -> void:
	if Transition.is_busy():
		return
	Global.current_level = i
	Global.save()
	Transition.go("res://scenes/Game.tscn")


## ---------- pause ----------
func _open_pause() -> void:
	if _overlay != null or _completed or _tutorial_open:
		return
	_clear_hint()
	var box := _open_overlay()
	_paused = true   # after _open_overlay(): closing a previous overlay resets it
	_pause_texts.clear()
	var title := UIKit.panel_title(Global.T("paused"), 40)
	var hint_key := "hint_touch" if Global.is_touch_device() else "hint"
	var hint := UIKit.panel_label(Global.T(hint_key), 16, UITheme.TEXT_DIM)
	box.add_child(title)
	box.add_child(hint)
	box.add_child(UIKit.spacer(8))
	var resume := UIKit.button(Global.T("resume"))
	resume.pressed.connect(_close_overlay)
	box.add_child(resume)
	var restart := UIKit.button(Global.T("restart"))
	restart.pressed.connect(func(): _close_overlay(); _load_level())
	box.add_child(restart)
	var settings := UIKit.button(Global.T("settings"))
	settings.pressed.connect(func():
		var p := SettingsPanel.new()
		_overlay.add_child(p)
		p.closed.connect(func():
			if is_instance_valid(settings):
				settings.grab_focus()))
	box.add_child(settings)
	var select := UIKit.button(Global.T("stage_select"))
	select.pressed.connect(func(): Transition.go("res://scenes/StageSelect.tscn"))
	if mode != "daily":
		box.add_child(select)
	else:
		select.queue_free()   # the daily puzzle has no stage list
	var menu := UIKit.button(Global.T("main_menu"))
	menu.pressed.connect(func(): Transition.go("res://scenes/MainMenu.tscn"))
	box.add_child(menu)
	_pause_texts = [[title, "paused"], [hint, hint_key], [resume, "resume"], [restart, "restart"],
		[settings, "settings"], [select, "stage_select"], [menu, "main_menu"]]
	UIKit.trap_focus_in(box)
	resume.grab_focus()


## Tutorial card closes on any key or click; pause overlay swallows ESC so it can close
func _input(event: InputEvent) -> void:
	if _tutorial_open:
		# modifier keys and mouse-wheel notches must not advance the steps
		var k := event as InputEventKey
		var key_down: bool = k != null and k.pressed and not k.echo \
			and not (k.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META])
		var mb := event as InputEventMouseButton
		var click: bool = mb != null and mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
		if click and _tut_panel != null and _tut_panel.get_global_rect().has_point(mb.position):
			return   # let the Skip button (or the box itself) take the tap
		var pad: bool = event is InputEventJoypadButton and event.is_pressed()
		if key_down or click or pad:
			get_viewport().set_input_as_handled()
			if event.is_action_pressed("pause"):
				dismiss_tutorial()
			else:
				_tut_next()
		return
	if _overlay != null and _paused and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		# Only close if no settings panel is on top
		var has_settings := false
		for c in _overlay.get_children():
			if c is SettingsPanel:
				has_settings = true
		if not has_settings:
			get_viewport().set_input_as_handled()
			_close_overlay()


## Steps explaining rules this level uses that the player has not seen yet.
## Marks them seen right away so the explanation appears only once.
func _rule_steps() -> Array:
	var steps: Array = []
	var green: Array = []
	var orange: Array = []
	for c in board.goals.keys():
		(green if int(board.goals[c]) == 1 else orange).append(c)
	for c in board.boxes.keys():
		if int(board.boxes[c]) == 1:
			green.append(c)
	var table := {
		"color": [["rule_color_1", green], ["rule_color_2", orange]],
		"ice": [["rule_ice_1", board.ice.keys()], ["rule_ice_2", []]],
		"oneway": [["rule_oneway_1", board.arrows.keys()], ["rule_oneway_2", []]],
	}
	for rule in ["color", "ice", "oneway"]:
		if board.has_rule(rule) and not Global.seen_rules.has(rule):
			for item in table[rule]:
				steps.append({"key": item[0], "cells": item[1]})
			Global.seen_rules[rule] = true
	if mode == "tier" and Levels.tier_id(tier) == "rule_mix" and not Global.seen_rules.has("mix"):
		steps.append({"key": "rule_mix_1", "cells": []})
		Global.seen_rules["mix"] = true
	if not steps.is_empty():
		Global.save()
	return steps


## ---------- hints ----------
## Lookup table along the level's stored solution: if the player is following
## it (in any walking order), the next push is known instantly.
func _build_path_index() -> void:
	_path_index.clear()
	var sol: String = level.get("solution", "")
	if sol == "":
		return
	var sim := Board.from_rows(level["rows"], level)
	for ch in sol:
		if not Board.LETTER.has(ch):
			break
		var d: Vector2i = Board.LETTER[ch]
		if sim.boxes.has(sim.player + d):
			var key := sim.state_key()
			if not _path_index.has(key):
				_path_index[key] = [sim.player + d, d]
		if not sim.try_move(d)["moved"]:
			break


func request_hint() -> void:
	if _paused or _completed or _overlay != null or _tutorial_open or board.is_solved():
		return
	if not Global.hints_unlocked(_level_key()):
		_open_hint_offer()
		return
	_clear_hint()
	_hint_used = true
	var key := board.state_key()
	if _path_index.has(key):
		_on_hint_result({"status": "ok", "box": _path_index[key][0], "dir": _path_index[key][1]}, _hint_version)
		return
	_show_banner(Global.T("hint_thinking"), false)
	if _hint_task >= 0:
		_hint_pending = true    # start as soon as the outdated search finishes
		return
	var snap := board.snapshot()
	var box := {"version": _hint_version}
	_hint_box = box
	_hint_task = WorkerThreadPool.add_task(func(): box["result"] = Solver.first_push(snap))


func _poll_hint() -> void:
	if _hint_task < 0 or not WorkerThreadPool.is_task_completed(_hint_task):
		return
	WorkerThreadPool.wait_for_task_completion(_hint_task)
	_hint_task = -1
	if _hint_pending:
		_hint_pending = false
		request_hint()
		return
	if _hint_box.has("result"):
		_on_hint_result(_hint_box["result"], int(_hint_box["version"]))


func _on_hint_result(r: Dictionary, version: int) -> void:
	if version != _hint_version or _completed:
		return     # the board changed while the solver was thinking
	match str(r.get("status", "")):
		"ok":
			_hint_last = r
			_draw_hint(r)
			_show_banner(Global.T("hint_ok"))
			Juice.haptic(15, 0.4)
		"dead":
			_show_banner(Global.T("hint_dead"))
			for node in _box_nodes.values():
				Juice.flash(node, Color(1.5, 0.75, 0.7), 0.5)
		"limit":
			_show_banner(Global.T("hint_limit"))
		_:
			_hide_banner()


## Progress key of the stage being played (daily puzzles use their date)
func _level_key() -> String:
	return "daily/" + Global.daily_date if mode == "daily" else Global.level_key(tier, level_index)


## Phones: the first hint on a stage costs a hint pass or a rewarded ad (Ads.gd).
## After that the stage keeps hints for good.
func _open_hint_offer() -> void:
	Global.refill_hint_passes()
	_clear_hint()
	var box := _open_overlay()
	box.custom_minimum_size.x = 500
	_paused = true   # ESC / Android back close it like the pause menu
	box.add_child(UIKit.panel_title(Global.T("hint_offer_title"), 34))
	for k in ["hint_offer_desc", "hint_offer_stars"]:
		var line := UIKit.panel_label(Global.T(k), 18, UITheme.TEXT_DIM)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(line)
	box.add_child(UIKit.spacer(6))
	var focus: Button = null
	if Global.hint_passes > 0:
		var use := UIKit.button(Global.T("hint_use_pass") % Global.hint_passes)
		use.pressed.connect(func(): _unlock_hints(true))
		box.add_child(use)
		focus = use
	var ad := UIKit.button("")
	box.add_child(ad)
	var sync := func(_ready_now: bool):
		if is_instance_valid(ad) and ad.text != Global.T("ad_playing"):
			ad.disabled = not Ads.is_ready()
			ad.text = Global.T("hint_watch_ad") if Ads.is_ready() else Global.T("hint_ad_loading")
	sync.call(false)
	Ads.ready_changed.connect(sync)
	ad.tree_exiting.connect(func(): Ads.ready_changed.disconnect(sync))
	ad.pressed.connect(func():
		ad.disabled = true
		ad.text = Global.T("ad_playing")
		Ads.show_rewarded(_on_hint_ad_done))
	var cancel := UIKit.button(Global.T("cancel"))
	cancel.pressed.connect(_close_overlay)
	box.add_child(cancel)
	var note := UIKit.panel_label(Global.T("hint_free_note") % Global.FREE_HINT_PASSES, 15, UITheme.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	if focus == null:
		focus = ad if not ad.disabled else cancel
	focus.grab_focus()


func _on_hint_ad_done(rewarded: bool) -> void:
	if not is_inside_tree() or _completed:
		return
	if rewarded:
		_unlock_hints(false)
	else:
		_close_overlay()
		_show_banner(Global.T("hint_ad_failed"))


func _unlock_hints(spend_pass: bool) -> void:
	Global.unlock_hints(_level_key(), spend_pass)
	_close_overlay()
	_update_hint_button()
	request_hint()


## Touch bar label: "Hint (3)" while this stage still needs a pass or an ad
func _update_hint_button() -> void:
	if _hint_btn == null or board == null:
		return
	if Global.hints_unlocked(_level_key()):
		_hint_btn.text = Global.T("hint_btn")
	else:
		_hint_btn.text = Global.T("hint_btn_count") % Global.hint_passes


## Dotted walk to the pushing spot, a ring on the food and an arrow for the push
func _draw_hint(r: Dictionary) -> void:
	for n in _hint_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_hint_nodes.clear()
	var b: Vector2i = r["box"]
	var d: Vector2i = r["dir"]
	var stand := b - d
	if stand != board.player:
		for cell in board.walk_path(stand):
			var dot := Sprite2D.new()
			dot.texture = Assets.art("fx", "sparkle")
			dot.position = _cell_pos(cell)
			dot.scale = Vector2.ONE * (_tile * 0.32 / dot.texture.get_width())
			dot.modulate = Color(1, 1, 1, 0.85)
			dot.z_index = 2
			_board_root.add_child(dot)
			_hint_nodes.append(dot)
	var ring := Sprite2D.new()
	ring.texture = Assets.tex("goal")
	ring.position = _cell_pos(b)
	ring.scale = Vector2.ONE * (_tile * 1.25 / ring.texture.get_width())
	ring.z_index = 2
	_board_root.add_child(ring)
	_hint_nodes.append(ring)
	var arrow := Sprite2D.new()
	arrow.texture = Assets.tex("oneway")
	arrow.position = _cell_pos(b) + Vector2(d) * _tile * 0.62
	arrow.rotation = Vector2.UP.angle_to(Vector2(d))
	arrow.scale = Vector2.ONE * (_tile * 0.6 / arrow.texture.get_width())
	arrow.z_index = 3
	_board_root.add_child(arrow)
	_hint_nodes.append(arrow)
	if Juice.enabled():
		for node in [ring, arrow]:
			var tw: Tween = node.create_tween().set_loops()
			tw.tween_property(node, "modulate:a", 0.45, 0.45).set_trans(Tween.TRANS_SINE)
			tw.tween_property(node, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)


func _clear_hint() -> void:
	_hint_version += 1
	_hint_pending = false
	_hint_last = {}
	for n in _hint_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_hint_nodes.clear()
	# a still-running search is now outdated; its result is ignored when it lands
	if _hint_label and _hint_label.text == Global.T("hint_thinking"):
		_hide_banner()


## ---------- tutorial (stage 1) ----------
## Step-by-step overlay: a short message at the bottom plus pulsing highlights
## on the relevant cells. Any key / click advances, ESC skips.
func _open_tutorial(steps := []) -> void:
	_tutorial_open = true
	_tut_steps = steps if not steps.is_empty() else [
		{"key": "tut_1", "cells": [board.player]},
		{"key": "tut_2", "cells": board.boxes.keys()},
		{"key": "tut_3", "cells": board.goals.keys()},
		{"key": "tut_4", "cells": []},
		{"key": "tut_5", "cells": []},
		{"key": "tut_6", "cells": board.goals.keys()},
	]
	_tut_index = 0
	_tut_layer = Control.new()
	_tut_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tut_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := UIKit.dim(0.3)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_layer.add_child(dim)

	# message box, bottom centre, above the controls hint
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_bottom = -60
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := UIKit.vbox(8)
	margin.add_child(box)
	_tut_text = UIKit.panel_label("", 22, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_tut_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_text.custom_minimum_size.x = 640
	box.add_child(_tut_text)
	_tut_counter = UIKit.panel_label("", 16, UITheme.ACCENT)
	box.add_child(_tut_counter)
	if Global.is_touch_device():
		var skip := UIKit.button(Global.T("skip"), 160)
		skip.focus_mode = Control.FOCUS_NONE
		skip.pressed.connect(dismiss_tutorial)
		var row := UIKit.hbox()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(skip)
		box.add_child(row)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP   # taps on the box hit the button, not "next"
	_tut_panel = panel
	_tut_layer.add_child(panel)
	add_child(_tut_layer)
	_tut_show_step()


func _tut_show_step() -> void:
	if _tut_layer == null:
		return
	for m in _tut_marks:
		m.queue_free()
	_tut_marks.clear()
	var step: Dictionary = _tut_steps[_tut_index]
	var key: String = step["key"]
	if Global.is_touch_device() and Global.STRINGS["en"].has(key + "_touch"):
		key += "_touch"
	_tut_text.text = Global.T(key)
	var counter_key := "tut_next_touch" if Global.is_touch_device() else "tut_next"
	_tut_counter.text = Global.T(counter_key) % [_tut_index + 1, _tut_steps.size()]
	for cell in step["cells"]:
		_tut_marks.append(_make_highlight(cell))
	_tut_place_panel(step["cells"])


## Put the message at the top when the highlighted cells sit in the lower half
## of the board, so the box never covers what it is talking about.
func _tut_place_panel(cells: Array) -> void:
	var panel: Control = _tut_text.get_parent().get_parent().get_parent()
	var lower_half := false
	if not cells.is_empty():
		var sum_y := 0.0
		for c in cells:
			sum_y += c.y
		lower_half = sum_y / cells.size() >= board.height / 2.0
	if lower_half:
		panel.anchor_top = 0.0
		panel.anchor_bottom = 0.0
		panel.offset_top = 84
		panel.offset_bottom = 84
		panel.grow_vertical = Control.GROW_DIRECTION_END
	else:
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_top = -60
		panel.offset_bottom = -60
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN


## Amber outline over one board cell, pulsing so it catches the eye
func _make_highlight(cell: Vector2i) -> Panel:
	var mark := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(UITheme.ACCENT, 0.15)
	style.border_color = UITheme.ACCENT
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	mark.add_theme_stylebox_override("panel", style)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = Vector2(_tile, _tile)
	mark.position = _board_area.position + _cell_pos(cell) - Vector2(_tile, _tile) / 2.0
	_tut_layer.add_child(mark)
	var tw := mark.create_tween().set_loops()
	if not Juice.enabled():
		tw.kill()
		return mark
	tw.tween_property(mark, "modulate:a", 0.35, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mark, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	return mark


func _tut_next() -> void:
	_tut_index += 1
	if _tut_index >= _tut_steps.size():
		dismiss_tutorial()
	else:
		_tut_show_step()


## Public so DevTools can start auto-play without the overlay in the way
func dismiss_tutorial() -> void:
	if not _tutorial_open:
		return
	_tutorial_open = false
	if _tut_layer:
		_tut_layer.queue_free()
		_tut_layer = null
	_tut_panel = null
	_tut_marks.clear()
	_input_lock = 0.25   # the key that closed the overlay must not move the player


## Android back button (project setting quit_on_go_back is off)
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _tutorial_open:
		dismiss_tutorial()
	elif _overlay != null:
		for c in _overlay.get_children():
			if c is SettingsPanel:
				c._close()
				return
		if _paused:
			_close_overlay()
	elif not _completed:
		_open_pause()


## ---------- overlay helpers ----------
## Creates dim + centered panel and returns the VBox to fill
func _open_overlay() -> VBoxContainer:
	_close_overlay()   # never leak a previous panel
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(UIKit.dim())
	var cp := UIKit.center_panel()
	_overlay.add_child(cp[0])
	var box := UIKit.vbox(10)
	box.custom_minimum_size.x = 360
	cp[1].add_child(box)
	add_child(_overlay)
	Juice.pop_panel(_overlay, cp[0].get_child(0))
	return box


func _close_overlay() -> void:
	_pad_dir = Vector2i.ZERO
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_pause_texts.clear()
	_paused = false
	_hold_dir = Vector2i.ZERO
	if board != null and not Juice.enabled():
		# Settings can turn effects off while a looping goal shimmer is alive.
		for node in _board_root.get_children():
			if node is CPUParticles2D:
				node.queue_free()
			elif node is Sprite2D:
				for key in ["scale_fx", "hop_fx", "flash_fx", "glow_fx"]:
					Juice.stop(node, key)
				node.offset = Vector2.ZERO
				node.modulate = Color.WHITE
				node.self_modulate = Color.WHITE
		_layout()
