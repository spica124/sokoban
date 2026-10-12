## Transition.gd — fade-to-black scene changes (autoload "Transition").
## Usage: Transition.go("res://scenes/Game.tscn")
extends CanvasLayer

const FADE := 0.18

var _fade: ColorRect
var _busy := false
var _tw: Tween


func _ready() -> void:
	layer = 100
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


## True while a scene change is in flight. Callers that mutate state before
## calling go() (e.g. picking a level) should bail out when this is true.
func is_busy() -> bool:
	return _busy


func go(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP   # block clicks during fade
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_fade, "modulate:a", 1.0, FADE)
	await _tw.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	# The new scene is live: accept requests again while fading back in
	_busy = false
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tw = create_tween()
	_tw.tween_property(_fade, "modulate:a", 0.0, FADE)
