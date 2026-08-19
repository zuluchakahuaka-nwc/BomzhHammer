extends SceneTree

var _gm: Variant = null
var _cd: Variant = null
var _passed: int = 0
var _errors: int = 0
var _ready: bool = false

func _init() -> void:
	print("ATTACK_CLICK_TEST: _init")

func _process(_delta: float) -> bool:
	if _ready:
		return false
	var root_node: Node = get_root()
	if root_node == null:
		return false
	_gm = root_node.get_node_or_null("GameManager")
	_cd = root_node.get_node_or_null("CardDatabase")
	if _gm == null or _cd == null:
		return false
	_ready = true
	_run_all()
	return false

func _log(msg: String) -> void:
	print(msg)

func _ok(condition: bool, desc: String) -> void:
	if condition:
		_passed += 1
	else:
		_errors += 1
		_log("  FAIL: " + desc)

func _run_all() -> void:
	_log("=== ATTACK CLICK TEST (5 ROUNDS) ===")
	_test_adjacency()
	for round_num in range(1, 6):
		_test_attack_round(round_num)
	_log("")
	_log("PASSED: %d | ERRORS: %d" % [_passed, _errors])
	_log("=== END ===")
	quit()

func _test_adjacency() -> void:
	_log("--- Adjacency Data ---")
	var checks := {
		"dump_west": ["den_basman", "street_west", "dumpster_pharmacy", "street_center"],
		"street_west": ["den_basman", "pereulok_skautov", "dumpster_north", "dacha_area", "ulica_trezvyh"],
		"dumpster_north": ["pereulok_poproshaek", "dacha_area", "ploschad_pelmenistana"],
		"dacha_area": ["pereulok_poproshaek", "dumpster_north", "ulica_trezvyh", "street_west"],
		"dumpster_pharmacy": ["den_basman", "pereulok_skautov", "dump_south", "ulica_pohmelnaya_44"],
	}
	for src in checks:
		var adj: Array = _cd.get_adjacent_territories(src)
		for tgt in checks[src]:
			var has_it: bool = adj.has(tgt)
			_log("  %s -> %s : %s" % [src, tgt, "YES" if has_it else "NO"])
			_ok(has_it, "%s must be adjacent to %s" % [src, tgt])
	_log("  Adjacency: %d passed, %d failed" % [_passed, _errors])

func _make_unit(unit_id: String) -> RefCounted:
	var CIScript = load("res://scripts/cards/card_instance.gd")
	var data: Dictionary = _cd.get_unit(unit_id)
	return CIScript.new(data)

func _create_mock_map() -> Control:
	var mock := Control.new()
	mock.name = "GameMap"
	mock.set("_selected_territory", "")
	mock.set("_player_deployed", {})
	mock.set("_npc_garrisons", {})
	mock.set("_territory_buttons", {})
	mock.set("_placing", false)
	mock.set("_moving", false)
	mock.set("_placing_data", {})
	mock.set("_moving_from", "")
	mock.set("_moving_units", [])
	mock.set("_lm", func(msg): print("  [LOG] " + msg))

	var TMScript = load("res://scripts/ui/map/territory_manager.gd")
	var tm = TMScript.new(mock)
	mock.set("_territory_mgr", tm)

	return mock

func _deploy_units(mock: Control, tid: String, count: int) -> void:
	var deployed: Dictionary = mock.get("_player_deployed")
	if not deployed.has(tid):
		deployed[tid] = []
	for _i in range(count):
		var u = _make_unit("unit_kuzmich")
		u.territory_id = tid
		deployed[tid].append(u)

func _place_npc(mock: Control, tid: String, count: int) -> void:
	var garrisons: Dictionary = mock.get("_npc_garrisons")
	var garrison: Array = []
	for _i in range(count):
		var u = _make_unit("unit_novice")
		u.territory_id = tid
		garrison.append(u)
	garrisons[tid] = garrison

func _test_attack_round(round_num: int) -> void:
	_log("")
	_log("--- Round %d: Full Attack Chain ---" % round_num)
	_gm.start_game()
	_gm.set_territory_owner("dump_west", "player")

	var mock: Control = _create_mock_map()
	var tm = mock.get("_territory_mgr")
	var deployed: Dictionary = mock.get("_player_deployed")
	var garrisons: Dictionary = mock.get("_npc_garrisons")

	_deploy_units(mock, "dump_west", 5)
	_place_npc(mock, "den_basman", 2)
	_place_npc(mock, "pereulok_poproshaek", 2)
	_place_npc(mock, "station_leningradsky", 2)
	_place_npc(mock, "station_kazansky", 2)
	_place_npc(mock, "street_center", 2)

	mock.set("_selected_territory", "dump_west")
	tm.attack_territory("den_basman")
	var owner_db: String = _gm.get_territory_owner("den_basman")
	_log("  R%d.1: dump_west -> den_basman : owner=%s" % [round_num, owner_db])
	_ok(owner_db == "player", "Round %d: captured den_basman from dump_west" % round_num)

	if owner_db == "player":
		_gm.set_territory_owner("den_basman", "player")
		_deploy_units(mock, "den_basman", 5)
		mock.set("_selected_territory", "den_basman")
		tm.attack_territory("pereulok_poproshaek")
		var owner_pp: String = _gm.get_territory_owner("pereulok_poproshaek")
		_log("  R%d.2: den_basman -> pereulok_poproshaek : owner=%s" % [round_num, owner_pp])
		_ok(owner_pp == "player", "Round %d: captured pereulok_poproshaek from den_basman" % round_num)

	if _gm.get_territory_owner("pereulok_poproshaek") == "player":
		_gm.set_territory_owner("pereulok_poproshaek", "player")
		_deploy_units(mock, "pereulok_poproshaek", 5)
		mock.set("_selected_territory", "pereulok_poproshaek")
		tm.attack_territory("station_leningradsky")
		var owner_sl: String = _gm.get_territory_owner("station_leningradsky")
		_log("  R%d.3: pereulok_poproshaek -> station_leningradsky : owner=%s" % [round_num, owner_sl])
		_ok(owner_sl == "player", "Round %d: captured station_leningradsky" % round_num)

	_gm.set_territory_owner("street_west", "player")
	_deploy_units(mock, "street_west", 5)
	mock.set("_selected_territory", "street_west")
	tm.attack_territory("den_basman")
	_log("  R%d.4: street_west -> den_basman : owner=%s" % [round_num, _gm.get_territory_owner("den_basman")])
	_ok(_gm.get_territory_owner("den_basman") == "player", "Round %d: street_west reaches den_basman" % round_num)

	_gm.set_territory_owner("dumpster_north", "player")
	_deploy_units(mock, "dumpster_north", 5)
	mock.set("_selected_territory", "dumpster_north")
	tm.attack_territory("pereulok_poproshaek")
	_log("  R%d.5: dumpster_north -> pereulok_poproshaek : owner=%s" % [round_num, _gm.get_territory_owner("pereulok_poproshaek")])
	_ok(_gm.get_territory_owner("pereulok_poproshaek") == "player", "Round %d: dumpster_north reaches pereulok_poproshaek" % round_num)

	_gm.set_territory_owner("dacha_area", "player")
	_deploy_units(mock, "dacha_area", 5)
	mock.set("_selected_territory", "dacha_area")
	tm.attack_territory("pereulok_poproshaek")
	_log("  R%d.6: dacha_area -> pereulok_poproshaek : owner=%s" % [round_num, _gm.get_territory_owner("pereulok_poproshaek")])
	_ok(_gm.get_territory_owner("pereulok_poproshaek") == "player", "Round %d: dacha_area reaches pereulok_poproshaek" % round_num)

	_gm.set_territory_owner("dumpster_pharmacy", "player")
	_deploy_units(mock, "dumpster_pharmacy", 5)
	mock.set("_selected_territory", "dumpster_pharmacy")
	tm.attack_territory("den_basman")
	_log("  R%d.7: dumpster_pharmacy -> den_basman : owner=%s" % [round_num, _gm.get_territory_owner("den_basman")])
	_ok(_gm.get_territory_owner("den_basman") == "player", "Round %d: dumpster_pharmacy reaches den_basman" % round_num)

	mock.free()
