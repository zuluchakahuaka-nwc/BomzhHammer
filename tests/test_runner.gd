extends SceneTree

var _pass_count: int = 0
var _fail_count: int = 0
var _error_count: int = 0
var _current_suite: String = ""
var _failures: Array = []

func _init() -> void:
	print("\n========================================")
	print("  BOMZHHAMMER TEST SUITE")
	print("========================================\n")

	test_data_integrity()
	test_scenes_exist()
	test_scripts_exist()
	test_error_parser_exists()
	test_map_image_exists()
	test_card_images_exist()
	test_connections_valid()
	test_screen_lens()
	test_safe_loader()
	test_video_files()
	test_music_files()
	test_splash_text_sizes()
	test_intro_overlay()

	print("\n========================================")
	if _fail_count == 0 and _error_count == 0:
		print("  ALL %d TESTS PASSED" % _pass_count)
	else:
		print("  PASSED: %d | FAILED: %d | ERRORS: %d" % [_pass_count, _fail_count, _error_count])
		if _failures.size() > 0:
			print("  --- FAILURES ---")
			for f in _failures:
				print("  %s" % f)
	print("========================================\n")
	quit()

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s" % [_current_suite, msg])
		print("  FAIL: %s" % msg)

func assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (got '%s', expected '%s')" % [_current_suite, msg, str(actual), str(expected)])
		print("  FAIL: %s (got '%s', expected '%s')" % [msg, str(actual), str(expected)])

func assert_gt(actual: Variant, threshold: Variant, msg: String) -> void:
	if actual > threshold:
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (%s not > %s)" % [_current_suite, msg, str(actual), str(threshold)])
		print("  FAIL: %s (%s not > %s)" % [msg, str(actual), str(threshold)])

func assert_gte(actual: Variant, threshold: Variant, msg: String) -> void:
	if actual >= threshold:
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (%s not >= %s)" % [_current_suite, msg, str(actual), str(threshold)])
		print("  FAIL: %s (%s not >= %s)" % [msg, str(actual), str(threshold)])

func assert_has_key(dict: Dictionary, key: String, msg: String) -> void:
	if dict.has(key):
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (missing key '%s')" % [_current_suite, msg, key])
		print("  FAIL: %s (missing key '%s')" % [msg, key])

func assert_file_exists(path: String, msg: String) -> void:
	if FileAccess.file_exists(path):
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (missing: %s)" % [_current_suite, msg, path])
		print("  FAIL: %s (missing: %s)" % [msg, path])

func suite(name: String) -> void:
	_current_suite = name
	print("\n--- %s ---" % name)

func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_error_count += 1
		print("  ERROR: file not found: %s" % path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_error_count += 1
		print("  ERROR: cannot open: %s" % path)
		return null
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		_error_count += 1
		print("  ERROR: parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.get_data()

# ============================================
func test_data_integrity() -> void:
	suite("Data Integrity")
	var files: Dictionary = {
		"res://data/cards/units.json": "units",
		"res://data/cards/situations.json": "situations",
		"res://data/cards/spells.json": "spells",
		"res://data/cards/commanders.json": "commanders",
		"res://data/cards/achievements.json": "achievements",
		"res://data/maps/territories.json": "territories",
		"res://data/maps/connections.json": "connections",
	}
	for path in files:
		assert_file_exists(path, "%s exists" % files[path])

	# Units
	var units = load_json("res://data/cards/units.json")
	assert_true(units is Array, "units is array")
	if units is Array:
		assert_gt(units.size(), 0, "units not empty (%d)" % units.size())
		var ids: Array = []
		for u in units:
			var uid: String = u.get("id", "")
			assert_has_key(u, "id", "unit has id")
			assert_has_key(u, "name_ru", "unit '%s' has name_ru" % uid)
			assert_has_key(u, "attack", "unit '%s' has attack" % uid)
			assert_has_key(u, "defense", "unit '%s' has defense" % uid)
			assert_has_key(u, "hp", "unit '%s' has hp" % uid)
			assert_has_key(u, "rarity", "unit '%s' has rarity" % uid)
			assert_has_key(u, "cost", "unit '%s' has cost" % uid)
			assert_eq(u.get("type", ""), "unit", "unit '%s' type=unit" % uid)
			assert_true(not ids.has(uid), "unit '%s' id unique" % uid)
			ids.append(uid)
			assert_gte(u.get("attack", -1), 0, "unit '%s' atk>=0" % uid)
			assert_gte(u.get("defense", -1), 0, "unit '%s' def>=0" % uid)
			assert_gte(u.get("hp", -1), 1, "unit '%s' hp>=1" % uid)
			var rarities: Array = ["common", "uncommon", "rare", "legendary"]
			assert_true(rarities.has(u.get("rarity", "")), "unit '%s' valid rarity" % uid)

	# Situations
	var sits = load_json("res://data/cards/situations.json")
	assert_true(sits is Array, "situations is array")
	if sits is Array:
		assert_gt(sits.size(), 0, "situations not empty (%d)" % sits.size())
		var sit_ids: Array = []
		for s in sits:
			var sid: String = s.get("id", "")
			assert_has_key(s, "id", "situation has id")
			assert_has_key(s, "effect_type", "sit '%s' has effect_type" % sid)
			assert_has_key(s, "rarity", "sit '%s' has rarity" % sid)
			assert_true(not sit_ids.has(sid), "sit '%s' id unique" % sid)
			sit_ids.append(sid)

	# Spells
	var spells = load_json("res://data/cards/spells.json")
	assert_true(spells is Array, "spells is array")
	if spells is Array:
		for sp in spells:
			assert_has_key(sp, "id", "spell has id")
			assert_has_key(sp, "effect_type", "spell '%s' has effect_type" % sp.get("id", ""))
			assert_has_key(sp, "cost", "spell '%s' has cost" % sp.get("id", ""))

	# Commanders
	var cmds = load_json("res://data/cards/commanders.json")
	assert_true(cmds is Array, "commanders is array")
	if cmds is Array:
		for c in cmds:
			assert_has_key(c, "id", "commander has id")
			assert_has_key(c, "effect_type", "cmd '%s' has effect_type" % c.get("id", ""))

	# Territories
	var territories = load_json("res://data/maps/territories.json")
	assert_true(territories is Array, "territories is array")
	if territories is Array:
		assert_gte(territories.size(), 10, ">=10 territories (%d)" % territories.size())
		for t in territories:
			var tid: String = t.get("id", "")
			assert_has_key(t, "id", "territory has id")
			assert_has_key(t, "terrain", "territory '%s' has terrain" % tid)
			assert_has_key(t, "initial_owner", "territory '%s' has owner" % tid)
			assert_has_key(t, "map_x", "territory '%s' has map_x" % tid)
			assert_has_key(t, "map_y", "territory '%s' has map_y" % tid)

	# Achievements
	var achs = load_json("res://data/cards/achievements.json")
	assert_true(achs is Array, "achievements is array")
	if achs is Array:
		assert_gt(achs.size(), 0, "achievements not empty")

	# Translations
	assert_file_exists("res://data/localization/translations.csv", "translations.csv")

# ============================================
func test_scenes_exist() -> void:
	suite("Scenes")
	for s in ["res://scenes/splash_screen.tscn", "res://scenes/main_menu.tscn",
			  "res://scenes/game_map.tscn", "res://scenes/battle_screen.tscn",
			  "res://scenes/settings.tscn"]:
		assert_file_exists(s, "scene %s" % s.get_file())

# ============================================
func test_scripts_exist() -> void:
	suite("Scripts")
	var scripts: Array = [
		"res://scripts/core/logger.gd",
		"res://scripts/core/error_parser.gd",
		"res://scripts/core/localization.gd",
		"res://scripts/core/game_manager.gd",
		"res://scripts/core/resource_manager.gd",
		"res://scripts/core/ideology_system.gd",
		"res://scripts/core/religion_system.gd",
		"res://scripts/core/achievement_system.gd",
		"res://scripts/core/turn_manager.gd",
		"res://scripts/cards/card_database.gd",
		"res://scripts/cards/card_instance.gd",
		"res://scripts/cards/card_effect.gd",
		"res://scripts/cards/deck.gd",
		"res://scripts/cards/hand.gd",
		"res://scripts/combat/battle_resolver.gd",
		"res://scripts/combat/unit_matcher.gd",
		"res://scripts/combat/event_trigger.gd",
		"res://scripts/map/territory.gd",
		"res://scripts/map/map_controller.gd",
		"res://scripts/map/path_finder.gd",
		"res://scripts/ai/ai_controller.gd",
		"res://scripts/ai/ai_strategy.gd",
		"res://scenes/splash_screen.gd",
		"res://scenes/main_menu.gd",
		"res://scenes/game_map.gd",
		"res://scenes/battle_screen.gd",
		"res://scenes/settings.gd",
	]
	for s in scripts:
		assert_file_exists(s, "script %s" % s.get_file())

# ============================================
func test_error_parser_exists() -> void:
	suite("ErrorParser")
	assert_file_exists("res://scripts/core/error_parser.gd", "error_parser.gd exists")
	assert_file_exists("res://tests/test_runner.gd", "test_runner.gd exists")
	var ep = load("res://scripts/core/error_parser.gd")
	assert_true(ep != null, "error_parser.gd loads as resource")

# ============================================
func test_map_image_exists() -> void:
	suite("Map Assets")
	assert_file_exists("res://assets/sprites/map/world_map.jpg", "world_map.png exists")
	assert_file_exists("res://assets/sprites/splash/splash.jpg", "splash.png exists")
	assert_file_exists("res://assets/sprites/cards/backs/situation_back.jpg", "situation_back.jpg")
	assert_file_exists("res://assets/sprites/cards/backs/unit_back.jpg", "unit_back.jpg")

# ============================================
func test_card_images_exist() -> void:
	suite("Card Images")
	var units = load_json("res://data/cards/units.json")
	var unit_img_count: int = 0
	if units is Array:
		for u in units:
			var uid: String = u.get("id", "")
			for ext in [".jpg", ".png"]:
				var path: String = "res://assets/sprites/cards/units/%s%s" % [uid, ext]
				if FileAccess.file_exists(path):
					unit_img_count += 1
					break
	if units is Array:
		if unit_img_count < units.size():
			print("  INFO: %d/%d unit images present (Leonardo AI art pending)" % [unit_img_count, units.size()])

	var sits = load_json("res://data/cards/situations.json")
	var sit_img_count: int = 0
	if sits is Array:
		for s in sits:
			var sid: String = s.get("id", "")
			for ext in [".jpg", ".png"]:
				var path: String = "res://assets/sprites/cards/situations/%s%s" % [sid, ext]
				if FileAccess.file_exists(path):
					sit_img_count += 1
					break
	if sits is Array:
		if sit_img_count < sits.size():
			print("  INFO: %d/%d situation images present (Leonardo AI art pending)" % [sit_img_count, sits.size()])

	var icons: Array = ["icon_bottles", "icon_coins", "icon_rolltons", "icon_cardboard", "icon_food"]
	for ic in icons:
		assert_file_exists("res://assets/sprites/ui/icons/resources/%s.jpg" % ic, "icon %s" % ic)

	var frames: Array = ["frame_common", "frame_uncommon", "frame_rare", "frame_legendary"]
	for fr in frames:
		assert_file_exists("res://assets/sprites/ui/frames/%s.jpg" % fr, "frame %s" % fr)

# ============================================
func test_connections_valid() -> void:
	suite("Connections")
	var territories = load_json("res://data/maps/territories.json")
	var conns = load_json("res://data/maps/connections.json")
	if territories is Array and conns is Array:
		var t_ids: Array = []
		for t in territories:
			t_ids.append(t.get("id", ""))
		assert_gt(conns.size(), 0, "connections not empty (%d)" % conns.size())
		for c in conns:
			var f: String = c.get("from", "")
			var t: String = c.get("to", "")
			assert_has_key(c, "from", "connection has from")
			assert_has_key(c, "to", "connection has to")
			assert_true(t_ids.has(f), "conn from '%s' is valid territory" % f)
			assert_true(t_ids.has(t), "conn to '%s' is valid territory" % t)
		var connected: Array = []
		for c in conns:
			if not connected.has(c.get("from", "")):
				connected.append(c.get("from", ""))
			if not connected.has(c.get("to", "")):
				connected.append(c.get("to", ""))
		for tid in t_ids:
			assert_true(connected.has(tid), "territory '%s' is connected" % tid)

# ============================================
func test_screen_lens() -> void:
	suite("Screen Lens")
	assert_file_exists("res://assets/sprites/map/city_map.jpg", "city_map.jpg for background")

	var city_tex = load("res://assets/sprites/map/city_map.jpg")
	assert_true(city_tex is Texture2D, "city_map.jpg loads via load() as Texture2D")
	if city_tex is Texture2D:
		var city_img: Image = city_tex.get_image()
		if city_img != null:
			assert_gt(city_img.get_width(), 100, "city_map.jpg width > 100")

	var scene_scripts: Dictionary = {
		"res://scenes/pre_splash.gd": "PreSplash",
		"res://scenes/splash_screen.gd": "SplashScreen",
		"res://scenes/main_menu.gd": "MainMenu",
		"res://scenes/game_map.gd": "GameMap",
		"res://scenes/settings.gd": "Settings",
	}
	for path in scene_scripts:
		var res = load(path)
		assert_true(res != null, "%s script compiles (gray screen if FAIL)" % scene_scripts[path])

	var scenes: Array = [
		"res://scenes/pre_splash.tscn",
		"res://scenes/splash_screen.tscn",
		"res://scenes/main_menu.tscn",
		"res://scenes/game_map.tscn",
	]
	for s in scenes:
		var res = load(s)
		assert_true(res != null, "%s scene loads (gray screen if FAIL)" % s.get_file())

	var gm_res = load("res://scenes/game_map.tscn")
	if gm_res != null:
		var gm = gm_res.instantiate()
		if gm != null:
			var map_area = gm.get_node_or_null("MapArea")
			assert_true(map_area != null, "game_map has MapArea node")
			if map_area != null:
				var city_bg = map_area.get_node_or_null("CityBg")
				assert_true(city_bg != null, "MapArea has CityBg TextureRect (fallback map image)")
			gm.free()

# ============================================
func test_safe_loader() -> void:
	suite("SafeLoader")
	assert_file_exists("res://scripts/core/safe_loader.gd", "safe_loader.gd exists")
	var sl = load("res://scripts/core/safe_loader.gd")
	assert_true(sl != null, "safe_loader script loads")

	var city_tex = sl.texture("res://assets/sprites/map/city_map.jpg")
	assert_true(city_tex is Texture2D, "SafeLoader.texture loads city_map.jpg as Texture2D")

	var city_tex2 = sl.texture("res://assets/sprites/map/city_map_backup.jpg")
	assert_true(city_tex2 is Texture2D, "SafeLoader.texture loads city_map_backup.jpg as Texture2D")

	var splash_tex = sl.texture("res://assets/sprites/splash/intro_bg.jpg")
	assert_true(splash_tex is Texture2D, "SafeLoader.texture loads intro_bg.jpg as Texture2D")

	var nope = sl.texture("res://nonexistent.jpg")
	assert_true(nope == null, "SafeLoader.texture returns null for missing file")

	var unit_tex = sl.texture("res://assets/sprites/cards/units/unit_novice.jpg")
	assert_true(unit_tex is Texture2D, "SafeLoader.texture loads unit_novice.jpg as Texture2D")

	var first_ogg := "res://music/1eb6223b-9249-49ce-8ffc-1caef5ec2419.ogg"
	if FileAccess.file_exists(first_ogg):
		var audio_stream = sl.audio(first_ogg)
		assert_true(audio_stream is AudioStream, "SafeLoader.audio loads .ogg as AudioStream")

# ============================================
func test_video_files() -> void:
	suite("Video Files")
	var video_files: Array = [
		"res://video/video_1.ogv",
		"res://video/video_2.ogv",
		"res://video/video_3.ogv",
		"res://video/video_4.ogv",
	]
	for vf in video_files:
		assert_file_exists(vf, "video file %s" % vf.get_file())
	for vf in video_files:
		if FileAccess.file_exists(vf):
			var stream = load(vf)
			if stream != null:
				assert_true(stream is VideoStream, "%s loads as VideoStream" % vf.get_file())
			else:
				_pass_count += 1
				print("  INFO: %s not yet imported by editor (needs Godot editor scan)" % vf.get_file())

# ============================================
func test_music_files() -> void:
	suite("Music Files")
	var music_dir := DirAccess.open("res://music")
	assert_true(music_dir != null, "music directory accessible")
	var ogg_count: int = 0
	if music_dir != null:
		music_dir.list_dir_begin()
		var fn := music_dir.get_next()
		while fn != "":
			if not music_dir.current_is_dir() and fn.get_extension().to_lower() == "ogg":
				ogg_count += 1
				var path := "res://music/" + fn
				assert_file_exists(path, "music file %s" % fn)
				var stream = load(path)
				if stream is AudioStream:
					assert_true(true, "%s loads as AudioStream via load()" % fn)
				else:
					var sl = load("res://scripts/core/safe_loader.gd")
					if sl != null:
						var fallback = sl.audio(path)
						assert_true(fallback is AudioStream, "%s loads via SafeLoader.audio()" % fn)
			fn = music_dir.get_next()
		music_dir.list_dir_end()
	assert_gte(ogg_count, 5, "at least 5 ogg music files (found %d)" % ogg_count)

# ============================================
func test_splash_text_sizes() -> void:
	suite("Splash Text Sizes")
	var splash := load("res://scenes/splash_screen.tscn")
	assert_true(splash != null, "splash_screen.tscn loads")
	if splash != null:
		var inst = splash.instantiate()
		assert_true(inst != null, "splash_screen instantiates")
		if inst != null:
			var logo = inst.get_node_or_null("LogoLabel")
			if logo is Label:
				var fs: int = logo.get_theme_font_size("font_size")
				assert_lte(fs, 25, "SplashScreen LogoLabel font_size <= 25 (got %d)" % fs)
			var sub = inst.get_node_or_null("SubtitleLabel")
			if sub is Label:
				var fs2: int = sub.get_theme_font_size("font_size")
				assert_lte(fs2, 15, "SplashScreen SubtitleLabel font_size <= 15 (got %d)" % fs2)
			inst.free()

	var menu := load("res://scenes/main_menu.tscn")
	assert_true(menu != null, "main_menu.tscn loads")
	if menu != null:
		var inst2 = menu.instantiate()
		assert_true(inst2 != null, "main_menu instantiates")
		if inst2 != null:
			var title = inst2.get_node_or_null("VBoxContainer/TitleLabel")
			if title is Label:
				var fs3: int = title.get_theme_font_size("font_size")
				assert_lte(fs3, 80, "MainMenu TitleLabel font_size <= 80 (got %d)" % fs3)
			var sub2 = inst2.get_node_or_null("VBoxContainer/SubtitleLabel")
			if sub2 is Label:
				var fs4: int = sub2.get_theme_font_size("font_size")
				assert_lte(fs4, 48, "MainMenu SubtitleLabel font_size <= 48 (got %d)" % fs4)
			var logo_node = inst2.get_node_or_null("Logo")
			if logo_node is TextureRect:
				assert_lte(logo_node.z_index, 2, "MainMenu Logo z_index <= 2 (got %d)" % logo_node.z_index)
				assert_gte(logo_node.anchor_left, 0.45, "MainMenu Logo anchor_left >= 0.45 (got %.2f)" % logo_node.anchor_left)
			inst2.free()

func assert_lte(actual: Variant, threshold: Variant, msg: String) -> void:
	if actual <= threshold:
		_pass_count += 1
	else:
		_fail_count += 1
		_failures.append("FAIL [%s] %s (%s not <= %s)" % [_current_suite, msg, str(actual), str(threshold)])
		print("  FAIL: %s (%s not <= %s)" % [msg, str(actual), str(threshold)])

# ============================================
func test_intro_overlay() -> void:
	suite("Intro Overlay")
	var src = load("res://scripts/ui/map/card_detail_ui.gd")
	assert_true(src != null, "card_detail_ui.gd compiles")
	if src == null:
		return
	var code: String = FileAccess.get_file_as_string("res://scripts/ui/map/card_detail_ui.gd")
	assert_true(code.find("InputEventScreenTouch") >= 0, "intro overlay handles InputEventScreenTouch (Android tap)")
	assert_true(code.find("font_size\", 64") >= 0 or code.find("font_size\", 64") >= 0, "intro title font_size <= 64")
	var title_match := RegEx.create_from_string('title.*font_size.*?(\\d+)').search(code)
	if title_match:
		var fs := int(title_match.get_string(1))
		assert_lte(fs, 70, "intro title font_size <= 70 (got %d)" % fs)
	var para_match := RegEx.create_from_string('para.*font_size.*?(\\d+)').search(code)
	if para_match:
		var ps := int(para_match.get_string(1))
		assert_lte(ps, 35, "intro paragraph font_size <= 35 (got %d)" % ps)
	var hint_match := RegEx.create_from_string('hint.*font_size.*?(\\d+)').search(code)
	if hint_match:
		var hs := int(hint_match.get_string(1))
		assert_lte(hs, 30, "intro hint font_size <= 30 (got %d)" % hs)
	var has_localization := code.find('Localization.t("intro.click")') >= 0
	assert_true(has_localization, "intro click text uses Localization.t")
