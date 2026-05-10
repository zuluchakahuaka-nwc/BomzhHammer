extends Control

var _card_data: Dictionary = {}
var _cached_portrait: Texture2D = null
var _portrait_path_checked: bool = false

signal card_clicked(data: Dictionary)
signal card_right_clicked(data: Dictionary)

func _ready() -> void:
	custom_minimum_size = Vector2(250, 375)
	size = Vector2(250, 375)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func setup(data: Dictionary) -> void:
	_card_data = data
	_cached_portrait = null
	_portrait_path_checked = false
	minimum_size_changed.emit()
	queue_redraw()

func _draw() -> void:
	if _card_data.is_empty():
		return
	var w: float = size.x
	var h: float = size.y
	if w < 10 or h < 10:
		w = custom_minimum_size.x
		h = custom_minimum_size.y
	var rect := Rect2(0, 0, w, h)
	var card_type: String = _card_data.get("type", "unit")
	var rarity: String = _card_data.get("rarity", "common")
	var border_color := _get_type_color(card_type, rarity)
	var radius: float = 8.0

	if not _portrait_path_checked:
		_portrait_path_checked = true
		var portrait_path: String = _get_portrait_path()
		_cached_portrait = _load_image(portrait_path)

	draw_rounded_rect(rect, Color(0.06, 0.05, 0.03), radius)

	if _cached_portrait:
		draw_texture_rect(_cached_portrait, rect, false)
		var grad_steps: int = 12
		var grad_h: float = h * 0.55
		var grad_y: float = h - grad_h
		for i in range(grad_steps):
			var t: float = float(i) / float(grad_steps)
			var a: float = t * 0.82
			var sy: float = grad_y + grad_h * t
			var sh: float = grad_h / float(grad_steps) + 1.0
			draw_rect(Rect2(0, sy, w, sh), Color(0, 0, 0, a), true)
	else:
		var ph_color := _get_type_color(card_type, rarity).darkened(0.7)
		draw_rect(rect, ph_color, true)
		var name_str: String = _card_data.get("name_ru", _card_data.get("id", ""))
		var ph_font := ThemeDB.fallback_font
		var lines := _wrap_text(name_str, ph_font, 24, w - 16)
		var start_y: float = h * 0.5 - float(lines.size()) * 14.0
		for i in range(lines.size()):
			draw_string_outline(ph_font, Vector2(8, start_y + i * 28 + 24), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 16, 24, 5, Color(0, 0, 0))
			draw_string(ph_font, Vector2(8, start_y + i * 28 + 24), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 16, 24, Color(1, 1, 1))

	draw_rounded_rect(Rect2(0, 0, w, h), Color.TRANSPARENT, radius, border_color, 3.0)

	var font := ThemeDB.fallback_font
	var name_str2: String = _card_data.get("name_ru", _card_data.get("id", ""))
	var name_size: int = 24
	var name_lines: Array = _wrap_text(name_str2, font, name_size, w - 12)
	var name_y: float = h * 0.44 - float(name_lines.size() - 1) * (name_size + 2) * 0.5
	var name_x: float = 6.0
	for i in range(name_lines.size()):
		draw_string_outline(font, Vector2(name_x, name_y + i * (name_size + 2)), name_lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, name_size, 6, Color(0, 0, 0))
		draw_string(font, Vector2(name_x, name_y + i * (name_size + 2)), name_lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, name_size, Color(1, 1, 1))
	var desc_size: int = 20
	var line_h: float = desc_size + 4
	var name_block_bottom: float = name_y + float(name_lines.size()) * (name_size + 2)
	var stat_y: float = name_block_bottom + 8.0

	if card_type == "unit" or card_type == "commander":
		var atk: int = _card_data.get("attack", 0)
		var def: int = _card_data.get("defense", 0)
		var hp: int = _card_data.get("hp", 0)
		var stat_size: int = 26
		var col_w: float = w / 3.0
		draw_string_outline(font, Vector2(col_w * 0.0 + 10, stat_y + stat_size), str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, 3, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 0.0 + 10, stat_y + stat_size), str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, Color(1, 1, 1))
		draw_string_outline(font, Vector2(col_w * 1.0 + 10, stat_y + stat_size), str(def), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, 3, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 1.0 + 10, stat_y + stat_size), str(def), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, Color(1, 1, 1))
		draw_string_outline(font, Vector2(col_w * 2.0 + 10, stat_y + stat_size), str(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, 3, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 2.0 + 10, stat_y + stat_size), str(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, stat_size, Color(1, 1, 1))
		var label_size: int = 13
		draw_string_outline(font, Vector2(col_w * 0.0 + 6, stat_y + stat_size + label_size + 2), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 2, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 0.0 + 6, stat_y + stat_size + label_size + 2), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(1, 1, 1))
		draw_string_outline(font, Vector2(col_w * 1.0 + 6, stat_y + stat_size + label_size + 2), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 2, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 1.0 + 6, stat_y + stat_size + label_size + 2), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(1, 1, 1))
		draw_string_outline(font, Vector2(col_w * 2.0 + 6, stat_y + stat_size + label_size + 2), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 2, Color(0, 0, 0))
		draw_string(font, Vector2(col_w * 2.0 + 6, stat_y + stat_size + label_size + 2), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(1, 1, 1))
		var desc: String = _card_data.get("description_ru", "")
		if desc != "":
			var unit_desc_size: int = 18
			var unit_line_h: float = unit_desc_size + 3
			var separator_y: float = stat_y + stat_size + label_size + 12
			draw_line(Vector2(8, separator_y), Vector2(w - 8, separator_y), border_color, 2.0)
			var lines := _wrap_text(desc, font, unit_desc_size, w - 12)
			var desc_y: float = separator_y + 12
			for i in range(mini(lines.size(), 2)):
				draw_string_outline(font, Vector2(6, desc_y + i * unit_line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, unit_desc_size, 2, Color(0, 0, 0))
				draw_string(font, Vector2(6, desc_y + i * unit_line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, unit_desc_size, Color(1, 1, 1))
	else:
		var desc: String = _card_data.get("description_ru", "")
		var lines := _wrap_text(desc, font, desc_size, w - 12)
		for i in range(mini(lines.size(), 5)):
			draw_string_outline(font, Vector2(6, stat_y + i * line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, desc_size, 2, Color(0, 0, 0))
			draw_string(font, Vector2(6, stat_y + i * line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 12, desc_size, Color(1, 1, 1))

func _wrap_text(text: String, font: Font, font_size: int, max_width: float) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var current: String = ""
	for word in words:
		var test: String = current + (" " if current != "" else "") + word
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
			if current != "":
				lines.append(current)
			current = word
		else:
			current = test
	if current != "":
		lines.append(current)
	return lines

func draw_rounded_rect(r: Rect2, fill: Color, radius: float, border: Color = Color.TRANSPARENT, border_w: float = 0.0) -> void:
	var points := PackedVector2Array()
	var segments: int = 8
	for corner in range(4):
		var cx: float
		var cy: float
		var start_angle: float
		match corner:
			0:
				cx = r.position.x + radius
				cy = r.position.y + radius
				start_angle = PI
			1:
				cx = r.position.x + r.size.x - radius
				cy = r.position.y + radius
				start_angle = -PI / 2.0
			2:
				cx = r.position.x + r.size.x - radius
				cy = r.position.y + r.size.y - radius
				start_angle = 0.0
			3:
				cx = r.position.x + radius
				cy = r.position.y + r.size.y - radius
				start_angle = PI / 2.0
		for i in range(segments + 1):
			var angle: float = start_angle + (PI / 2.0) * (float(i) / segments)
			points.append(Vector2(cx + cos(angle) * radius, cy + sin(angle) * radius))
	if fill.a > 0:
		draw_colored_polygon(points, fill)
	if border_w > 0 and border.a > 0:
		draw_polyline(points, border, border_w, true)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.55, 0.55, 0.55)
		"uncommon": return Color(0.15, 0.65, 0.15)
		"rare": return Color(0.2, 0.45, 0.95)
		"legendary": return Color(1.0, 0.84, 0.0)
		_: return Color(0.55, 0.55, 0.55)

func _get_type_color(card_type: String, rarity: String) -> Color:
	var rarity_brightness := {"common": 0.7, "uncommon": 0.85, "rare": 1.0, "legendary": 1.0}
	var b: float = rarity_brightness.get(rarity, 0.7)
	match card_type:
		"unit":
			return Color(0.15 * b, 0.75 * b, 0.2 * b)
		"commander":
			return Color(1.0 * b, 0.55 * b, 0.0)
		"situation":
			return Color(1.0 * b, 0.85 * b, 0.1 * b)
		"spell":
			return Color(0.7 * b, 0.25 * b, 1.0 * b)
		_:
			return _get_rarity_color(rarity)

func _get_portrait_path() -> String:
	var card_id: String = _card_data.get("id", "")
	var card_type: String = _card_data.get("type", "unit")
	var base: String = "res://assets/sprites/cards/"
	var sub: String = ""
	match card_type:
		"unit": sub = "units/"
		"situation": sub = "situations/"
		"commander": sub = "commanders/"
		"spell": sub = "spells/"
		_: sub = "units/"
	for ext in [".png", ".jpg"]:
		var path: String = base + sub + card_id + ext
		if FileAccess.file_exists(path):
			return path
	return ""

func _load_image(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res as Texture2D
	var img: Image = Image.new()
	if img.load(path) == OK:
		var tex: Texture2D = ImageTexture.create_from_image(img)
		return tex
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(_card_data)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			card_right_clicked.emit(_card_data)
			accept_event()

func get_card_data() -> Dictionary:
	return _card_data
