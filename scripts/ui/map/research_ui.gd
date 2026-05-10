class_name ResearchUI
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_research_popup() -> void:
	var research_grid: GridContainer = _map.research_grid
	var research_current_label: Label = _map.research_current_label
	var research_popup: Control = _map.research_popup
	for child in research_grid.get_children():
		child.queue_free()
	var cur: Dictionary = ResearchSystem.get_current()
	if not cur.is_empty():
		research_current_label.text = "Текущее: %s (осталось %d ходов)" % [cur.get("name_ru", ""), ResearchSystem.get_turns_left()]
	else:
		research_current_label.text = "Нищие учёные ждут указаний!"
	var available: Array = ResearchSystem.get_available()
	if available.is_empty():
		research_current_label.text = "Все изобретения изучены!"
		research_popup.visible = true
		return
	for inv in available:
		_add_invention_card(inv)
	research_popup.visible = true

func _add_invention_card(inv: Dictionary) -> void:
	var research_grid: GridContainer = _map.research_grid
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 340)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.bg_color = Color(0.06, 0.05, 0.03, 0.95)
	style.border_color = Color(0.4, 0.7, 1.0)
	style.set_border_width_all(3)
	style.shadow_color = Color(0.3, 0.5, 0.8, 0.3)
	style.shadow_size = 6
	card.add_theme_stylebox_override("panel", style)
	research_grid.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	var tex: Texture2D = _load_invention_portrait(inv.get("id", ""))
	if tex:
		var img_rect := TextureRect.new()
		img_rect.texture = tex
		img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img_rect.custom_minimum_size = Vector2(240, 160)
		img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(img_rect)
	var name_lbl := Label.new()
	name_lbl.text = inv.get("name_ru", "")
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = inv.get("description_ru", "")
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	var turns_lbl := Label.new()
	turns_lbl.text = "Срок: %d ходов" % inv.get("turns_to_research", 4)
	turns_lbl.add_theme_font_size_override("font_size", 18)
	turns_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	turns_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	turns_lbl.add_theme_constant_override("outline_size", 3)
	turns_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(turns_lbl)
	var btn := Button.new()
	btn.text = "ИССЛЕДОВАТЬ"
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(0, 50)
	btn.pressed.connect(_on_research_pick.bind(inv.get("id", "")))
	vbox.add_child(btn)

func _load_invention_portrait(inv_id: String) -> Texture2D:
	for ext in [".png", ".jpg"]:
		var path: String = "res://assets/sprites/cards/situations/%s%s" % [inv_id, ext]
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is Texture2D:
				return res as Texture2D
		if FileAccess.file_exists(path):
			var img := Image.new()
			if img.load(path) == OK:
				return ImageTexture.create_from_image(img)
	return null

func _on_research_pick(inv_id: String) -> void:
	if ResearchSystem.start_research(inv_id):
		var inv: Dictionary = ResearchSystem.get_current()
		_map._lm("Research started: %s" % inv.get("name_ru", ""))
		_map.research_popup.visible = false
		_map._update_resources()
	else:
		_map._lm("Research failed: cannot afford or already researching")

func show_research_result_popup(inv: Dictionary) -> void:
	if inv.is_empty():
		return
	var popup := PanelContainer.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -300
	popup.offset_top = -150
	popup.offset_right = 300
	popup.offset_bottom = 150
	popup.z_index = 250
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(12)
	style.bg_color = Color(0.03, 0.08, 0.03, 0.95)
	style.border_color = Color(0.2, 1.0, 0.3)
	style.set_border_width_all(4)
	style.shadow_color = Color(0.2, 0.9, 0.3, 0.5)
	style.shadow_size = 12
	popup.add_theme_stylebox_override("panel", style)
	_map.add_child(popup)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	popup.add_child(vbox)
	var lbl_title := Label.new()
	lbl_title.text = "ИЗОБРЕТЕНИЕ ЗАВЕРШЕНО!"
	lbl_title.add_theme_font_size_override("font_size", 36)
	lbl_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	lbl_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl_title.add_theme_constant_override("outline_size", 5)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)
	var lbl_name := Label.new()
	lbl_name.text = inv.get("name_ru", "")
	lbl_name.add_theme_font_size_override("font_size", 40)
	lbl_name.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl_name.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl_name.add_theme_constant_override("outline_size", 5)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_name)
	var lbl_desc := Label.new()
	lbl_desc.text = inv.get("description_ru", "")
	lbl_desc.add_theme_font_size_override("font_size", 28)
	lbl_desc.add_theme_color_override("font_color", Color(0.85, 0.9, 0.75))
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_desc)
	var tween := _map.create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 2.5).set_ease(Tween.EASE_IN).set_delay(2.0)
	tween.tween_callback(popup.queue_free)

func show_periodic_popup(inv: Dictionary) -> void:
	if inv.is_empty():
		return
	var popup := PanelContainer.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.offset_left = -300
	popup.offset_top = -100
	popup.offset_right = 300
	popup.offset_bottom = 100
	popup.z_index = 250
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(12)
	style.bg_color = Color(0.05, 0.12, 0.05, 0.95)
	style.border_color = Color(0.3, 1.0, 0.4)
	style.set_border_width_all(3)
	style.shadow_color = Color(0.2, 0.8, 0.3, 0.4)
	style.shadow_size = 8
	popup.add_theme_stylebox_override("panel", style)
	_map.add_child(popup)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	popup.add_child(vbox)
	var lbl := Label.new()
	lbl.text = "%s: сработало!" % inv.get("name_ru", "")
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	var desc := Label.new()
	desc.text = inv.get("description_ru", "")
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.8, 0.9, 0.75))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	var tween := _map.create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 2.0).set_ease(Tween.EASE_IN).set_delay(1.5)
	tween.tween_callback(popup.queue_free)
