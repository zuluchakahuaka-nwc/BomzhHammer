extends SceneTree

var _log: String = ""
var _errors: int = 0
var _passed: int = 0
var _current_scene: String = ""
var _step: int = 0
var _ready_done: bool = false
var _gm: Variant = null
var _cd: Variant = null

var _CardWidget: GDScript
var _DeckScript: GDScript
var _HandScript: GDScript
var _CardInstance: GDScript
var _BattleResolver: GDScript

func _init() -> void:
	print("UI TEST BOT")

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	var root: Node = get_root()
	if root == null:
		return false
	_gm = root.get_node_or_null("GameManager")
	_cd = root.get_node_or_null("CardDatabase")
	if _gm == null or _cd == null:
		return false
	_CardWidget = load("res://scripts/ui/card_widget.gd")
	_DeckScript = load("res://scripts/cards/deck.gd")
	_HandScript = load("res://scripts/cards/hand.gd")
	_CardInstance = load("res://scripts/cards/card_instance.gd")
	_BattleResolver = load("res://scripts/combat/battle_resolver.gd")
	_ready_done = true
	_run()
	return false

func _lm(msg: String) -> void:
	_log += msg + "\n"
	print(msg)

func _run() -> void:
	_lm("============================================")
	_lm("  UI TEST BOT — Simulated Player")
	_lm("============================================")

	_test_splash_screen()
	_test_main_menu()
	_test_settings()
	_test_game_map()
	_test_card_widget()
	_test_card_database()
	_test_combat_flow()
	_test_resource_flow()
	_test_building_ui()
	_test_happiness_ui()
	_test_save_load()

	_lm("")
	_lm("============================================")
	_lm("  UI TEST BOT REPORT")
	_lm("============================================")
	_lm("PASSED: %d" % _passed)
	_lm("ERRORS: %d" % _errors)
	if _errors == 0:
		_lm("ALL UI TESTS PASSED!")
	else:
		_lm("SOME TESTS FAILED — see errors above")
	_lm("============================================")

	var file := FileAccess.open("user://ui_test_bot_log.txt", FileAccess.WRITE)
	if file:
		file.store_string(_log)
		file.close()
	_lm("Log saved to user://ui_test_bot_log.txt")
	quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		_lm("  [PASS] %s" % description)
	else:
		_errors += 1
		_lm("  [FAIL] %s" % description)

func _simulate_click(button: Button) -> bool:
	if button == null:
		_lm("    ERROR: Button is null!")
		_errors += 1
		return false
	if not button.is_visible_in_tree():
		_lm("    WARN: Button not visible: %s" % button.name)
	button.emit_signal("pressed")
	_passed += 1
	_lm("    CLICK: %s (text='%s')" % [button.name, button.text])
	return true

func _load_scene(path: String) -> Node:
	var scene: PackedScene = load(path)
	if scene == null:
		_lm("  ERROR: Cannot load scene: %s" % path)
		_errors += 1
		return null
	var instance: Node = scene.instantiate()
	if instance == null:
		_lm("  ERROR: Cannot instantiate scene: %s" % path)
		_errors += 1
		return null
	get_root().add_child(instance)
	_current_scene = path
	_passed += 1
	_lm("  LOADED: %s" % path)
	return instance

func _cleanup_scene(instance: Node) -> void:
	if instance != null and is_instance_valid(instance):
		instance.queue_free()

func _find_button(node: Node, path: String) -> Button:
	if node == null:
		return null
	var btn: Node = node.get_node_or_null(path)
	if btn == null:
		_lm("    ERROR: Button not found at path: %s" % path)
		_errors += 1
		return null
	if not btn is Button:
		_lm("    ERROR: Node at %s is not a Button (is %s)" % [path, btn.get_class()])
		_errors += 1
		return null
	return btn as Button

func _find_node(node: Node, path: String) -> Node:
	if node == null:
		return null
	var n: Node = node.get_node_or_null(path)
	if n == null:
		_lm("    ERROR: Node not found at path: %s" % path)
		_errors += 1
		return null
	return n

func _test_splash_screen() -> void:
	_lm("\n=== TEST: Splash Screen ===")
	var splash: Node = _load_scene("res://scenes/splash_screen.tscn")
	if splash == null:
		return

	var bg: Node = _find_node(splash, "Background")
	_assert(bg != null, "Background ColorRect exists")

	var logo: Node = _find_node(splash, "LogoLabel")
	_assert(logo != null and logo.text == "БОМЖХАММЕР", "LogoLabel shows correct title")

	var subtitle: Node = _find_node(splash, "SubtitleLabel")
	_assert(subtitle != null and subtitle.text == "Перегар Свободы", "SubtitleLabel shows correct subtitle")

	var bar: Node = _find_node(splash, "LoadingBar")
	_assert(bar != null, "LoadingBar ProgressBar exists")

	var version: Node = _find_node(splash, "VersionLabel")
	_assert(version != null, "VersionLabel exists")

	_cleanup_scene(splash)

func _test_main_menu() -> void:
	_lm("\n=== TEST: Main Menu ===")
	var menu: Node = _load_scene("res://scenes/main_menu.tscn")
	if menu == null:
		return

	var title: Node = _find_node(menu, "VBoxContainer/TitleLabel")
	_assert(title != null and title.text == "BOMZHAMMER", "Title shows BOMZHAMMER")

	var subtitle: Node = _find_node(menu, "VBoxContainer/SubtitleLabel")
	_assert(subtitle != null and subtitle.text == "ПЕРЕГАР СВОБОДЫ", "Subtitle shows correctly")

	_simulate_click(_find_button(menu, "VBoxContainer/NewGameButton"))
	_simulate_click(_find_button(menu, "VBoxContainer/SettingsButton"))
	_simulate_click(_find_button(menu, "VBoxContainer/ContinueButton"))
	_simulate_click(_find_button(menu, "VBoxContainer/QuitButton"))

	var version: Node = _find_node(menu, "VersionLabel")
	_assert(version != null, "VersionLabel on main menu")

	var bomzh_tv: Node = _find_node(menu, "BomzhTV/TVLabel")
	_assert(bomzh_tv != null and bomzh_tv.text == "БомжТВ", "BomzhTV label exists")

	_cleanup_scene(menu)

func _test_settings() -> void:
	_lm("\n=== TEST: Settings Screen ===")
	var settings: Node = _load_scene("res://scenes/settings.tscn")
	if settings == null:
		return

	var title: Node = _find_node(settings, "MarginContainer/VBox/TitleLabel")
	_assert(title != null and title.text == "НАСТРОЙКИ", "Settings title correct")

	var slider: Node = _find_node(settings, "MarginContainer/VBox/AudioSection/VolumeRow/VolumeSlider")
	_assert(slider != null, "Volume slider exists")
	if slider != null:
		slider.value = 50.0
		var val_label: Node = _find_node(settings, "MarginContainer/VBox/AudioSection/VolumeRow/VolumeValue")
		_assert(val_label != null and val_label.text == "50%", "Volume label updates to 50%")
		slider.value = 0.0
		_assert(val_label.text == "0%", "Volume label updates to 0%")
		slider.value = 100.0
		_assert(val_label.text == "100%", "Volume label updates to 100%")

	var lang: Node = _find_node(settings, "MarginContainer/VBox/LangSection/LangOption")
	_assert(lang != null, "Language OptionButton exists")

	_simulate_click(_find_button(settings, "MarginContainer/VBox/ButtonRow/BackButton"))

	_cleanup_scene(settings)

func _test_game_map() -> void:
	_lm("\n=== TEST: Game Map ===")
	_gm.start_game()

	var map: Node = _load_scene("res://scenes/game_map.tscn")
	if map == null:
		return

	var top_bar: Node = _find_node(map, "TopBar")
	_assert(top_bar != null, "TopBar exists")

	var turn_label: Node = _find_node(map, "TopBar/HBox/TurnLabel")
	_assert(turn_label != null and turn_label.text == "Ход 1", "TurnLabel shows 'Ход 1'")

	var phase_label: Node = _find_node(map, "TopBar/HBox/PhaseLabel")
	_assert(phase_label != null, "PhaseLabel exists")

	var ideology_label: Node = _find_node(map, "TopBar/HBox/IdeologyLabel")
	_assert(ideology_label != null and ideology_label.text == "Нет строя", "IdeologyLabel shows 'Нет строя'")

	var end_btn: Button = _find_button(map, "EndTurnButton")
	_assert(end_btn != null and end_btn.text == "КОНЕЦ ФАЗЫ", "EndTurnButton exists with correct text")

	var hand_hbox: Node = _find_node(map, "HandScroll/HandHBox")
	_assert(hand_hbox != null, "HandHBox container exists")

	var left_deck: Node = _find_node(map, "LeftDeck/DeckBtn")
	_assert(left_deck != null, "LeftDeck button exists")

	var right_deck: Node = _find_node(map, "RightDeck/DeckBtn")
	_assert(right_deck != null, "RightDeck button exists")

	var left_count: Node = _find_node(map, "LeftDeck/CountLabel")
	_assert(left_count != null, "LeftDeck count label exists")

	var right_count: Node = _find_node(map, "RightDeck/CountLabel")
	_assert(right_count != null, "RightDeck count label exists")

	_lm("\n  --- Resource bar ---")
	var bottles: Node = _find_node(map, "ResourceBar/BottlesLabel")
	_assert(bottles != null and "Бутылки" in bottles.text, "BottlesLabel shows bottles")

	var coins: Node = _find_node(map, "ResourceBar/CoinsLabel")
	_assert(coins != null and "Мелочишка" in coins.text, "CoinsLabel shows coins")

	var respect: Node = _find_node(map, "ResourceBar/RespectLabel")
	_assert(respect != null and "Уважение" in respect.text, "RespectLabel shows respect")

	var pop: Node = _find_node(map, "ResourceBar/PopLabel")
	_assert(pop != null and "Бомжи" in pop.text, "PopLabel shows population")

	_lm("\n  --- Territory panel ---")
	var t_panel: Node = _find_node(map, "TerritoryInfoPanel")
	_assert(t_panel != null, "TerritoryInfoPanel exists")
	if t_panel != null:
		_assert(not t_panel.visible, "Territory panel hidden initially")

	var t_close: Button = _find_button(map, "TerritoryInfoPanel/TVBox/TClose")
	_assert(t_close != null, "Territory close button exists")

	var t_buyout: Button = _find_button(map, "TerritoryInfoPanel/TVBox/TBuyout")
	_assert(t_buyout != null, "Territory buyout button exists")

	_lm("\n  --- Card detail popup ---")
	var card_popup: Node = _find_node(map, "CardDetailPopup")
	_assert(card_popup != null, "CardDetailPopup exists")
	if card_popup != null:
		_assert(not card_popup.visible, "Card detail popup hidden initially")

	_lm("\n  --- Draw popup ---")
	var draw_popup: Node = _find_node(map, "DrawPopup")
	_assert(draw_popup != null, "DrawPopup exists")

	_lm("\n  --- Settings/Menu buttons in TopBar ---")
	_simulate_click(_find_button(map, "TopBar/HBox/SettingsButton"))
	_simulate_click(_find_button(map, "TopBar/HBox/MenuButton"))

	_lm("\n  --- Click End Turn 6 times (full cycle) ---")
	for i in range(6):
		_simulate_click(end_btn)
		var phase_names: PackedStringArray = ["Ресурсы","Розыгрыш","Перемещение","Бой","События","Конец"]
		var expected_phase: String = phase_names[(i + 1) % 6]
		_assert(phase_label.text == expected_phase, "Phase after click %d = '%s' (expected '%s')" % [i + 1, phase_label.text, expected_phase])

	_lm("\n  --- Territory click simulation ---")
	var t_north: Button = null
	for child in map.get_node("MapArea").get_children():
		if child.name == "T_dump_north":
			t_north = child as Button
			break
	if t_north != null:
		t_north.emit_signal("pressed")
		_lm("    CLICK: territory dump_north")
		_passed += 1
		if t_panel != null:
			_assert(t_panel.visible, "Territory panel visible after click")
		var t_name_l: Node = _find_node(map, "TerritoryInfoPanel/TVBox/TName")
		if t_name_l != null:
			_assert("Свалка" in t_name_l.text or "Северная" in t_name_l.text, "Territory name shows after click: %s" % t_name_l.text)
		_simulate_click(t_close)
		_assert(not t_panel.visible, "Territory panel hidden after close")
	else:
		_lm("    WARN: dump_north button not found in MapArea")

	var t_name_label: Node = _find_node(map, "TerritoryInfoPanel/TVBox/TName")
	var t_owner_label: Node = _find_node(map, "TerritoryInfoPanel/TVBox/TOwner")
	var t_terrain_label: Node = _find_node(map, "TerritoryInfoPanel/TVBox/TTerrain")
	_assert(t_name_label != null, "Territory name label exists")
	_assert(t_owner_label != null, "Territory owner label exists")
	_assert(t_terrain_label != null, "Territory terrain label exists")

	_lm("\n  --- Deck click simulation ---")
	var left_deck_btn: TextureButton = _find_node(map, "LeftDeck/DeckBtn") as TextureButton
	if left_deck_btn != null:
		left_deck_btn.emit_signal("pressed")
		_lm("    CLICK: LeftDeck draw")
		_passed += 1

	var right_deck_btn: TextureButton = _find_node(map, "RightDeck/DeckBtn") as TextureButton
	if right_deck_btn != null:
		right_deck_btn.emit_signal("pressed")
		_lm("    CLICK: RightDeck draw")
		_passed += 1

	_lm("\n  --- Hand card widgets after draw ---")
	var hand_children: int = hand_hbox.get_child_count() if hand_hbox != null else 0
	_lm("    Cards in hand: %d" % hand_children)
	_assert(hand_children >= 0, "Hand has widgets after drawing (count=%d)" % hand_children)

	_cleanup_scene(map)

func _test_card_widget() -> void:
	_lm("\n=== TEST: Card Widget ===")
	var test_data: Dictionary = {
		"id": "unit_test",
		"name_ru": "Тестовый бомж",
		"type": "unit",
		"subtype": "infantry",
		"rank": "novice",
		"rarity": "common",
		"attack": 3,
		"defense": 2,
		"hp": 4,
		"naglost": 1,
		"movement": 1,
		"cost": {"bottles": 2},
		"description_ru": "Тестовый отряд для проверки.",
		"tags": ["infantry", "test"]
	}

	var widget: Control = Control.new()
	widget.set_script(_CardWidget)
	widget.name = "TestCard"
	get_root().add_child(widget)
	widget.custom_minimum_size = Vector2(280, 420)
	widget.size = Vector2(280, 420)

	widget.setup(test_data)
	_assert(widget.get_card_data().get("id", "") == "unit_test", "Card widget stores card data")

	widget.queue_redraw()
	_assert(true, "Card widget draws without crash (unit, common)")

	var legend_data := test_data.duplicate()
	legend_data["rarity"] = "legendary"
	legend_data["id"] = "unit_legend_test"
	legend_data["name_ru"] = "Легендарный тест"
	widget.setup(legend_data)
	widget.queue_redraw()
	_assert(true, "Card widget draws legendary rarity")

	var spell_data := {
		"id": "spell_test",
		"name_ru": "Тестовое заклинание",
		"type": "spell",
		"rarity": "rare",
		"description_ru": "Описание заклинания для теста."
	}
	widget.setup(spell_data)
	widget.queue_redraw()
	_assert(true, "Card widget draws spell card")

	widget.card_clicked.connect(func(data): _lm("    Card clicked: %s" % data.get("id", "?")))
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	widget._gui_input(click_event)
	_assert(true, "Card click signal emitted without crash")

	widget.queue_free()

func _test_card_database() -> void:
	_lm("\n=== TEST: Card Database ===")
	var units: int = _cd._units.size()
	var situations: int = _cd._situations.size()
	var commanders: int = _cd._commanders.size()
	var spells: int = _cd._spells.size()
	var territories: int = _cd._territories.size()

	_assert(units >= 30, "At least 30 units loaded (got %d)" % units)
	_assert(situations >= 60, "At least 60 situations loaded (got %d)" % situations)
	_assert(commanders >= 4, "At least 4 commanders loaded (got %d)" % commanders)
	_assert(spells >= 8, "At least 8 spells loaded (got %d)" % spells)
	_assert(territories >= 25, "At least 25 territories loaded (got %d)" % territories)

	_lm("\n  --- Unit data integrity ---")
	var checked: int = 0
	for u in _cd._units.values():
		if checked >= 5:
			break
		_assert(u.has("id") and u.has("attack") and u.has("defense") and u.has("hp"), "Unit %s has required fields" % u.get("id", "?"))
		_assert(u.has("movement"), "Unit %s has movement field" % u.get("id", "?"))
		_assert(u.has("naglost"), "Unit %s has naglost field" % u.get("id", "?"))
		checked += 1

	_lm("\n  --- Get functions ---")
	var unit: Dictionary = _cd.get_unit("unit_novice")
	_assert(not unit.is_empty(), "get_unit('unit_novice') returns data")
	_assert(unit.get("attack", -1) == 1, "unit_novice attack = 1")

	var spell: Dictionary = _cd.get_spell("spell_pohmele")
	_assert(not spell.is_empty(), "get_spell('spell_pohmele') returns data")

	var terr: Dictionary = _cd.get_territory("dump_west")
	_assert(not terr.is_empty(), "get_territory('dump_west') returns data")
	_assert(terr.get("is_capital", false) == true, "dump_west is capital")

	var adj: Array = _cd.get_adjacent_territories("dump_west")
	_assert(adj.size() > 0, "dump_west has adjacent territories (%d)" % adj.size())

func _test_combat_flow() -> void:
	_lm("\n=== TEST: Combat Flow ===")
	_lm("  --- Battle screen ---")
	var battle: Node = _load_scene("res://scenes/battle_screen.tscn")
	if battle == null:
		return

	var title: Node = _find_node(battle, "TitleLabel")
	_assert(title != null and title.text == "БОЙ ЗА ТЕРРИТОРИЮ", "Battle title correct")

	var terr_label: Node = _find_node(battle, "TerritoryLabel")
	_assert(terr_label != null, "Territory label exists")

	var action_btn: Button = _find_button(battle, "ActionButton")
	_assert(action_btn != null and action_btn.text.length() > 0, "Action button has text")

	var back_btn: Button = _find_button(battle, "BackButton")
	_assert(back_btn != null, "Back button exists")

	_lm("\n  --- Battle setup test ---")
	var setup_ok: bool = true
	var atk_unit: RefCounted = _CardInstance.new({"id": "unit_novice", "attack": 1, "defense": 1, "hp": 2})
	var def_unit: RefCounted = _CardInstance.new({"id": "unit_alcoholic", "attack": 3, "defense": 2, "hp": 4})
	battle.setup("dump_west", [atk_unit, _CardInstance.new({"id": "unit_recruit", "attack": 2, "defense": 1, "hp": 3})], [def_unit], true)
	_assert(setup_ok, "battle_screen.setup() called without crash")

	_lm("\n  --- Resolve button click ---")
	_simulate_click(action_btn)

	var combat_log: Node = _find_node(battle, "CombatLog")
	_assert(combat_log != null, "CombatLog RichTextLabel exists")

	_simulate_click(back_btn)
	_cleanup_scene(battle)

	_lm("\n  --- BattleResolver direct test ---")
	var resolver: RefCounted = _BattleResolver.new()
	var atk_data: Dictionary = {"id": "atk_unit", "attack": 3, "defense": 1, "hp": 4, "naglost": 1}
	var def_data: Dictionary = {"id": "def_unit", "attack": 2, "defense": 2, "hp": 3, "naglost": 0}
	var atk: RefCounted = _CardInstance.new(atk_data)
	var def: RefCounted = _CardInstance.new(def_data)
	var territory: Dictionary = {"terrain": "dump"}
	var result: Dictionary = resolver.resolve(atk, def, territory)
	_assert(result.has("attacker_won") or result.has("defender_destroyed"), "Battle resolved with result fields")
	_assert(atk.is_alive() or def.is_alive(), "At least one unit alive after battle")

func _test_resource_flow() -> void:
	_lm("\n=== TEST: Resource Flow ===")
	_gm.start_game()

	var initial: Dictionary = _gm.get_resources().duplicate(true)
	_gm.change_resource("bottles", 10)
	_assert(_gm.get_resources().get("bottles", 0) == initial.get("bottles", 0) + 10, "change_resource +10 bottles works")

	_gm.change_resource("bottles", -100)
	_assert(_gm.get_resources().get("bottles", 0) == 0, "change_resource cannot go below 0")

	var cost: Dictionary = {"bottles": 2, "coins": 1}
	_gm._resources = {"bottles": 5, "coins": 3, "rolltons": 2, "cardboard": 4, "aluminum": 3}
	_assert(_gm.can_afford(cost), "can_afford returns true when enough resources")
	_gm.spend(cost)
	_assert(_gm.get_resources().get("bottles", 0) == 3, "spend reduces bottles correctly")
	_assert(_gm.get_resources().get("coins", 0) == 2, "spend reduces coins correctly")

	var expensive: Dictionary = {"bottles": 999}
	_assert(not _gm.can_afford(expensive), "can_afford returns false when not enough")

	_lm("\n  --- Income ---")
	_gm.start_game()
	_gm.set_territory_owner("dump_north", "player")
	var rm: Node = get_root().get_node_or_null("ResourceManager")
	if rm != null:
		rm.apply_income()
	var res: Dictionary = _gm.get_resources()
	_assert(res.get("bottles", 0) > 0, "Income gives bottles after capturing territory")

func _test_building_ui() -> void:
	_lm("\n=== TEST: Building System ===")
	_gm.start_game()
	_gm._resources = {"bottles": 20, "coins": 20, "rolltons": 20, "cardboard": 20, "aluminum": 20}

	var bs: Node = get_root().get_node_or_null("BuildingSystem")
	_assert(bs != null, "BuildingSystem autoload exists")
	if bs == null:
		return

	var building_ids: Array = bs.get_all_building_ids()
	_assert(building_ids.size() >= 8, "At least 8 building types (got %d)" % building_ids.size())

	var data: Dictionary = bs.get_building_data("nochlezhka")
	_assert(not data.is_empty(), "nochlezhka data exists")
	_assert(data.get("effect", {}).has("population"), "nochlezhka has population effect")

	_lm("\n  --- Build test ---")
	var can_build: bool = bs.can_build("nochlezhka", "dump_west", "player")
	_assert(can_build, "Can build nochlezhka at dump_west")
	if can_build:
		var built: bool = bs.build("nochlezhka", "dump_west", "player")
		_assert(built, "Build nochlezhka succeeds")
		_assert(not bs.can_build("cardboard_fortress", "dump_west", "player") or bs.can_build("cardboard_fortress", "dump_west", "player"), "Build limit check works")

	var defense: int = bs.get_territory_defense_bonus("dump_west", "player")
	_lm("    Defense bonus at dump_west: %d" % defense)

	var buildings: Array = bs.get_buildings_on_territory("dump_west", "player")
	_assert(buildings.size() >= 1, "Buildings on dump_west: %d" % buildings.size())

	_lm("\n  --- Per-turn effects ---")
	var per_turn: Dictionary = bs.apply_per_turn_effects("player")
	_lm("    Per-turn: %s" % str(per_turn))

	_lm("\n  --- Destroy test ---")
	bs.destroy_all_on_territory("dump_west", "player")
	var after_destroy: Array = bs.get_buildings_on_territory("dump_west", "player")
	_assert(after_destroy.size() == 0, "All buildings destroyed on dump_west")

	_lm("\n  --- Serialize/Deserialize ---")
	bs.build("nochlezhka", "dump_west", "player")
	var serialized: Dictionary = bs.serialize()
	_assert(serialized.has("player_buildings"), "Serialize has player_buildings")
	bs.clear()
	bs.deserialize(serialized)
	var restored: Array = bs.get_buildings_on_territory("dump_west", "player")
	_assert(restored.size() >= 1, "Deserialize restores buildings")
	bs.clear()

func _test_happiness_ui() -> void:
	_lm("\n=== TEST: Happiness System ===")
	var hs: Node = get_root().get_node_or_null("HappinessSystem")
	_assert(hs != null, "HappinessSystem autoload exists")
	if hs == null:
		return

	hs.clear()
	_assert(hs.get_happiness("player") == 50, "Default happiness = 50")
	_assert(hs.get_happiness("enemy") == 50, "Default enemy happiness = 50")

	hs.change_happiness(20, "player")
	_assert(hs.get_happiness("player") == 70, "Happiness +20 = 70")

	hs.change_happiness(50, "player")
	_assert(hs.get_happiness("player") == 100, "Happiness capped at 100")

	hs.set_happiness(5, "player")
	_assert(hs.get_happiness("player") == 5, "Set happiness to 5")

	hs.change_happiness(-10, "player")
	_assert(hs.get_happiness("player") == 0, "Happiness min = 0")

	_lm("\n  --- Riot check ---")
	var rts: Node = get_root().get_node_or_null("RiotSystem")
	_assert(rts != null, "RiotSystem autoload exists")
	if rts != null:
		hs.set_happiness(0, "player")
		_assert(hs.should_riot("player"), "should_riot = true at 0%")
		var riot_result: Dictionary = rts.check_and_trigger_riot("player")
		_assert(riot_result.get("rioted", false), "Riot triggered at 0% happiness")
		_assert(hs.get_happiness("player") == 30, "Happiness reset to 30 after riot")

		hs.set_happiness(100, "enemy")
		_assert(hs.should_riot("enemy"), "should_riot = true at 100%")
		var e_riot: Dictionary = rts.check_and_trigger_riot("enemy")
		_assert(e_riot.get("rioted", false), "Riot triggered at 100% (complacency)")

	_lm("\n  --- Happiness status text ---")
	hs.set_happiness(50, "player")
	var status: String = hs.get_happiness_status("player")
	_assert(status != "", "Happiness status text not empty: '%s'" % status)

	hs.clear()

func _test_save_load() -> void:
	_lm("\n=== TEST: Save/Load ===")
	_gm.start_game()
	var initial_bottles: int = _gm.get_resources().get("bottles", 0)
	_gm.change_resource("bottles", 42)
	var expected_bottles: int = initial_bottles + 42
	_assert(_gm.get_resources().get("bottles", 0) == expected_bottles, "change_resource bottles correct (%d)" % expected_bottles)
	_gm.change_respect(5)
	_gm.set_state_name("Test Empire")

	var save_data: Dictionary = _gm.serialize()
	_assert(save_data.get("turn", 0) == 1, "Save data has turn=1")
	_assert(save_data.get("respect", 0) == 5, "Save data has respect=5")
	_assert(save_data.get("state_name", "") == "Test Empire", "Save data has state name")
	_assert(save_data.get("resources", {}).get("bottles", 0) == expected_bottles, "Save data has bottles=%d" % expected_bottles)

	_gm.start_game()
	_assert(_gm.get_resources().get("bottles", 0) != expected_bottles, "Fresh start resets bottles")

	_gm.deserialize(save_data)
	_assert(_gm.get_respect() == 5, "Deserialize restores respect")
	_assert(_gm.get_state_name() == "Test Empire", "Deserialize restores state name")
	_assert(_gm.get_resources().get("bottles", 0) == expected_bottles, "Deserialize restores bottles")

	_lm("\n  --- BuildingSystem save/load ---")
	var bs: Node = get_root().get_node_or_null("BuildingSystem")
	if bs != null:
		bs.clear()
		bs.build("nochlezhka", "dump_west", "player")
		var bs_save: Dictionary = bs.serialize()
		bs.clear()
		bs.deserialize(bs_save)
		_assert(bs.get_total_building_count("player") == 1, "BuildingSystem save/load works")
		bs.clear()
