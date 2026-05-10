class_name ChoicePopups
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_religion_choice() -> void:
	var overlay := ColorRect.new()
	overlay.name = "ReligionChoice"
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.add_child(overlay)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250
	vbox.offset_top = -200
	vbox.offset_right = 250
	vbox.offset_bottom = 200
	vbox.z_index = 501
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vbox)
	var title := Label.new()
	title.text = "ВЫБЕРИТЕ ВЕРОВАНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)
	var choices := [
		{"id": "mnogobomzhie", "name": "Многобомжие", "desc": "Верования в древних бомжей-покровителей. Бог свалки, бог вокзала, бог картона, бог полторашки."},
		{"id": "trezvost", "name": "Трезвость", "desc": "Путь воздержания. +производительность, -алкогольные карты."}
	]
	for choice in choices:
		var btn := Button.new()
		btn.text = choice["name"]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 26)
		var desc := Label.new()
		desc.text = choice["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(480, 0)
		desc.add_theme_font_size_override("font_size", 20)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		desc.add_theme_constant_override("outline_size", 2)
		var cid: String = choice["id"]
		btn.pressed.connect(func():
			GameManager.set_religion_chosen(true)
			ReligionSystem.set_religion(cid)
			_map._lm("Religion chosen: %s" % cid)
			overlay.queue_free()
			_map._update_all_ui()
			if not GameManager.is_ideology_chosen() and GameManager.get_player_territory_count() >= 5:
				show_ideology_choice()
			else:
				GameManager.advance_phase()
		)
		vbox.add_child(btn)
		vbox.add_child(desc)

func show_ideology_choice() -> void:
	var overlay := ColorRect.new()
	overlay.name = "IdeologyChoice"
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.add_child(overlay)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -250
	vbox.offset_top = -200
	vbox.offset_right = 250
	vbox.offset_bottom = 200
	vbox.z_index = 501
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vbox)
	var title := Label.new()
	title.text = "ВЫБЕРИТЕ СТРОЙ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 3)
	vbox.add_child(title)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)
	var choices := [
		{"id": "alcoholism", "name": "Алкоголизм", "desc": "Тоталитарный строй. 0 налогов. Водка правит. +1 карта отряда при доборе."},
		{"id": "dermocracy", "name": "Дерьмократия", "desc": "Свободный рынок мусора. +25% к мелочишке. Торговля краденым."}
	]
	for choice in choices:
		var btn := Button.new()
		btn.text = choice["name"]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 26)
		var desc := Label.new()
		desc.text = choice["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(480, 0)
		desc.add_theme_font_size_override("font_size", 20)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		desc.add_theme_constant_override("outline_size", 2)
		var cid: String = choice["id"]
		btn.pressed.connect(func():
			GameManager.choose_ideology(cid)
			_map._lm("Ideology chosen: %s" % cid)
			overlay.queue_free()
			_map._update_all_ui()
			GameManager.advance_phase()
		)
		vbox.add_child(btn)
		vbox.add_child(desc)
