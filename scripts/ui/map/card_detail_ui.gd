class_name CardDetailUI
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_intro() -> void:
	var overlay := Control.new()
	overlay.name = "IntroOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.add_child(overlay)
	var bg := TextureRect.new()
	bg.name = "IntroBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var img := Image.new()
	if img.load("res://assets/sprites/splash/intro_bg.jpg") == OK:
		bg.texture = ImageTexture.create_from_image(img)
	overlay.add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 60
	scroll.offset_top = 40
	scroll.offset_right = -60
	scroll.offset_bottom = -40
	scroll.z_index = 501
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(0, 0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(vbox)
	var title := Label.new()
	title.text = Localization.t("intro.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title)
	var subtitle := Label.new()
	subtitle.text = Localization.t("intro.subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 38)
	subtitle.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	vbox.add_child(subtitle)
	var sp1 := Control.new()
	sp1.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(sp1)
	var intro := Label.new()
	intro.text = Localization.t("intro.text")
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(0, 0)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.add_theme_font_size_override("font_size", 30)
	intro.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(intro)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp2)
	var hint := Label.new()
	hint.text = Localization.t("intro.click")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(hint)
	overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			overlay.queue_free()
			GameManager.set_intro_shown()
	)

func show_card_detail(card_data: Dictionary) -> void:
	var card_detail_preview: Control = _map.card_detail_preview
	var card_detail_popup: Control = _map.card_detail_popup
	for child in card_detail_preview.get_children():
		child.queue_free()
	var script := load("res://scripts/ui/card_widget.gd")
	var card := Control.new()
	card.set_script(script)
	card.name = "DetailCard"
	card.size = Vector2(280, 420)
	card.custom_minimum_size = Vector2(280, 420)
	card_detail_preview.add_child(card)
	card.setup(card_data)
	card_detail_preview.pivot_offset = Vector2(280.0, 420.0) * 0.5
	card_detail_preview.scale = Vector2.ZERO
	card_detail_popup.visible = true
	var tween := _map.create_tween()
	tween.tween_property(card_detail_preview, "scale", Vector2(3.5, 3.5), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func show_auto_card_popup(card_data: Dictionary) -> void:
	var popup := Control.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -200
	popup.offset_top = -300
	popup.offset_right = 200
	popup.offset_bottom = 300
	popup.z_index = 200
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(popup)
	var card := Control.new()
	card.set_script(load("res://scripts/ui/card_widget.gd"))
	card.name = "AutoCard"
	card.size = Vector2(400, 600)
	card.custom_minimum_size = Vector2(400, 600)
	popup.add_child(card)
	card.setup(card_data)
	popup.pivot_offset = Vector2(400.0, 600.0) * 0.5
	popup.scale = Vector2(0.1, 0.1)
	var tween := _map.create_tween()
	tween.tween_property(popup, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.8)
	tween.tween_property(popup, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(popup.queue_free)
	_map._lm("Auto-played: %s" % Localization.get_card_name(card_data))

func add_active_effect(card_data: Dictionary) -> void:
	_map._active_effects.append(card_data)
	var effects_grid: GridContainer = _map.effects_grid
	if not effects_grid:
		return
	var wrapper := PanelContainer.new()
	wrapper.name = "Eff_" + card_data.get("id", "")
	wrapper.custom_minimum_size = Vector2(120, 170)
	var ps := StyleBoxFlat.new()
	ps.set_corner_radius_all(6)
	ps.bg_color = Color(0.06, 0.05, 0.03, 0.9)
	ps.border_color = Color(1.0, 0.85, 0.2)
	ps.set_border_width_all(2)
	wrapper.add_theme_stylebox_override("panel", ps)
	effects_grid.add_child(wrapper)
	var card := Control.new()
	card.set_script(load("res://scripts/ui/card_widget.gd"))
	card.name = "EffCard"
	card.custom_minimum_size = Vector2(116, 166)
	card.size = Vector2(116, 166)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(card)
	card.setup(card_data)
	var click_layer := Button.new()
	click_layer.name = "ClickLayer"
	click_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_layer.flat = true
	click_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	click_layer.pressed.connect(_map._on_effect_card_click.bind(card_data))
	wrapper.add_child(click_layer)

func load_card_portrait(card_data: Dictionary) -> Texture2D:
	var card_id: String = card_data.get("id", "")
	var card_type: String = card_data.get("type", "unit")
	var sub_map := {"unit": "units", "situation": "situations", "commander": "commanders", "spell": "spells"}
	var sub: String = sub_map.get(card_type, "units")
	for ext in [".png", ".jpg"]:
		var path: String = "res://assets/sprites/cards/%s/%s%s" % [sub, card_id, ext]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is Texture2D:
				return res as Texture2D
		if FileAccess.file_exists(path):
			var img := Image.new()
			if img.load(path) == OK:
				return ImageTexture.create_from_image(img)
	return null

func show_deploy_feedback(t_id: String, card_name: String) -> void:
	var _territory_buttons: Dictionary = _map._territory_buttons
	if not _territory_buttons.has(t_id):
		return
	var btn: Button = _territory_buttons[t_id]
	var pos := btn.global_position + btn.size * 0.5
	var lbl := Label.new()
	lbl.text = ">> %s" % card_name.left(18)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = pos - Vector2(120, 60)
	lbl.z_index = 300
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map.add_child(lbl)
	var tween := _map.create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", pos.y - 140.0, 2.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)
	var flash := StyleBoxFlat.new()
	flash.set_corner_radius_all(8)
	flash.set_border_width_all(5)
	flash.bg_color = Color(1.0, 1.0, 0.2, 0.95)
	flash.border_color = Color(1.0, 1.0, 0.5)
	flash.shadow_color = Color(1.0, 0.95, 0.3, 0.8)
	flash.shadow_size = 10
	btn.add_theme_stylebox_override("normal", flash)
	var ft := _map.create_tween()
	ft.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	ft.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	ft.tween_callback(func() -> void:
		_map._territory_mgr.update_territory_button_style(t_id, "player"))
