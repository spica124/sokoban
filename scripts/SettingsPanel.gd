## SettingsPanel.gd — overlay with all options. Add as a child of any screen:
##   var p := SettingsPanel.new(); add_child(p); p.closed.connect(...)
## Screens in group "localized" get refresh_texts() called when language changes.
class_name SettingsPanel
extends Control

signal closed

var _confirm: Control = null
var _first_focus: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## Builds (or rebuilds, after a language change) the panel contents in place,
## so the node identity and any external `closed` connections survive.
func _build() -> void:
	_first_focus = null
	add_child(UIKit.dim())
	var cp := UIKit.center_panel()
	add_child(cp[0])
	Juice.pop_in(cp[0].get_child(0), 0.0, 0.88)
	var box := UIKit.vbox(14)
	box.custom_minimum_size.x = 460
	cp[1].add_child(box)

	box.add_child(UIKit.panel_title(Global.T("settings"), 36))
	box.add_child(UIKit.spacer(8))

	# Fullscreen / VSync mean nothing on phones; the window is always fullscreen there
	if not Global.is_touch_device():
		var fs := _check(Global.T("fullscreen"), Global.settings["fullscreen"],
			func(v): Global.set_setting("fullscreen", v))
		box.add_child(fs)
		_first_focus = fs
		box.add_child(_check(Global.T("vsync"), Global.settings["vsync"],
			func(v): Global.set_setting("vsync", v)))
	var anim := _check(Global.T("animation"), Global.settings["anim"],
		func(v): Global.set_setting("anim", v))
	box.add_child(anim)
	if _first_focus == null:
		_first_focus = anim
	# phones vibrate; on desktop this drives gamepad rumble, so show it when a pad is connected
	if Global.is_touch_device() or not Input.get_connected_joypads().is_empty():
		box.add_child(_check(Global.T("vibration"), Global.settings["vibrate"], _on_vibrate_toggled))
	box.add_child(_language_row())
	box.add_child(UIKit.spacer(8))

	var reset := UIKit.button(Global.T("reset_progress"))
	reset.pressed.connect(_ask_reset)
	box.add_child(reset)
	# Google's consent rules: users who answered the consent form must be able to reopen it
	if Ads.privacy_options_required():
		var privacy := UIKit.button(Global.T("privacy_options"))
		privacy.pressed.connect(Ads.show_privacy_options)
		box.add_child(privacy)

	var back := UIKit.button(Global.T("back"))
	back.pressed.connect(_close)
	box.add_child(back)
	UIKit.trap_focus_in(box)
	_first_focus.grab_focus()


## Buzz once when turned on so the player feels what they enabled
func _on_vibrate_toggled(v: bool) -> void:
	Global.set_setting("vibrate", v)
	if v:
		Juice.haptic(40, 0.6)


func _check(text: String, value: bool, on_toggle: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.custom_minimum_size.y = 48
	c.text = text
	c.button_pressed = value
	c.toggled.connect(on_toggle)
	return c


func _language_row() -> HBoxContainer:
	var row := UIKit.hbox()
	row.add_child(UIKit.panel_label(Global.T("language"), 22, UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var opt := OptionButton.new()
	opt.custom_minimum_size.y = 60
	opt.add_item("한국어")
	opt.add_item("English")
	opt.selected = 0 if Global.settings["lang"] == "ko" else 1
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.item_selected.connect(_on_language_selected)
	row.add_child(opt)
	return row


func _on_language_selected(i: int) -> void:
	Global.set_setting("lang", "ko" if i == 0 else "en")
	get_tree().call_group("localized", "refresh_texts")
	# Rebuild in place so labels update and the caller's `closed` connection stays
	for c in get_children():
		c.queue_free()
	_confirm = null
	_build()


func _ask_reset() -> void:
	if _confirm:
		return
	_confirm = Control.new()
	_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(UIKit.dim(0.5))
	var cp := UIKit.center_panel()
	_confirm.add_child(cp[0])
	var box := UIKit.vbox(16)
	cp[1].add_child(box)
	var msg := UIKit.panel_label(Global.T("reset_confirm"))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.custom_minimum_size.x = 420
	box.add_child(msg)
	var row := UIKit.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var yes := UIKit.button(Global.T("yes"), 160)
	yes.pressed.connect(_do_reset)
	var no := UIKit.button(Global.T("no"), 160)
	no.pressed.connect(_close_confirm)
	row.add_child(yes)
	row.add_child(no)
	box.add_child(row)
	add_child(_confirm)
	UIKit.trap_focus_in(row)
	no.grab_focus()


func _do_reset() -> void:
	Global.reset_progress()
	_close_confirm()
	get_tree().call_group("localized", "refresh_texts")


func _close_confirm() -> void:
	if _confirm:
		_confirm.queue_free()
		_confirm = null
		_first_focus.grab_focus()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _confirm:
			_close_confirm()
		else:
			_close()
