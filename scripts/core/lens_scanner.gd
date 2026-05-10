extends Control

var _timer: float = 0.0
var _interval: float = 3.0
var _scan_count: int = 0
var _menu_fail: int = 0
var _map_fail: int = 0
var _pulse_t: float = 0.0

var _menu_sq: ColorRect
var _menu_lbl: Label
var _map_sq: ColorRect
var _map_lbl: Label
var _menu_color: Color = Color(0.4, 0.4, 0.4)
var _map_color: Color = Color(0.4, 0.4, 0.4)

const MENU_BG := Color(0.1, 0.08, 0.06)

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 500

	_menu_sq = ColorRect.new()
	_menu_sq.size = Vector2(18, 18)
	add_child(_menu_sq)

	_menu_lbl = Label.new()
	_menu_lbl.add_theme_font_size_override("font_size", 13)
	_menu_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	_menu_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_menu_lbl.add_theme_constant_override("outline_size", 2)
	_menu_lbl.text = "MENU: ---"
	add_child(_menu_lbl)

	_map_sq = ColorRect.new()
	_map_sq.size = Vector2(18, 18)
	add_child(_map_sq)

	_map_lbl = Label.new()
	_map_lbl.add_theme_font_size_override("font_size", 13)
	_map_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	_map_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_map_lbl.add_theme_constant_override("outline_size", 2)
	_map_lbl.text = "MAP: ---"
	add_child(_map_lbl)

	_reposition()
	get_viewport().size_changed.connect(_reposition)
	set_process(true)

func _reposition() -> void:
	var vw: float = get_viewport().size.x
	var rx: float = vw - 170.0
	_menu_sq.position = Vector2(rx, 8)
	_menu_lbl.position = Vector2(rx + 24, 7)
	_map_sq.position = Vector2(rx, 30)
	_map_lbl.position = Vector2(rx + 24, 29)

func _process(delta: float) -> void:
	_pulse_t += delta
	var pulse := 0.6 + 0.4 * sin(_pulse_t * 2.0)
	_menu_sq.color = Color(_menu_color.r * pulse, _menu_color.g * pulse, _menu_color.b * pulse)
	_map_sq.color = Color(_map_color.r * pulse, _map_color.g * pulse, _map_color.b * pulse)

	_timer += delta
	if _timer < _interval:
		return
	_timer = 0.0
	_scan()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		var current := get_tree().current_scene
		if current != null and current.name not in ["main_menu", "MainMenu"]:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _scan() -> void:
	var current := get_tree().current_scene
	if current == null:
		return
	var scene_name: String = current.name
	var vp := get_viewport()
	if vp == null:
		return
	var tex := vp.get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 10 or h < 10:
		return
	_scan_count += 1
	var is_menu: bool = scene_name in ["MainMenu", "main_menu"]
	var is_map: bool = scene_name in ["game_map", "GameMap"]
	if _scan_count <= 5 or is_menu or is_map:
		var sample := img.get_pixel(w / 2, h / 2)
		Logger.info("LENS", "scan#%d scene=[%s] menu=%s map=%s center_color=(%.3f,%.3f,%.3f)" % [_scan_count, scene_name, is_menu, is_map, sample.r, sample.g, sample.b])

	if is_menu:
		_check_main_menu(img, w, h)
	else:
		_menu_color = Color(0.3, 0.3, 0.3)
		_menu_lbl.text = "MENU: ---"
		_menu_fail = 0

	if is_map:
		_check_game_map(img, w, h)
	else:
		_map_color = Color(0.3, 0.3, 0.3)
		_map_lbl.text = "MAP: ---"
		_map_fail = 0

func _check_main_menu(img: Image, w: int, h: int) -> void:
	var points: Array = [
		Vector2i(w * 2 / 5, h * 2 / 5),
		Vector2i(w / 2, h / 2),
		Vector2i(w * 3 / 5, h * 3 / 5),
	]
	var bg_hits: int = 0
	for p in points:
		var c: Color = img.get_pixel(p.x, p.y)
		if _is_menu_bg(c):
			bg_hits += 1
	if bg_hits >= 3:
		_menu_fail += 1
		_menu_color = Color(1, 0.15, 0.1)
		_menu_lbl.text = "MENU: FAIL #%d" % _menu_fail
		Logger.error("LENS", "MAIN MENU — заставка слетела! center = bg color (%d/%d hits, fail #%d)" % [bg_hits, points.size(), _menu_fail])
		_try_fix_menu()
	else:
		_menu_color = Color(0, 0.85, 0.2)
		_menu_lbl.text = "MENU: OK #%d" % _scan_count
		if _menu_fail > 0:
			Logger.info("LENS", "Menu recovered after %d failures" % _menu_fail)
			_menu_fail = 0

func _check_game_map(img: Image, w: int, h: int) -> void:
	var gm: Control = _find_game_map()
	if gm == null:
		_map_color = Color(0.3, 0.3, 0.3)
		_map_lbl.text = "MAP: ---"
		return
	var tex: Texture2D = gm.get("_city_map_tex")
	var need_fix: bool = false
	var reason: String = ""
	if tex == null:
		need_fix = true
		reason = "_city_map_tex is NULL"
	else:
		var points: Array = [
			Vector2i(w / 2, h / 2),
			Vector2i(w * 2 / 5, h * 2 / 5),
			Vector2i(w * 3 / 5, h * 3 / 5),
		]
		var dark_hits: int = 0
		for p in points:
			var c: Color = img.get_pixel(p.x, p.y)
			if c.r + c.g + c.b < 0.3:
				dark_hits += 1
		if dark_hits >= 2:
			need_fix = true
			reason = "center is DARK (%d/%d hits)" % [dark_hits, points.size()]
	if need_fix:
		_map_fail += 1
		_map_color = Color(1, 0.15, 0.1)
		_map_lbl.text = "MAP: FAIL #%d" % _map_fail
		Logger.error("LENS", "GAME MAP — %s, fail #%d" % [reason, _map_fail])
		_fix_city_map(gm)
	else:
		var city_bg: TextureRect = _get_city_bg(gm)
		if city_bg != null and city_bg.texture == null:
			city_bg.texture = tex
		_map_color = Color(0, 0.85, 0.2)
		_map_lbl.text = "MAP: OK #%d" % _scan_count
		if _map_fail > 0:
			Logger.info("LENS", "Game map recovered after %d failures" % _map_fail)
			_map_fail = 0

func _find_game_map() -> Control:
	var current := get_tree().current_scene
	if current != null and current.name in ["game_map", "GameMap"]:
		return current
	return null

func _get_city_bg(gm: Control) -> TextureRect:
	if gm.has_node("MapArea/CityBg"):
		return gm.get_node("MapArea/CityBg")
	return null

func _fix_city_map(gm: Control) -> void:
	var paths: Array = [
		"res://assets/sprites/map/city_map.jpg",
		"res://assets/sprites/map/city_map_backup.jpg",
	]
	for p in paths:
		var img := Image.new()
		if img.load(p) == OK:
			var tex := ImageTexture.create_from_image(img)
			if tex != null:
				gm.set("_city_map_tex", tex)
				var city_bg: TextureRect = _get_city_bg(gm)
				if city_bg != null:
					city_bg.texture = tex
				Logger.info("LENS", "FIXED: city_map reloaded from %s" % p)
				return

func _is_menu_bg(c: Color) -> bool:
	return absf(c.r - MENU_BG.r) < 0.04 and absf(c.g - MENU_BG.g) < 0.04 and absf(c.b - MENU_BG.b) < 0.04

func _is_gray(c: Color) -> bool:
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b
	var avg: float = (r + g + b) / 3.0
	var diff: float = maxf(absf(r - avg), maxf(absf(g - avg), absf(b - avg)))
	return diff < 0.05 and avg > 0.25 and avg < 0.75

func _try_fix_menu() -> void:
	var root := get_tree().root
	for c in root.get_children():
		if c.name in ["MainMenu", "main_menu"]:
			var logo: TextureRect = c.get_node_or_null("Logo")
			if logo and logo.texture == null:
				var paths: Array = [
					"res://assets/sprites/splash/logos/logo_5.jpg",
					"res://assets/sprites/splash/logos/logo_4.jpg",
					"res://assets/sprites/splash/logos/logo_3.jpg",
					"res://assets/sprites/splash/logos/logo_2.jpg",
					"res://assets/sprites/splash/logos/logo_1.jpg",
				]
				for p in paths:
					if FileAccess.file_exists(p):
						var img := Image.new()
						if img.load(p) == OK:
							logo.texture = ImageTexture.create_from_image(img)
							Logger.info("LENS", "FIXED: menu logo reloaded from %s" % p)
							return
			var tv_bg: TextureRect = c.get_node_or_null("BomzhTV/TVBackground")
			if tv_bg and tv_bg.texture == null:
				if FileAccess.file_exists("res://assets/sprites/splash/bomzh_tv_bg.jpg"):
					var img := Image.new()
					if img.load("res://assets/sprites/splash/bomzh_tv_bg.jpg") == OK:
						tv_bg.texture = ImageTexture.create_from_image(img)
						Logger.info("LENS", "FIXED: TV bg reloaded")
			break

func _try_fix_game_map() -> void:
	var root := get_tree().root
	for c in root.get_children():
		if c.name in ["game_map", "GameMap"] and c.has_node("MapArea"):
			var map_area: Control = c.get_node("MapArea")
			var city_bg: TextureRect = map_area.get_node_or_null("CityBg")
			if city_bg and city_bg.texture == null:
				var paths: Array = [
					"res://assets/sprites/map/city_map.jpg",
					"res://assets/sprites/map/city_map_backup.jpg",
				]
				for p in paths:
					if FileAccess.file_exists(p):
						var img := Image.new()
						if img.load(p) == OK:
							city_bg.texture = ImageTexture.create_from_image(img)
							c._city_map_tex = city_bg.texture
							Logger.info("LENS", "FIXED: city_map reloaded from %s" % p)
							return
			break
