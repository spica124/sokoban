## UIKit.gd — small helpers so screens can build UI in code without repetition.
class_name UIKit


static func button(text: String, min_width := 280) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 60)
	return b


static func label(text: String, size := 22, color := UITheme.TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func title(text: String, size := 48) -> Label:
	return label(text, size, UITheme.ACCENT)


static func panel_label(text: String, size := 22, color := UITheme.TEXT, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	return label(text, size, UITheme.panel_ink(color), align)


static func panel_title(text: String, size := 48) -> Label:
	return panel_label(text, size, UITheme.ACCENT)


static func vbox(separation := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func spacer(height := 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


static func icon(tex_name: String, pixels := 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Assets.art("ui", tex_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(pixels, pixels)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func stars(n: int, pixels := 24) -> HBoxContainer:
	var row := hbox(2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var st := icon("star_on" if i < n else "star_off", pixels)
		if i >= n:
			# empty slots must look empty at card size (the cream star_off reads as "earned")
			st.modulate = Color(0.55, 0.45, 0.35, 0.55)
		row.add_child(st)
	return row


## Decorative children of a button must never intercept its touch or hover.
static func ignore_mouse(root: Control) -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		if child is Control:
			ignore_mouse(child)


## Full-screen dark overlay that also swallows clicks (for pause/dialogs)
static func dim(alpha := 0.55) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## Returns [center_container, margin]. Add children to the margin.
static func center_panel(padding := 32) -> Array:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding)
	panel.add_child(margin)
	center.add_child(panel)
	return [center, margin]


## Background: bg.png if the artist provided one, else flat color
static func background(shade := 0.0) -> Control:
	if Assets.has_file("bg"):
		var t := TextureRect.new()
		t.texture = Assets.tex("bg")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if shade > 0.0:
			var veil := dim(shade)
			veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.add_child(veil)
		return t
	var r := ColorRect.new()
	r.color = UITheme.BG
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Keep keyboard/gamepad focus inside an overlay: every focusable control under
## `root` gets next/previous and up/down neighbours that cycle within the group,
## so arrows can never wander to buttons hidden behind the dim.
static func trap_focus_in(root: Control) -> void:
	var items: Array = []
	_collect_focusable(root, items)
	var n := items.size()
	if n == 0:
		return
	for i in n:
		var c: Control = items[i]
		var prev: Control = items[(i - 1 + n) % n]
		var next: Control = items[(i + 1) % n]
		c.focus_previous = prev.get_path()
		c.focus_next = next.get_path()
		c.focus_neighbor_top = prev.get_path()
		c.focus_neighbor_bottom = next.get_path()
		c.focus_neighbor_left = prev.get_path()
		c.focus_neighbor_right = next.get_path()


static func _collect_focusable(node: Node, out: Array) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE and node.is_visible_in_tree():
		out.append(node)
	for child in node.get_children():
		_collect_focusable(child, out)


## "★★☆" style string
static func stars_text(n: int) -> String:
	var s := ""
	for i in 3:
		s += "★" if i < n else "☆"
	return s
