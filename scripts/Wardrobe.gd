## Wardrobe.gd — pick the capybara's hat. Hats unlock with stars and achievements
## (Achievements.HATS); the choice is saved in Global.hat and worn in game.
extends Control

const PREVIEW := 300.0
const HAT_ANCHOR_DOWN := Vector2(0, -66)   # same as Game.HAT_ANCHOR["down"]

var _content: Control


func _ready() -> void:
	add_to_group("localized")
	add_child(UIKit.background(0.3))
	_build()


func refresh_texts() -> void:
	_build()


func _build() -> void:
	if _content:
		_content.queue_free()
	_content = MarginContainer.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ins := Global.safe_insets()
	for side in ["left", "right", "top", "bottom"]:
		_content.add_theme_constant_override("margin_" + side, 24 + int(ins[side]))
	add_child(_content)
	var col := UIKit.vbox(14)
	_content.add_child(col)

	var header := UIKit.hbox(20)
	var back := UIKit.button(Global.T("back"), 140)
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title := UIKit.title(Global.T("wardrobe"), 36)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var stars := UIKit.hbox(6)
	stars.add_child(UIKit.icon("star_on", 30))
	stars.add_child(UIKit.label(str(Achievements.stats()["stars"]), 22, UITheme.ACCENT))
	stars.custom_minimum_size.x = 140
	header.add_child(stars)
	col.add_child(header)
	col.add_child(UIKit.label(Global.T("wardrobe_desc"), 18, UITheme.TEXT_DIM))

	var body := UIKit.hbox(40)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)
	body.add_child(_preview())

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var grid_box := CenterContainer.new()
	grid_box.add_child(grid)
	body.add_child(grid_box)
	var focus: Button = null
	var ids: Array = [""]
	for h in Achievements.HATS:
		ids.append(h[0])
	for i in ids.size():
		var card := _card(ids[i])
		grid.add_child(card)
		Juice.fade_in(card, i * 0.03)
		if ids[i] == Global.hat:
			focus = card
	await get_tree().process_frame
	if is_instance_valid(focus):
		focus.grab_focus()


## Big capybara with the current hat
func _preview() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(PREVIEW, PREVIEW)
	var capy := TextureRect.new()
	capy.texture = Assets.tex("player_down")
	capy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	capy.size = Vector2(PREVIEW, PREVIEW)
	holder.add_child(capy)
	if Global.hat != "" and Achievements.hat_unlocked(Global.hat):
		var hat := TextureRect.new()
		hat.texture = Assets.tex("hat_" + Global.hat)
		hat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var k := PREVIEW / 256.0
		var hw := PREVIEW * 0.46
		hat.size = Vector2(hw, hw)
		# same placement rule as Game._update_hat, converted to preview pixels
		var centre := Vector2(PREVIEW / 2.0, PREVIEW / 2.0) + HAT_ANCHOR_DOWN * k \
			- Vector2(0, hw * 0.28) + Vector2(0, PREVIEW * 0.04)
		hat.position = centre - hat.size / 2.0
		holder.add_child(hat)
		Juice.pop_in(hat, 0.05, 0.6)
	return holder


func _card(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(170, 150)
	var box := UIKit.vbox(2)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(box)
	var unlocked := Achievements.hat_unlocked(id)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, 70)
	pic.texture = Assets.tex("hat_" + id) if id != "" else null
	box.add_child(pic)
	box.add_child(UIKit.label(Achievements.hat_name(id), 17, UITheme.ACCENT if id == Global.hat else UITheme.TEXT))
	var note := ""
	if id == Global.hat:
		note = Global.T("equipped")
	elif not unlocked:
		note = Achievements.hat_requirement(id)
	var sub := UIKit.label(note, 13, UITheme.TEXT_DIM)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 150
	box.add_child(sub)
	if not unlocked:
		b.disabled = true
		pic.modulate = Color(0.2, 0.15, 0.1, 0.6)
	UIKit.ignore_mouse(box)
	b.pressed.connect(func(): _equip(id))
	return b


func _equip(id: String) -> void:
	Global.hat = id
	Global.save()
	Juice.haptic(15, 0.4)
	_build()


func _go_back() -> void:
	Transition.go("res://scenes/MainMenu.tscn")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
