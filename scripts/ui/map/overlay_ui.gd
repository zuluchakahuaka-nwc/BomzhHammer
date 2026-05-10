class_name OverlayUI
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_territory_overlay(t_id: String) -> void:
	var data: Dictionary = CardDatabase.get_territory(t_id)
	if data.is_empty():
		return
	var terr_overlay: Control = _map.terr_overlay
	var terr_overlay_name: Label = _map.terr_overlay_name
	var terr_overlay_details: Label = _map.terr_overlay_details
	var terr_overlay_img: TextureRect = _map.terr_overlay_img
	var terr_overlay_units: HBoxContainer = _map.terr_overlay_units
	terr_overlay_name.text = data.get("name_ru", t_id)
	var owner: String = GameManager.get_territory_owner(t_id)
	var tn := {"dump":"Свалка","station":"Вокзал","square_three_stations":"Пл.3 вокзалов",
		"den":"Притон","supermarket_dumpster":"Мусорка","pharmacy_dumpster":"Аптека-мусорка",
		"dacha":"Дачи","obrygalovka":"Обрыгаловка","kutuzka":"Кутузка","open_street":"Улица"}
	var details: String = "Тип: %s | Владелец: %s" % [tn.get(data.get("terrain",""),"?"),
		"ВЫ" if owner=="player" else "ВРАГ" if owner=="enemy" else "Нейтральная"]
	details += " | Бутылки:%d Мелочишка:%d Водка:%d" % [data.get("resource_bottles",0),data.get("resource_coins",0),data.get("resource_rolltons",0)]
	terr_overlay_details.text = details
	var img_path: String = "res://assets/sprites/map/territories/%s.jpg" % t_id
	if ResourceLoader.exists(img_path):
		terr_overlay_img.texture = load(img_path)
		terr_overlay_img.visible = true
	else:
		terr_overlay_img.visible = false
	for child in terr_overlay_units.get_children():
		child.queue_free()
	var p_count: int = 0
	if _map._player_deployed.has(t_id):
		for u in _map._player_deployed[t_id]:
			if u.is_alive():
				p_count += 1
		Logger.info("GameMap", "Overlay %s: %d alive player units" % [t_id, p_count])
		_add_overlay_units(terr_overlay_units, _map._player_deployed[t_id], Color(1,1,0.3), false)
	if _map._npc_garrisons.has(t_id):
		_add_overlay_units(terr_overlay_units, _map._npc_garrisons[t_id], Color(0.2,1.0,0.3), true)
	terr_overlay.visible = true

func _add_overlay_units(container: HBoxContainer, units: Array, accent: Color, is_enemy: bool) -> void:
	var label_text: String = "ВРАГИ:" if is_enemy else "ВАШИ:"
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", accent)
	container.add_child(lbl)
	for u in units:
		if not u.is_alive():
			continue
		var card := Panel.new()
		card.custom_minimum_size = Vector2(280, 380)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.bg_color = Color(0.04, 0.04, 0.04)
		style.border_color = accent
		style.set_border_width_all(4)
		card.add_theme_stylebox_override("panel", style)
		container.add_child(card)
		var portrait: TextureRect = _load_unit_portrait(u)
		if portrait:
			portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
			portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			portrait.z_index = 0
			card.add_child(portrait)
		var grad := ColorRect.new()
		grad.set_anchors_preset(Control.PRESET_FULL_RECT)
		grad.color = Color(0, 0, 0, 0.55)
		grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grad.z_index = 1
		card.add_child(grad)
		var vbox := VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 2)
		vbox.alignment = BoxContainer.ALIGNMENT_END
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.z_index = 2
		card.add_child(vbox)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(spacer)
		var n := Label.new()
		n.text = u.get_name()
		n.add_theme_font_size_override("font_size", 22)
		n.add_theme_color_override("font_color", Color(0, 0, 0))
		n.add_theme_color_override("font_outline_color", Color(1, 1, 1))
		n.add_theme_constant_override("outline_size", 5)
		vbox.add_child(n)
		var s := Label.new()
		s.text = "ATK:%d DEF:%d HP:%d" % [u.attack, u.defense, u.current_hp]
		s.add_theme_font_size_override("font_size", 16)
		s.add_theme_color_override("font_color", accent)
		s.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		s.add_theme_constant_override("outline_size", 3)
		vbox.add_child(s)
		var mv := Label.new()
		mv.text = "MOV:%d NAG:%d" % [u.movement, u.naglost]
		mv.add_theme_font_size_override("font_size", 14)
		mv.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		mv.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		mv.add_theme_constant_override("outline_size", 3)
		vbox.add_child(mv)

func _load_unit_portrait(unit: RefCounted) -> TextureRect:
	var portrait_id: String = unit.id
	var paths: Array = [
		"res://assets/sprites/cards/units/%s.jpg" % portrait_id,
		"res://assets/sprites/cards/units/%s.png" % portrait_id,
		"res://assets/sprites/cards/commanders/%s.jpg" % portrait_id,
		"res://assets/sprites/cards/commanders/%s.png" % portrait_id,
		"res://assets/sprites/cards/situations/%s.jpg" % portrait_id,
		"res://assets/sprites/cards/spells/%s.jpg" % portrait_id
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var tex: Resource = load(p)
			if tex is Texture2D:
				var rect := TextureRect.new()
				rect.texture = tex as Texture2D
				return rect
	return null
