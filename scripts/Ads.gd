## Ads.gd — rewarded ads that unlock hints on phones (autoload).
##
## PC / Steam: no ads at all and hints stay free (enabled() == false).
## Android:    AdMobBackend asks for consent (UMP) if needed, starts the SDK and
##             keeps one rewarded ad loaded; show_rewarded() plays it.
## Debug:      `-- --fakeads` turns the hint passes + ads on for PC testing with a
##             fake 3-second ad; `--fakeads=fail` behaves as if no ad can load.
##
## Release checklist: put the rewarded ad unit from the AdMob console into
## REWARDED_UNIT. Until then (and in every debug build) Google's test unit is
## used, which shows "Test Ad" banners and earns nothing.
extends Node

signal ready_changed(is_ready: bool)

const TEST_REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"
const REWARDED_UNIT := ""
const FAKE_AD_SECONDS := 3.0

var _backend: RefCounted = null     # AdMobBackend, Android only
var _fake := ""                     # "", "ok" or "fail"
var _showing := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--fakeads":
			_fake = "ok"
		elif a.begins_with("--fakeads="):
			_fake = a.substr(10)
	if _fake == "" and OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob"):
		# loaded by path so desktop builds never touch the plugin classes
		_backend = load("res://scripts/AdMobBackend.gd").new()
		_backend.ready_changed.connect(func(r: bool): ready_changed.emit(r))
		_backend.start(unit_id())


## True when hints cost a pass or an ad (phones, or the --fakeads test mode)
func enabled() -> bool:
	return _fake != "" or _backend != null


func unit_id() -> String:
	if OS.is_debug_build() or REWARDED_UNIT == "":
		return TEST_REWARDED_UNIT
	return REWARDED_UNIT


## An ad is loaded and can be shown right now
func is_ready() -> bool:
	if _showing:
		return false
	if _fake != "":
		return _fake == "ok"
	return _backend != null and _backend.is_ready()


## Plays a rewarded ad; `done(rewarded: bool)` runs once it is closed.
func show_rewarded(done: Callable) -> void:
	if not is_ready():
		done.call(false)
		return
	_showing = true
	var finish := func(rewarded: bool):
		_showing = false
		if done.is_valid():     # the scene that asked may be gone by now
			done.call(rewarded)
	if _fake != "":
		_show_fake(finish)
	else:
		_backend.show(finish)


## Consent: true when the user must be able to reopen the privacy form (EEA etc.)
func privacy_options_required() -> bool:
	return _backend != null and _backend.privacy_options_required()


func show_privacy_options() -> void:
	if _backend != null:
		_backend.show_privacy_options()


## Stand-in ad for PC tests: dark screen with a countdown, then the reward
func _show_fake(finish: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	layer.add_child(label)
	var left := FAKE_AD_SECONDS
	while left > 0.0:
		label.text = Global.T("ad_test") % ceili(left)
		await get_tree().create_timer(0.5).timeout
		left -= 0.5
	layer.queue_free()
	finish.call(true)
