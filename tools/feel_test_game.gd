## Exercise real move/render methods without writing completion records.
extends "res://scripts/Game.gd"

func _on_solved() -> void:
	_completed = true
	_running = false
	_pad_dir = Vector2i.ZERO
	_celebrate()
