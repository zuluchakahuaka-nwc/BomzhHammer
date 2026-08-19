class_name MapBuilder
extends RefCounted

var _map: Control = null

var _grid: Array = [
	["romashkovy_proezd", "ulica_trezvyh", "dacha_area", "dumpster_north", "kutuzka", "dumpster_elite"],
	["dump_west", "street_west", "pereulok_poproshaek", "den_basman", "dump_north", "station_yaroslavsky"],
	["dumpster_pharmacy", "ulica_pohmelnaya_44", "pereulok_skautov", "station_leningradsky", "station_kazansky", "prospect_avtoritetov"],
	["dump_south", "obrygalovka", "street_center", "square_three_stations", "prospect_peregarova", "street_east"],
	["", "den_taganka", "magazin_spirtmaster", "ploschad_pelmenistana", "ulica_djamala", "dump_east"],
]

var _rows: int = 5
var _cols: int = 6

func _init(map: Control) -> void:
	_map = map

func build_map() -> void:
	var map_area: Control = _map.map_area
	_map._city_map_tex = load_city_texture()
	if _map._city_map_tex:
		var city_bg: TextureRect = map_area.get_node_or_null("CityBg")
		if city_bg:
			city_bg.texture = _map._city_map_tex

	var cell_w: float = 1.0 / float(_cols)
	var cell_h: float = 1.0 / float(_rows)

	var grid_lines := Control.new()
	grid_lines.name = "GridLines"
	grid_lines.anchor_right = 1.0
	grid_lines.anchor_bottom = 1.0
	grid_lines.z_index = 5
	grid_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.add_child(grid_lines)

	for r in range(_rows):
		for c in range(_cols):
			var tid: String = _grid[r][c]
			if tid == "":
				continue
			var t_data: Dictionary = CardDatabase.get_territory(tid)
			if t_data.is_empty():
				continue
			_build_cell(map_area, t_data, c, r, cell_w, cell_h)

	Logger.info("GameMap", "Grid map built: %dx%d = %d cells" % [_cols, _rows, _count_cells()])

func _count_cells() -> int:
	var n: int = 0
	for row in _grid:
		for tid in row:
			if tid != "":
				n += 1
	return n

func load_city_texture() -> Texture2D:
	var paths: Array = [
		"res://assets/sprites/map/city_map.jpg",
		"res://assets/sprites/map/city_map_backup.jpg",
	]
	for p in paths:
		var tex := SafeLoader.texture(p)
		if tex != null:
			return tex
	return null

func _build_cell(map_area: Control, t_data: Dictionary, col: int, row: int, cell_w: float, cell_h: float) -> void:
	var tid: String = t_data.get("id", "")
	var owner: String = GameManager.get_territory_owner(tid)
	var terrain: String = t_data.get("terrain", "open_street")
	var is_capital: bool = t_data.get("is_capital", false)

	var x0: float = float(col) * cell_w
	var y0: float = float(row) * cell_h

	var btn := Button.new()
	btn.name = "T_" + tid
	btn.anchor_left = x0
	btn.anchor_top = y0
	btn.anchor_right = x0 + cell_w
	btn.anchor_bottom = y0 + cell_h
	btn.z_index = 10
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(2)
	style.bg_color = _terrain_color(terrain, owner)
	style.border_color = _border_color(owner)
	if is_capital:
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hov := style.duplicate()
	hov.bg_color.a = 0.9
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)

	var icons := {"dump":"S","station":"B","square_three_stations":"3B","den":"D",
		"supermarket_dumpster":"M","pharmacy_dumpster":"A","dacha":"Da",
		"obrygalovka":"O","kutuzka":"K","open_street":"."}
	btn.text = icons.get(terrain, "?")
	btn.add_theme_font_size_override("font_size", 34)
	btn.tooltip_text = Localization.get_territory_name(t_data)
	btn.pressed.connect(_map._on_territory_clicked.bind(tid))
	btn.gui_input.connect(_map._on_territory_gui_input.bind(tid))
	map_area.add_child(btn)
	_map._territory_buttons[tid] = btn

	var name_text: String = Localization.get_territory_name(t_data)
	var lbl := Label.new()
	lbl.name = "L_" + tid
	lbl.text = _wrap_name(name_text, 12)
	lbl.anchor_left = x0
	lbl.anchor_top = y0 + cell_h * 0.55
	lbl.anchor_right = x0 + cell_w
	lbl.anchor_bottom = y0 + cell_h
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.z_index = 11
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_area.add_child(lbl)

func _terrain_color(terrain: String, owner: String) -> Color:
	match owner:
		"player":
			return Color(0.85, 0.75, 0.1, 0.45)
		"enemy":
			return Color(0.7, 0.1, 0.1, 0.4)
	return Color(0, 0, 0, 0)

func _border_color(owner: String) -> Color:
	match owner:
		"player":
			return Color(1.0, 1.0, 0.3)
		"enemy":
			return Color(1.0, 0.2, 0.2)
		_:
			return Color(0.6, 0.55, 0.45)

func _wrap_name(name: String, max_chars: int) -> String:
	if name.length() <= max_chars:
		return name
	var words: PackedStringArray = name.split(" ")
	var lines: PackedStringArray = []
	var current: String = ""
	for word in words:
		if current.length() + word.length() + 1 > max_chars and current != "":
			lines.append(current)
			current = word
		else:
			if current != "":
				current += " "
			current += word
	if current != "":
		lines.append(current)
	return "\n".join(lines)

func style_by_owner(style: StyleBoxFlat, owner: String) -> void:
	match owner:
		"player":
			style.bg_color = Color(0.85, 0.75, 0.1, 0.85)
			style.border_color = Color(1.0, 1.0, 0.3)
		"enemy":
			style.bg_color = Color(0.7, 0.1, 0.1, 0.75)
			style.border_color = Color(1.0, 0.2, 0.2)
		_:
			style.bg_color = Color(0.3, 0.28, 0.25, 0.6)
			style.border_color = Color(0.6, 0.55, 0.45)
