## UITheme.gd — builds the shared UI theme in code (colors, buttons, panels).
## Applied once in Global._ready() via get_window().theme.
##
## Optional artist skin: drop 9-slice PNGs into assets/ui/ (see ASSETS.md):
##   panel.png, button.png, button_hover.png, button_pressed.png, button_disabled.png
## Each is 96x96 with 28 px corners. When a file exists it replaces the flat
## code-drawn box for that element; missing files keep the built-in look.
class_name UITheme

const UI_DIR := "res://assets/ui/"
const UI_CORNER := 28

const BG := Color("27190f")
const PANEL := Color("3b2314")
const PANEL_BORDER := Color("785031")
const BTN := Color("57331e")
const BTN_HOVER := Color("75492b")
const ACCENT := Color("e8c46a")
const TEXT := Color("f6e7c9")
const TEXT_DIM := Color("d7c5a4")
const TEXT_DARK := Color("3b2314")


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 22

	# --- Button ---
	t.set_stylebox("normal", "Button", _button_skin(Color.WHITE, BTN))
	t.set_stylebox("hover", "Button", _button_skin(Color(1.16, 1.12, 1.04), BTN_HOVER))
	t.set_stylebox("pressed", "Button", _button_skin(Color(0.82, 0.82, 0.82), BTN))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", _button_skin(Color(0.64, 0.68, 0.73), Color("40382e")))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("c7baa1"))

	# --- Panel / PanelContainer ---
	var panel := _box(PANEL, 16, PANEL_BORDER, 1)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 12
	var panel_style: StyleBox = _skin("panel", panel)
	t.set_stylebox("panel", "Panel", panel_style)
	t.set_stylebox("panel", "PanelContainer", panel_style)

	# --- Label ---
	t.set_color("font_color", "Label", TEXT)

	# --- CheckButton / OptionButton reuse button colors ---
	# CheckButton text sits directly on the cream panel, without a wood face.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var check_style := StyleBoxEmpty.new()
		check_style.content_margin_left = 12
		check_style.content_margin_right = 12
		check_style.content_margin_top = 6
		check_style.content_margin_bottom = 6
		t.set_stylebox(state, "CheckButton", check_style)
	t.set_color("font_color", "CheckButton", panel_ink(TEXT))
	t.set_color("font_hover_color", "CheckButton", panel_ink(ACCENT))
	t.set_color("font_hover_pressed_color", "CheckButton", panel_ink(ACCENT))
	t.set_color("font_pressed_color", "CheckButton", panel_ink(TEXT))
	t.set_color("font_focus_color", "CheckButton", panel_ink(TEXT))
	t.set_stylebox("focus", "CheckButton", _box(Color.TRANSPARENT, 8, panel_ink(ACCENT), 2))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "OptionButton", t.get_stylebox(state, "Button"))
	t.set_color("font_color", "OptionButton", TEXT)

	# --- PopupMenu (dropdown of OptionButton) ---
	t.set_stylebox("panel", "PopupMenu", _box(PANEL, 8, PANEL_BORDER, 1))
	t.set_stylebox("hover", "PopupMenu", _box(BTN_HOVER, 6))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)

	# --- ScrollContainer ---
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return t


## All interaction states share one silhouette and the same nine-slice margins.
## Independently painted state images have slightly different rims/shadows.
static func _button_skin(tint: Color, fallback: Color) -> StyleBox:
	var style := _skin("button", _box(fallback, 10))
	if style is StyleBoxTexture:
		style.modulate_color = tint
	return style


## Focus uses the normal button background, behind labels/icons, not an overlay.
static func focused_button() -> StyleBox:
	return _button_skin(Color(1.28, 1.19, 1.03), BTN_HOVER)


## The supplied panel has a cream face; labels on dark scenes keep light ink.
static func panel_ink(color: Color) -> Color:
	if _load_ui("panel") == null:
		return color
	if color == ACCENT:
		return Color("704017")
	if color == TEXT_DIM:
		return Color("765536")
	return TEXT_DARK


## 9-slice texture style when assets/ui/<name>.png exists, else the fallback
static func _skin(name: String, fallback: StyleBox) -> StyleBox:
	var tex := _load_ui(name)
	if tex == null:
		return fallback
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.texture_margin_left = UI_CORNER
	s.texture_margin_right = UI_CORNER
	s.texture_margin_top = UI_CORNER
	s.texture_margin_bottom = UI_CORNER
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func _load_ui(name: String) -> Texture2D:
	var path := UI_DIR + name + ".png"
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			return ImageTexture.create_from_image(img)
	return null


static func _box(bg: Color, radius: int, border := Color.TRANSPARENT, border_w := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(border_w)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
