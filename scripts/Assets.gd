## Assets.gd — texture loader with procedural placeholders (autoload "Assets").
##
## Assets.tex("box") looks for res://assets/sprites/box.png. If the file is
## missing, a simple placeholder is drawn in code so the game always runs.
## Drop real PNGs (see ASSETS.md) into assets/sprites/ and they are used
## automatically — no code change needed.
extends Node

const SPRITE_DIR := "res://assets/sprites/"
const SIZE := 64   # placeholder pixel size; real assets can be any size (square)
const HALF := 32   # half of SIZE, written out to avoid integer-division warnings
const QUARTER := 16

var _cache := {}


## Shared loader for UI and particle art, including imported export resources.
## Missing UI icons fall back to a drawn placeholder so new screens never show blanks.
func art(folder: String, tex_name: String) -> Texture2D:
	var path := "res://assets/%s/%s.png" % [folder, tex_name]
	if not _cache.has(path):
		var t := _load_png(path)
		if t == null and folder == "ui":
			t = _ui_placeholder(tex_name)
		_cache[path] = t
	return _cache[path]


func tex(tex_name: String) -> Texture2D:
	if _cache.has(tex_name):
		return _cache[tex_name]
	var t := _load_png(SPRITE_DIR + tex_name + ".png")
	if t == null and tex_name.ends_with("_c1"):
		t = _recolor_green(tex_name.trim_suffix("_c1"))
	if t == null and tex_name.begins_with("hat_"):
		t = _hat(tex_name.trim_prefix("hat_"))
	if t == null and (tex_name == "ice" or tex_name == "oneway"):
		t = _tile_overlay(tex_name)
	if t == null:
		t = _placeholder(tex_name)
	_cache[tex_name] = t
	return t


## True when the artist provided this image. In an exported build the .png
## source is replaced by an imported resource, so FileAccess alone would say
## "missing" — ResourceLoader.exists covers that case.
func has_file(tex_name: String) -> bool:
	var path := SPRITE_DIR + tex_name + ".png"
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## Load through the resource system if imported, otherwise straight from disk
## (covers PNGs added while the editor was closed).
func _load_png(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			return ImageTexture.create_from_image(img)
	return null


## ---------- generated art (replaced by real PNGs when provided) ----------
## Green squash for color-1 food: shift the pumpkin's orange hues to green.
func _recolor_green(base: String) -> Texture2D:
	var src := tex(base)
	if src == null:
		return null
	var img := src.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.02 or c.s < 0.25:
				continue
			if c.h < 0.14 or c.h > 0.95:
				var g := Color.from_hsv(0.27 + (c.h if c.h < 0.5 else 0.0) * 0.2, min(1.0, c.s * 0.85), c.v * 0.72, c.a)
				img.set_pixel(x, y, g)
	return ImageTexture.create_from_image(img)


## Ice: translucent pale-blue sheet with diagonal glints. Arrow: chevron pointing up.
func _tile_overlay(kind: String) -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	if kind == "ice":
		for y in n:
			for x in n:
				var edge: int = min(min(x, y), min(n - 1 - x, n - 1 - y))
				var a := 0.42 if edge > 5 else 0.75
				img.set_pixel(x, y, Color(0.70, 0.88, 1.0, a))
		for k in [-40, 0, 38]:
			for t in range(10, n - 10):
				var x: int = t
				var y: int = n - t + k
				for w in 3:
					if y + w >= 0 and y + w < n:
						img.set_pixel(x, y + w, Color(1, 1, 1, 0.8))
	else:
		var ink := Color(0.98, 0.93, 0.80, 0.95)
		var rim := Color(0.24, 0.14, 0.05, 0.95)
		for pass_ in 2:
			var grow := 7 if pass_ == 0 else 0
			var col := rim if pass_ == 0 else ink
			for y in n:
				for x in n:
					var cx := absf(x - n / 2.0)
					# chevron: two arms meeting at the top
					var arm := absf((y - 30) - cx * 0.95)
					var on := arm < 11 + grow and cx < 40 + grow and y > 22 - grow and y < 82 + grow
					var stem := cx < 8 + grow and y > 48 - grow and y < 104 + grow
					if on or stem:
						img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## Simple hat shapes, drawn around the hat's bottom-centre at (64, 100)
func _hat(id: String) -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var ink := Color(0.16, 0.09, 0.03)
	match id:
		"straw":
			_ell(img, 64, 96, 58, 16, ink); _ell(img, 64, 96, 54, 12, Color("e8c46a"))
			_ell(img, 64, 74, 32, 26, ink); _ell(img, 64, 74, 28, 22, Color("f0d27c"))
			_rect(img, 34, 84, 60, 8, Color("c84a3a"))
		"mandarin":
			_ell(img, 64, 80, 34, 30, ink); _ell(img, 64, 80, 30, 26, Color("f39a2b"))
			_ell(img, 56, 70, 8, 6, Color("ffc06a"))
			_ell(img, 74, 48, 14, 7, ink); _ell(img, 74, 48, 11, 5, Color("6fa05a"))
		"flower":
			_ell(img, 64, 94, 52, 10, ink); _ell(img, 64, 94, 48, 7, Color("6fa05a"))
			for i in 5:
				var fx := 24 + i * 20
				_ell(img, fx, 86, 11, 11, ink)
				_ell(img, fx, 86, 8, 8, [Color("f2a6b8"), Color("ffffff"), Color("f5d76e"), Color("f2a6b8"), Color("c9b6f2")][i])
				_ell(img, fx, 86, 3, 3, Color("f5b84b"))
		"leaf":
			_ell(img, 64, 70, 22, 36, ink); _ell(img, 64, 70, 18, 32, Color("7fb35a"))
			_rect(img, 63, 40, 3, 64, Color("4f7d3a"))
		"chef":
			_rect(img, 34, 76, 60, 24, ink); _rect(img, 37, 79, 54, 18, Color.WHITE)
			for c in [[44, 60], [64, 50], [84, 60], [54, 70], [74, 70]]:
				_ell(img, c[0], c[1], 20, 18, ink)
			for c in [[44, 60], [64, 50], [84, 60], [54, 70], [74, 70]]:
				_ell(img, c[0], c[1], 17, 15, Color.WHITE)
		"beanie":
			_ell(img, 64, 82, 40, 34, ink); _ell(img, 64, 82, 36, 30, Color("c84a3a"))
			_rect(img, 24, 88, 80, 14, ink); _rect(img, 27, 90, 74, 10, Color("f6e7c9"))
			_ell(img, 64, 46, 12, 12, ink); _ell(img, 64, 46, 9, 9, Color("f6e7c9"))
		"grad":
			_rect(img, 40, 72, 48, 26, ink); _rect(img, 43, 75, 42, 20, Color("3b3b48"))
			for y in range(52, 76):
				var half := 46 - absi(y - 64) * 3
				_rect(img, 64 - half, y, half * 2, 1, ink if absi(y - 64) > 9 else Color("2e2e3a"))
			_rect(img, 88, 64, 3, 30, Color("f5b84b")); _ell(img, 89, 96, 5, 5, Color("f5b84b"))
		"crown":
			for x in range(28, 100):
				var tip: int = 48 + absi(((x - 28) % 24) - 12) * 2
				for y in range(tip, 98):
					var border: bool = y < tip + 4 or y > 93 or x < 31 or x > 96
					img.set_pixel(x, y, ink if border else Color("f5c13b"))
			for c in [[40, 82], [64, 82], [88, 82]]:
				_ell(img, c[0], c[1], 6, 6, Color("d9573b"))
		_:
			pass
	return ImageTexture.create_from_image(img)


## Menu / chapter icons that have no artwork yet
func _ui_placeholder(id: String) -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var ink := Color(0.16, 0.09, 0.03)
	match id:
		"rule_color":
			_ell(img, 44, 70, 30, 28, ink); _ell(img, 44, 70, 26, 24, Color("e8983f"))
			_ell(img, 86, 70, 30, 28, ink); _ell(img, 86, 70, 26, 24, Color("5d9a4a"))
		"rule_ice":
			_ell(img, 64, 64, 46, 46, ink); _ell(img, 64, 64, 42, 42, Color(0.72, 0.89, 1.0))
			_rect(img, 40, 50, 40, 6, Color.WHITE); _rect(img, 50, 70, 30, 6, Color.WHITE)
		"rule_oneway", "rule_mix":
			_ell(img, 64, 64, 46, 46, ink); _ell(img, 64, 64, 42, 42, Color("e8c46a"))
			var arrow := _tile_overlay("oneway").get_image()
			arrow.resize(80, 80)
			img.blend_rect(arrow, Rect2i(0, 0, 80, 80), Vector2i(24, 24))
			if id == "rule_mix":
				_ell(img, 96, 96, 18, 18, ink); _ell(img, 96, 96, 15, 15, Color("5d9a4a"))
		"daily":
			_rect(img, 24, 30, 80, 76, ink); _rect(img, 28, 34, 72, 68, Color("f6e7c9"))
			_rect(img, 28, 34, 72, 18, Color("d9573b"))
			_rect(img, 40, 22, 8, 18, ink); _rect(img, 80, 22, 8, 18, ink)
			_ell(img, 64, 78, 14, 14, Color("e8983f"))
		"trophy":
			_ell(img, 64, 50, 34, 30, ink); _ell(img, 64, 50, 30, 26, Color("f5c13b"))
			_rect(img, 58, 70, 12, 22, ink); _rect(img, 40, 92, 48, 12, ink); _rect(img, 43, 95, 42, 6, Color("a86e40"))
		"hint_pass":
			# ticket with a sparkle
			_rect(img, 14, 36, 100, 58, ink); _rect(img, 18, 40, 92, 50, Color("f6e7c9"))
			_ell(img, 14, 65, 9, 9, Color.TRANSPARENT); _ell(img, 114, 65, 9, 9, Color.TRANSPARENT)
			_rect(img, 40, 44, 4, 42, Color("d7c5a4"))
			_ell(img, 76, 65, 16, 16, Color("e8c46a")); _ell(img, 76, 65, 7, 7, Color.WHITE)
		"hanger":
			var h := _hat("straw").get_image()
			img.blend_rect(h, Rect2i(0, 0, 128, 128), Vector2i(0, -6))
		_:
			return null
	return ImageTexture.create_from_image(img)


func _ell(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx := float(x - cx) / rx
			var dy := float(y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c)


## ---------- placeholders ----------
func _placeholder(tex_name: String) -> Texture2D:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	match tex_name:
		"floor":
			img.fill(Color("3a4052"))
			_rect(img, 0, 0, SIZE, 1, Color("2f3443"))
			_rect(img, 0, 0, 1, SIZE, Color("2f3443"))
		"wall":
			img.fill(Color("6b7390"))
			_rect(img, 0, 0, SIZE, 3, Color("8a92b0"))
			_rect(img, 0, SIZE - 4, SIZE, 4, Color("4d5470"))
			_rect(img, 0, HALF - 1, SIZE, 2, Color("4d5470"))
			_rect(img, HALF - 1, 0, 2, HALF, Color("4d5470"))
			_rect(img, QUARTER - 1, HALF, 2, HALF, Color("4d5470"))
			_rect(img, (HALF + QUARTER) - 1, HALF, 2, HALF, Color("4d5470"))
		"goal":
			_ring(img, HALF, HALF, 14, 10, Color("f5b84b"))
		"goal_tile":
			img.fill(Color("3a4052"))
			_ring(img, HALF, HALF, 14, 10, Color("f5b84b"))
		"box":
			_crate(img, Color("b8763a"), Color("7a4a1f"))
		"box_on_goal":
			_crate(img, Color("d9a441"), Color("8c5e10"))
		"player", "player_up", "player_down", "player_left", "player_right":
			_disc(img, HALF, HALF, 24, Color("4fc3f7"))
			_disc(img, HALF, HALF, 20, Color("81d4fa"))
			_disc(img, HALF - 8, HALF - 4, 4, Color("1b1f2a"))
			_disc(img, HALF + 8, HALF - 4, 4, Color("1b1f2a"))
		_:
			img.fill(Color.MAGENTA)
	return ImageTexture.create_from_image(img)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, c)


func _ring(img: Image, cx: int, cy: int, r_out: int, r_in: int, c: Color) -> void:
	for y in range(cy - r_out, cy + r_out + 1):
		for x in range(cx - r_out, cx + r_out + 1):
			var d := (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if d <= r_out * r_out and d >= r_in * r_in:
				img.set_pixel(x, y, c)


func _crate(img: Image, fill: Color, edge: Color) -> void:
	var m := 4
	_rect(img, m, m, SIZE - 2 * m, SIZE - 2 * m, edge)
	_rect(img, m + 4, m + 4, SIZE - 2 * m - 8, SIZE - 2 * m - 8, fill)
	# diagonal cross
	for i in range(m + 4, SIZE - m - 4):
		for t in range(-2, 3):
			var yy := i + t
			if yy >= m + 4 and yy < SIZE - m - 4:
				img.set_pixel(i, yy, edge)
				img.set_pixel(SIZE - 1 - i, yy, edge)
