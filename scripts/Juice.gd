## Juice.gd — reusable "game feel" effects: squash & stretch, hops, shakes,
## flashes, particles, UI pops and haptics.
##
## Every visual effect is skipped when the "anim" setting is off, so players who
## prefer a calm screen get one. Haptics follow the separate "vibrate" setting.
##
## Tweens are stored in node metadata under a key per property group
## ("scale_fx", "hop_fx", "flash_fx", ...). Starting a new effect kills the
## previous one in the same group, so rapid input never stacks effects.
class_name Juice

static var _dot: Texture2D = null
static var _chip: Texture2D = null


static func enabled() -> bool:
	return bool(Global.settings.get("anim", true))


static func stop(node: Node, key: String) -> void:
	if node.has_meta(key):
		var old = node.get_meta(key)
		if old is Tween and old.is_valid():
			old.kill()
		node.remove_meta(key)


## New tween for `node`, killing the one previously stored under `key`
static func _fresh(node: Node, key: String) -> Tween:
	if node.has_meta(key):
		var old = node.get_meta(key)
		if old is Tween and old.is_valid():
			old.kill()
	var tw := node.create_tween()
	node.set_meta(key, tw)
	return tw


## ---------------------------------------------------------------- sprites
## Stretch along `dir` (amount > 0) or squash against it (amount < 0), then
## spring back to `base`.
static func squash(s: Node2D, base: Vector2, dir: Vector2i, amount := 0.12, time := 0.18) -> void:
	if not enabled():
		return
	var k := Vector2(1.0 + amount, 1.0 - amount * 0.7)
	if dir.y != 0:
		k = Vector2(1.0 - amount * 0.7, 1.0 + amount)
	s.scale = base * k
	var tw := _fresh(s, "scale_fx")
	tw.tween_property(s, "scale", base, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Grow to `peak` and settle back (food landing on a pantry spot)
static func pop(s: Node2D, base: Vector2, peak := 1.2, delay := 0.0) -> void:
	if not enabled():
		return
	var tw := _fresh(s, "scale_fx")
	tw.tween_property(s, "scale", base * peak, 0.08).set_delay(delay)
	tw.tween_property(s, "scale", base, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Little jump using the sprite offset (never fights position tweens)
static func hop(s: Sprite2D, height: float, time: float, delay := 0.0) -> void:
	if not enabled():
		return
	var tw := _fresh(s, "hop_fx")
	tw.tween_property(s, "offset:y", -height, time * 0.5).set_delay(delay) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "offset:y", 0.0, time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## Board tiles rising into place at level start
static func rise_in(s: Sprite2D, delay: float) -> void:
	if not enabled():
		return
	s.modulate.a = 0.0
	s.offset.y = s.texture.get_height() * 0.25
	var fade := _fresh(s, "flash_fx")
	fade.tween_property(s, "modulate:a", 1.0, 0.16).set_delay(delay)
	var rise := _fresh(s, "hop_fx")
	rise.tween_property(s, "offset:y", 0.0, 0.3).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Food / capybara dropping onto the board with a bounce
static func drop_in(s: Sprite2D, delay: float) -> void:
	if not enabled():
		return
	s.modulate.a = 0.0
	s.offset.y = -s.texture.get_height() * 0.9
	var fade := _fresh(s, "flash_fx")
	fade.tween_property(s, "modulate:a", 1.0, 0.1).set_delay(delay)
	var drop := _fresh(s, "hop_fx")
	drop.tween_property(s, "offset:y", 0.0, 0.34).set_delay(delay) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Tint quickly and fade back to normal (colors > 1 brighten)
static func flash(c: CanvasItem, color: Color, time := 0.22) -> void:
	if not enabled():
		return
	var tw := _fresh(c, "flash_fx")
	c.modulate = color
	tw.tween_property(c, "modulate", Color.WHITE, time)


## Soft looping shimmer for food that sits on its spot (uses self_modulate so
## it never fights flash())
static func glow(c: CanvasItem, on: bool) -> void:
	if c.has_meta("glow_fx"):
		var old = c.get_meta("glow_fx")
		if old is Tween and old.is_valid():
			old.kill()
		c.remove_meta("glow_fx")
	c.self_modulate = Color.WHITE
	if not on or not enabled():
		return
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "self_modulate", Color(1.16, 1.1, 0.98), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "self_modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	c.set_meta("glow_fx", tw)


## Decaying random jitter of a Node2D around (0, 0)
static func shake(n: Node2D, strength: float, time := 0.18) -> void:
	if not enabled():
		return
	var tw := _fresh(n, "shake_fx")
	var steps := 6
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * falloff
		tw.tween_property(n, "position", off, time / (steps + 1))
	tw.tween_property(n, "position", Vector2.ZERO, time / (steps + 1))


## ---------------------------------------------------------------- controls
## Quick scale punch around the centre of a Control
static func punch(c: Control, peak := 1.08, time := 0.24) -> void:
	if not enabled():
		return
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2.ONE * peak
	var tw := _fresh(c, "scale_fx")
	tw.tween_property(c, "scale", Vector2.ONE, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Fade + scale in from `from` (waits one frame so the size / pivot is known)
static func pop_in(c: Control, delay := 0.0, from := 0.3) -> void:
	if not enabled() or not c.is_inside_tree():
		return
	c.modulate.a = 0.0
	await c.get_tree().process_frame
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2.ONE * max(from, 0.01)
	var tw := _fresh(c, "scale_fx")
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.14).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.34).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Overlay entrance: dim fades in, panel pops
static func pop_panel(overlay: CanvasItem, panel: Control) -> void:
	if not enabled():
		return
	overlay.modulate.a = 0.0
	var tw := _fresh(overlay, "flash_fx")
	tw.tween_property(overlay, "modulate:a", 1.0, 0.14)
	pop_in(panel, 0.0, 0.86)


## Staggered fade for lists of cards
static func fade_in(c: CanvasItem, delay: float, time := 0.18) -> void:
	if not enabled():
		return
	c.modulate.a = 0.0
	var tw := _fresh(c, "flash_fx")
	tw.tween_property(c, "modulate:a", 1.0, time).set_delay(delay)


## Slow looping scale "breath" (title logo)
static func breathe(c: Control, amount := 0.025, period := 2.6) -> void:
	if not enabled():
		return
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween().set_loops()
	tw.tween_property(c, "scale", Vector2.ONE * (1.0 + amount), period / 2.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, period / 2.0).set_trans(Tween.TRANS_SINE)


## Fixed button geometry: brightness feedback never moves a hit area or label.
static func attach_button(b: BaseButton) -> void:
	if b.has_meta("juiced"):
		return
	b.set_meta("juiced", true)
	b.mouse_entered.connect(func(): _button_to(b, 1.05))
	b.focus_entered.connect(func(): _button_to(b, 1.05))
	b.mouse_exited.connect(func(): _button_to(b, 1.05 if b.has_focus() else 1.0))
	b.focus_exited.connect(func(): _button_to(b, 1.0))
	b.button_down.connect(func(): _button_to(b, 0.92, 0.06))
	b.button_up.connect(func(): _button_to(b, 1.05 if (b.is_hovered() or b.has_focus()) else 1.0, 0.2))


static func _button_to(b: BaseButton, target: float, time := 0.12) -> void:
	if not is_instance_valid(b):
		return
	stop(b, "scale_fx")
	b.scale = Vector2.ONE
	b.z_index = 0
	if not b is CheckButton and not b is CheckBox:
		if b.has_focus() and not b.disabled:
			b.add_theme_stylebox_override("normal", UITheme.focused_button())
		else:
			b.remove_theme_stylebox_override("normal")
	if not enabled() or b.disabled:
		stop(b, "button_tint_fx")
		b.self_modulate = Color.WHITE
		return
	var tw := _fresh(b, "button_tint_fx")
	tw.tween_property(b, "self_modulate", Color(target, target, target), time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## ---------------------------------------------------------------- particles
## One-shot particle burst. Options (all optional):
##   amount, life, dir (Vector2), spread (deg), speed, gravity, damping,
##   size (texture scale), colors (Array[Color]), rect (Vector2 half-extents),
##   spin (deg/s), chips (bool: rectangular confetti instead of soft dots), z
static func burst(parent: Node, pos: Vector2, o: Dictionary) -> void:
	if not enabled() or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.texture = Assets.art("fx", o["texture"]) if o.has("texture") else (_chip_tex() if o.get("chips", false) else _dot_tex())
	p.one_shot = true
	p.explosiveness = o.get("explosiveness", 0.9)
	p.amount = o.get("amount", 12)
	p.lifetime = o.get("life", 0.5)
	p.direction = o.get("dir", Vector2.UP)
	p.spread = o.get("spread", 180.0)
	var speed: float = o.get("speed", 120.0)
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, o.get("gravity", 0.0))
	p.damping_min = o.get("damping", 0.0)
	p.damping_max = o.get("damping", 0.0)
	var size: float = o.get("size", 1.0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	p.scale_amount_curve = shrink
	var spin: float = o.get("spin", 0.0)
	p.angular_velocity_min = -spin
	p.angular_velocity_max = spin
	p.angle_min = 0.0
	p.angle_max = 360.0 if spin > 0.0 else 0.0
	var colors: Array = o.get("colors", [Color.WHITE])
	var pick := Gradient.new()
	pick.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	pick.offsets = PackedFloat32Array()
	pick.colors = PackedColorArray()
	for i in colors.size():
		pick.add_point(float(i) / colors.size(), colors[i])
	p.color_initial_ramp = pick
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	if o.has("rect"):
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = o["rect"]
	p.position = pos
	p.z_index = o.get("z", 5)
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## burst() after a delay (e.g. when a pushed box actually arrives)
static func burst_later(parent: Node, pos: Vector2, o: Dictionary, delay: float) -> void:
	if not enabled() or not is_instance_valid(parent):
		return
	await parent.get_tree().create_timer(delay).timeout
	if o.has("source"):
		var source: Node = o["source"].get_ref()
		if not is_instance_valid(source) or source.get_meta("goal_version", -1) != o.get("version", -2):
			return
	if is_instance_valid(parent) and parent.is_inside_tree():
		burst(parent, pos, o)


static func _dot_tex() -> Texture2D:
	if _dot == null:
		var n := 16
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0).length() / (n / 2.0)
				img.set_pixel(x, y, Color(1, 1, 1, clamp((1.0 - d) * 2.0, 0.0, 1.0)))
		_dot = ImageTexture.create_from_image(img)
	return _dot


static func _chip_tex() -> Texture2D:
	if _chip == null:
		var img := Image.create(12, 7, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_chip = ImageTexture.create_from_image(img)
	return _chip


## ---------------------------------------------------------------- haptics
## Phone vibration (Android) and gamepad rumble, both behind the "vibrate" setting
static func haptic(ms: int, strength := 0.5) -> void:
	if not bool(Global.settings.get("vibrate", true)):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms, strength)
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, strength * 0.6, strength, ms / 1000.0)
