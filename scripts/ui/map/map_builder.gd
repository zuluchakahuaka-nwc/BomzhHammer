class_name MapBuilder
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func build_map() -> void:
	var map_area: Control = _map.map_area

	_map._city_map_tex = load_city_texture()
	if _map._city_map_tex:
		Logger.info("GameMap", "CityMap texture loaded OK, size=%s" % str(_map._city_map_tex.get_size()))
		var city_bg: TextureRect = _map.map_area.get_node_or_null("CityBg")
		if city_bg:
			city_bg.texture = _map._city_map_tex
			Logger.info("GameMap", "CityBg TextureRect updated")
	else:
		Logger.error("GameMap", "FAILED to load city_map.jpg!")

	var all_t: Array = CardDatabase._territories.values()
	for t_data in all_t:
		_build_territory_button(map_area, t_data)
	Logger.info("GameMap", "Map built with %d territories" % all_t.size())

func load_city_texture() -> Texture2D:
	var paths: Array = [
		"res://assets/sprites/map/city_map.jpg",
		"res://assets/sprites/map/city_map_backup.jpg",
	]
	for p in paths:
		var tex := SafeLoader.texture(p)
		if tex != null:
			Logger.info("GameMap", "Loaded city_map: %s" % p)
			return tex
	return null

func _build_territory_button(map_area: Control, t_data: Dictionary) -> void:
	var tid: String = t_data.get("id", "")
	var raw_x: float = float(t_data.get("map_x", 540))
	var raw_y: float = float(t_data.get("map_y", 400))
	var pct_x: float = (raw_x - 150.0) / 780.0
	var pct_y: float = raw_y / 800.0
	var terrain: String = t_data.get("terrain", "open_street")
	var owner: String = GameManager.get_territory_owner(tid)
	var is_capital: bool = t_data.get("is_capital", false)
	var sz: float = 0.07 if is_capital else 0.05

	var btn := Button.new()
	btn.name = "T_" + tid
	btn.anchor_left = pct_x - sz / 2.0
	btn.anchor_top = pct_y - sz / 2.0
	btn.anchor_right = pct_x + sz / 2.0
	btn.anchor_bottom = pct_y + sz / 2.0
	btn.z_index = 10

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style_by_owner(style, owner)
	if is_capital:
		style.set_border_width_all(4)
		style.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", style)
	var hov := style.duplicate()
	hov.bg_color.a = 0.95
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)

	var icons := {"dump":"S","station":"B","square_three_stations":"3B","den":"D",
		"supermarket_dumpster":"M","pharmacy_dumpster":"A","dacha":"Da",
		"obrygalovka":"O","kutuzka":"K","open_street":"."}
	btn.text = icons.get(terrain, "?")
	btn.add_theme_font_size_override("font_size", 30)
	btn.tooltip_text = Localization.get_territory_name(t_data)
	btn.pressed.connect(_map._on_territory_clicked.bind(tid))
	btn.gui_input.connect(_map._on_territory_gui_input.bind(tid))
	map_area.add_child(btn)
	_map._territory_buttons[tid] = btn

	var lbl := Label.new()
	lbl.name = "L_" + tid
	lbl.text = Localization.get_territory_name(t_data)
	lbl.anchor_left = pct_x - 0.08
	lbl.anchor_top = pct_y + sz / 2.0
	lbl.anchor_right = pct_x + 0.08
	lbl.anchor_bottom = pct_y + sz / 2.0 + 0.04
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 11
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 4)
	map_area.add_child(lbl)

func style_by_owner(style: StyleBoxFlat, owner: String) -> void:
	match owner:
		"player":
			style.bg_color = Color(1.0, 0.9, 0.1, 0.95)
			style.border_color = Color(1.0, 1.0, 0.3)
			style.shadow_color = Color(1.0, 0.95, 0.2, 0.7)
			style.shadow_size = 10
		"enemy":
			style.bg_color = Color(0.95, 0.1, 0.1, 0.8)
			style.border_color = Color(1.0, 0.2, 0.2)
			style.shadow_color = Color(1.0, 0.1, 0.1, 0.4)
			style.shadow_size = 4
		_:
			style.bg_color = Color(0.45, 0.38, 0.28, 0.65)
			style.border_color = Color(0.65, 0.55, 0.4)
			style.shadow_size = 0
