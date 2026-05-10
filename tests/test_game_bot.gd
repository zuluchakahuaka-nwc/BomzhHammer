extends SceneTree

var _log: String = ""
var _errors: int = 0
var _passed: int = 0
var _gm: Variant = null
var _cd: Variant = null
var _rm: Variant = null
var _rs: Variant = null
var _ready_done: bool = false

var _is: Variant = null

func _init() -> void:
	_log = ""
	print("GAME BOT: _init called")

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	if _gm == null:
		_try_init()
		return false
	_ready_done = true
	_run_tests()
	return false

func _try_init() -> void:
	var root_node: Node = get_root()
	if root_node == null:
		return
	_gm = root_node.get_node_or_null("GameManager")
	_cd = root_node.get_node_or_null("CardDatabase")
	_rm = root_node.get_node_or_null("ResourceManager")
	_rs = root_node.get_node_or_null("ReligionSystem")
	_is = root_node.get_node_or_null("IdeologySystem")

func _run_tests() -> void:
	_log_msg("=== GAME BOT TEST START ===")
	_test_turn_manager_init()
	_test_resource_phase()
	_test_draw_phase()
	_test_management_deploy()
	_test_combat_forced()
	_test_naglost_mechanic()
	_test_territory_capture()
	_test_resource_display()
	_test_naming_turn2()
	_test_religion_at_3_territories()
	_test_religion_mnogobomzhie_bonus()
	_test_religion_alcoteism_bonus()
	_test_religion_etanolstvo_bonus()
	_test_state_name_cycling()
	_test_ideology_at_5_territories()
	_test_alcoholism_bonus_draw()
	_test_dermocracy_bonus_coins()
	_test_buyout_territory()
	_test_full_game_loop(3)
	_log_msg("")
	_log_msg("PASSED: %d | ERRORS: %d" % [_passed, _errors])
	_log_msg("=== GAME BOT TEST END ===")
	var file := FileAccess.open("user://bot_test_log.txt", FileAccess.WRITE)
	if file:
		file.store_string(_log)
		file.close()
	quit()

func _log_msg(msg: String) -> void:
	_log += msg + "\n"
	print(msg)

func _assert(condition: bool, desc: String) -> void:
	if condition:
		_passed += 1
	else:
		_errors += 1
		_log_msg("  FAIL: %s" % desc)

func _make_tm() -> RefCounted:
	var TMS: GDScript = load("res://scripts/core/turn_manager.gd")
	return TMS.new()

func _make_unit(unit_id: String) -> CardInstance:
	var data: Dictionary = _cd.get_unit(unit_id)
	return CardInstance.new(data)

func _make_territory_data(tid: String) -> Dictionary:
	return _cd.get_territory(tid)

func _give_player_resources() -> void:
	_gm.change_resource("bottles", 50)
	_gm.change_resource("aluminum", 50)
	_gm.change_resource("coins", 50)
	_gm.change_resource("rolltons", 50)
	_gm.change_resource("cardboard", 50)

func _give_enemy_resources() -> void:
	_gm.change_enemy_resource("bottles", 50)
	_gm.change_enemy_resource("aluminum", 50)
	_gm.change_enemy_resource("coins", 50)
	_gm.change_enemy_resource("rolltons", 50)
	_gm.change_enemy_resource("cardboard", 50)

# ========================================
func _test_turn_manager_init() -> void:
	_log_msg("--- TurnManager Init ---")
	var tm: RefCounted = _make_tm()
	_assert(tm != null, "TurnManager created")
	tm.new_game()
	_assert(_gm.get_current_turn() == 1, "Turn=1 after new_game")
	_assert(_gm.get_ideology() == "", "Ideology not set at start")
	_assert(tm.get_player_deployed().size() == 0, "No deployed at start")
	_assert(not tm.is_religion_pending(), "Religion not pending at start")
	_assert(not tm.is_naming_pending(), "Naming not pending at start")
	_log_msg("  OK")

# ========================================
func _test_resource_phase() -> void:
	_log_msg("--- Resource Phase ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	_gm.set_territory_owner("dump_west", "player")

	var res_before: Dictionary = _gm.get_resources().duplicate(true)
	var result: Dictionary = tm.execute_resource_phase()
	_log_msg("  Income: %s" % str(result.get("player_income", {})))

	_assert(_gm.get_resources().get("bottles", 0) > res_before.get("bottles", 0), "Bottles increased from territory")
	_log_msg("  OK")

# ========================================
func _test_draw_phase() -> void:
	_log_msg("--- Draw Phase ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()

	var result: Dictionary = tm.execute_draw_phase()
	_assert(result.get("player_drawn", 0) > 0, "Player drew %d" % result.get("player_drawn", 0))
	_assert(result.get("enemy_drawn", 0) > 0, "Enemy drew %d" % result.get("enemy_drawn", 0))

	var ph: RefCounted = tm.get_player_hand()
	_assert(ph.size() > 0, "Hand not empty")
	_log_msg("  OK")

# ========================================
func _test_management_deploy() -> void:
	_log_msg("--- Management: Deploy & Move ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	_give_player_resources()
	_give_enemy_resources()
	tm.execute_resource_phase()
	tm.execute_draw_phase()

	var result: Dictionary = tm.execute_management_phase()
	_log_msg("  Deployed: %d, Moved: %d" % [result.get("deployed", 0), result.get("moved", 0)])
	_assert(result.has("deployed"), "Management result has deployed")
	_log_msg("  OK")

# ========================================
func _test_combat_forced() -> void:
	_log_msg("--- Combat: Forced Battle ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()

	var attacker: CardInstance = _make_unit("unit_recruit")
	var defender: CardInstance = _make_unit("unit_novice")
	attacker.territory_id = "street_center"
	defender.territory_id = "street_center"

	tm.get_player_deployed()["street_center"] = [attacker]
	tm.get_enemy_deployed()["street_center"] = [defender]

	var result: Dictionary = tm.execute_combat_phase()
	_log_msg("  Battles: %d, P wins: %d, E wins: %d" % [
		result.get("battles", 0), result.get("player_wins", 0), result.get("enemy_wins", 0)])

	_assert(result.get("battles", 0) >= 1, "At least 1 battle")
	_assert(not attacker.is_alive() or not defender.is_alive(), "Someone died")
	var owner: String = _gm.get_territory_owner("street_center")
	_assert(owner == "player" or owner == "enemy", "Territory captured")
	_log_msg("  OK")

# ========================================
func _test_naglost_mechanic() -> void:
	_log_msg("--- Naglost Mechanic ---")
	var resolver := BattleResolver.new()

	var attacker: CardInstance = _make_unit("unit_chunga_changa")
	var defender: CardInstance = _make_unit("unit_novice")
	attacker.max_hp = 100
	attacker.current_hp = 100
	defender.max_hp = 100
	defender.current_hp = 100

	_assert(attacker.naglost == 5, "Chunga-Changa naglost=5")

	var total_naglost_hits := 0
	var total_rounds := 0
	for trial in range(20):
		attacker.current_hp = 100
		defender.current_hp = 100
		var result: Dictionary = resolver.resolve(attacker, defender, _make_territory_data("street_center"))
		for r in result.get("rounds", []):
			total_rounds += 1
			if r.get("naglost_bonus", 0) > 0:
				total_naglost_hits += 1

	_log_msg("  Naglost hits: %d / %d rounds" % [total_naglost_hits, total_rounds])
	_assert(total_rounds > 0, "Rounds happened")
	if total_rounds > 0:
		var ratio: float = float(total_naglost_hits) / float(total_rounds)
		_assert(ratio > 0.05 and ratio < 0.45, "Naglost ratio: %.2f" % ratio)

	_assert(_make_unit("unit_novice").naglost == 0, "Novice naglost=0")
	_log_msg("  OK")

# ========================================
func _test_territory_capture() -> void:
	_log_msg("--- Territory Capture ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()

	_assert(_gm.get_territory_owner("street_center") == "neutral", "street_center neutral at start")

	var strong: CardInstance = _make_unit("unit_kuzmich")
	strong.territory_id = "street_center"
	tm.get_player_deployed()["street_center"] = [strong]

	tm.execute_combat_phase()
	_assert(_gm.get_territory_owner("street_center") == "player", "Player captured street_center")
	_log_msg("  OK")

# ========================================
func _test_resource_display() -> void:
	_log_msg("--- Resource Display: Income per Turn ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("TestState")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("street_west", "player")
	_gm.set_territory_owner("den_basman", "player")

	_rm.apply_income()

	var display: Dictionary = _rm.get_resource_display()
	_log_msg("  Display: %s" % str(display))

	_assert(display.has("aluminum"), "Display has aluminum")
	_assert(display.has("aluminum_income"), "Display has aluminum_income")
	_assert(display.get("aluminum", 0) > 0, "Aluminum stock > 0")
	_assert(display.get("aluminum_income", 0) > 0, "Aluminum income > 0 (got %d)" % display.get("aluminum_income", 0))

	var formatted: Dictionary = _rm.get_formatted_display()
	_log_msg("  Formatted:")
	for res_key in formatted:
		_log_msg("    %s" % formatted[res_key])

	var alu_line: String = formatted.get("aluminum", "")
	_assert(alu_line.find("Алюминь") >= 0, "Aluminum line starts with name")
	_assert(alu_line.find("(+") >= 0 or alu_line.find("(-") >= 0 or display.get("aluminum_income", 0) == 0, "Income shown in format")

	_rs.set_religion("alcoteism")
	var display2: Dictionary = _rm.get_resource_display()
	_log_msg("  With Alcoteism: coins=%d coins_income=%d" % [display2.coins, display2.coins_income])
	_log_msg("  OK")

# ========================================
func _test_naming_turn2() -> void:
	_log_msg("--- Naming: Turn 2 ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()

	var r1: Dictionary = tm.execute_resource_phase()
	_assert(not r1.get("naming_pending", false), "No naming on turn 1")

	tm.execute_draw_phase()
	tm.execute_management_phase()
	tm.execute_combat_phase()
	tm.execute_events_phase()
	tm.execute_end_phase()

	_assert(tm.get_current_turn() == 2, "Turn 2 after first end phase")

	var r2: Dictionary = tm.execute_resource_phase()
	_assert(r2.get("naming_pending", false), "Naming pending on turn 2")
	_assert(tm.is_naming_pending(), "is_naming_pending=true")

	var suggestion: String = tm.get_current_name_suggestion()
	_log_msg("  Suggestion: %s" % suggestion)
	_assert(suggestion == "Пьяная Империя", "First suggestion = Пьяная Империя")

	tm.choose_state_name("Княжество Тестовое")
	_assert(not tm.is_naming_pending(), "Naming resolved after choice")
	_assert(_gm.get_state_name() == "Княжество Тестовое", "State name set")
	_assert(_gm.is_state_named(), "is_state_named=true")
	_log_msg("  OK")

# ========================================
func _test_religion_at_3_territories() -> void:
	_log_msg("--- Religion: Trigger at 3 Territories ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Тестландия")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("street_west", "player")
	_assert(_gm.get_player_territory_count() == 2, "2 territories")

	tm.execute_resource_phase()
	tm.execute_draw_phase()
	tm.execute_management_phase()

	_assert(not tm.is_religion_pending(), "No religion at 2 territories")

	var u: CardInstance = _make_unit("unit_recruit")
	u.territory_id = "street_center"
	tm.get_player_deployed()["street_center"] = [u]

	tm.execute_combat_phase()
	_assert(_gm.get_player_territory_count() >= 3, "3+ territories after capture")
	_assert(tm.is_religion_pending(), "Religion pending at 3 territories")

	var choices: Array = tm.get_religion_choices()
	_assert(choices.size() == 4, "4 religion choices")
	_log_msg("  Choices: %s" % str(choices))

	tm.choose_religion("mnogobomzhie")
	_assert(not tm.is_religion_pending(), "Religion resolved")
	_assert(_gm.is_religion_chosen(), "is_religion_chosen=true")
	_assert(_rs.get_religion() == "mnogobomzhie", "Religion=mnogobomzhie")
	_log_msg("  OK")

# ========================================
func _test_religion_mnogobomzhie_bonus() -> void:
	_log_msg("--- Religion: Mnogobomzhie Attack +1 ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")
	_rs.set_religion("mnogobomzhie")

	var u: CardInstance = _make_unit("unit_recruit")
	var base_atk: int = u.attack
	var eff_atk: int = u.get_effective_attack()
	_log_msg("  Recruit: base=%d effective=%d" % [base_atk, eff_atk])
	_assert(eff_atk == base_atk + 1, "Mnogobomzhie: attack +1 (base=%d eff=%d)" % [base_atk, eff_atk])
	_log_msg("  OK")

# ========================================
func _test_religion_alcoteism_bonus() -> void:
	_log_msg("--- Religion: Alcoteism Coins +2/territory ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")
	_rs.set_religion("alcoteism")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("street_west", "player")
	_gm.set_territory_owner("street_center", "player")

	var income: Dictionary = _rm.calculate_income()
	var p_count: int = _gm.get_player_territory_count()
	_log_msg("  Income with %d territories: %s" % [p_count, str(income)])
	_assert(income.get("coins", 0) >= p_count * 2, "Alcoteism: coins >= %d (got %d)" % [p_count * 2, income.get("coins", 0)])
	_log_msg("  OK")

# ========================================
func _test_religion_etanolstvo_bonus() -> void:
	_log_msg("--- Religion: Etanolstvo Resources +1/territory ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")
	_rs.set_religion("etanolstvo")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("street_west", "player")

	var income: Dictionary = _rm.calculate_income()
	var p_count: int = _gm.get_player_territory_count()
	_log_msg("  Income with %d territories: %s" % [p_count, str(income)])
	_assert(income.get("aluminum", 0) >= p_count * 1, "Etanolstvo: aluminum bonus")
	_assert(income.get("bottles", 0) >= p_count * 1, "Etanolstvo: bottles bonus")
	_assert(income.get("cardboard", 0) >= p_count * 1, "Etanolstvo: cardboard bonus")
	_log_msg("  OK")

# ========================================
func _test_state_name_cycling() -> void:
	_log_msg("--- State Name Cycling ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()

	var names: Array = tm.get_state_names()
	_assert(names.size() == 7, "7 suggested names")

	var first: String = tm.get_current_name_suggestion()
	_assert(first == "Пьяная Империя", "First: Пьяная Империя")

	var second: String = tm.get_next_name_suggestion()
	_assert(second == "Страна Ветров и Перегара", "Second: Страна Ветров")

	var third: String = tm.get_next_name_suggestion()
	_assert(third == "Княжество Стакания", "Third: Княжество Стакания")

	for i in range(10):
		tm.get_next_name_suggestion()
	var wrapped: String = tm.get_current_name_suggestion()
	_log_msg("  After cycling: %s" % wrapped)
	_assert(wrapped != "", "Name cycling works")

	tm.choose_state_name("Моё Государство")
	_assert(_gm.get_state_name() == "Моё Государство", "Custom name accepted")
	_log_msg("  OK")

# ========================================
func _test_ideology_at_5_territories() -> void:
	_log_msg("--- Ideology: Trigger at 5 Territories ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Тестландия")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("street_west", "player")
	_gm.set_territory_owner("street_center", "player")
	_gm.set_territory_owner("den_basman", "player")
	_assert(_gm.get_player_territory_count() == 4, "4 territories")

	_assert(not tm.is_ideology_pending(), "No ideology at 4 territories")

	_gm.set_territory_owner("dumpster_north", "player")
	_assert(_gm.get_player_territory_count() == 5, "5 territories")

	var u: CardInstance = _make_unit("unit_recruit")
	u.territory_id = "dump_north"
	tm.get_player_deployed()["dump_north"] = [u]
	tm.execute_combat_phase()

	_assert(_gm.get_player_territory_count() >= 5, "5+ territories after combat")
	_assert(tm.is_ideology_pending(), "Ideology pending at 5 territories")

	tm.choose_ideology("alcoholism")
	_assert(not tm.is_ideology_pending(), "Ideology resolved")
	_assert(_gm.is_ideology_chosen(), "is_ideology_chosen=true")
	_assert(_gm.get_ideology() == "alcoholism", "Ideology=alcoholism")
	_assert(_is.get_ideology() == "alcoholism", "IdeologySystem=alcoholism")
	_log_msg("  OK")

# ========================================
func _test_alcoholism_bonus_draw() -> void:
	_log_msg("--- Alcoholism: +1 Unit Card Draw ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")
	_gm.choose_ideology("alcoholism")

	_assert(_is.get_extra_unit_draw() == 1, "Extra unit draw = 1")

	_give_player_resources()
	tm.execute_resource_phase()

	var right_before: int = tm.get_player_hand().size()
	var r: Dictionary = tm.execute_draw_phase()
	_log_msg("  Drawn: %d, hand size: %d" % [r.get("player_drawn", 0), tm.get_player_hand().size()])

	var units_in_hand: int = 0
	for card in tm.get_player_hand().get_all():
		if card.get("type", "") == "unit" or card.get("type", "") == "commander":
			units_in_hand += 1
	_log_msg("  Units in hand: %d" % units_in_hand)
	_assert(r.get("player_drawn", 0) >= 3, "Drew at least 3 cards with alcoholism (3 left + 3 right)")
	_log_msg("  OK")

# ========================================
func _test_dermocracy_bonus_coins() -> void:
	_log_msg("--- Dermocracy: +25% Coins ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")
	_gm.choose_ideology("dermocracy")

	_gm.set_territory_owner("dump_west", "player")
	_gm.set_territory_owner("station_kazansky", "player")
	_gm.set_territory_owner("street_center", "player")

	var income: Dictionary = _rm.calculate_income()
	_log_msg("  Income with dermocracy: %s" % str(income))

	var base_coins: int = 0
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == "player":
			var t: Dictionary = _cd.get_territory(t_id)
			base_coins += t.get("resource_coins", 0)
	_log_msg("  Base coins: %d, Modified coins: %d" % [base_coins, income.get("coins", 0)])
	_assert(income.get("coins", 0) > base_coins, "Dermocracy coins > base coins (+25%%)")
	_log_msg("  OK")

# ========================================
func _test_buyout_territory() -> void:
	_log_msg("--- Buyout Territory ---")
	var tm: RefCounted = _make_tm()
	tm.new_game()
	tm.choose_state_name("Test")

	_assert(_gm.get_territory_owner("street_center") == "neutral", "street_center neutral")

	_gm.change_resource("coins", 100)
	var coins_before: int = _gm.get_resources().get("coins", 0)
	_assert(_gm.can_buyout_territory("street_center"), "Can buyout street_center")

	var success: bool = _gm.buyout_territory("street_center")
	_assert(success, "Buyout succeeded")
	_assert(_gm.get_territory_owner("street_center") == "player", "Player owns after buyout")
	_assert(_gm.get_resources().get("coins", 0) < coins_before, "Coins spent on buyout")

	_assert(not _gm.can_buyout_territory("dump_west"), "Cannot buyout own territory")
	_gm.set_territory_owner("dump_east", "enemy")
	_assert(not _gm.can_buyout_territory("dump_east"), "Cannot buyout enemy territory")

	_log_msg("  OK")

# ========================================
func _test_full_game_loop(turns: int) -> void:
	_log_msg("--- Full Game Loop x%d ---" % turns)
	var tm: RefCounted = _make_tm()
	tm.new_game()
	_give_player_resources()
	_give_enemy_resources()

	for turn in range(turns):
		var t: int = tm.get_current_turn()
		_log_msg("  TURN %d" % t)

		var r_res: Dictionary = tm.execute_resource_phase()
		_log_msg("    Res: bottles=%d | naming=%s religion=%s ideology=%s" % [
			_gm.get_resources().get("bottles", 0),
			str(r_res.get("naming_pending", false)),
			str(r_res.get("religion_pending", false)),
			str(r_res.get("ideology_pending", false))])

		if tm.is_naming_pending():
			var name: String = tm.get_current_name_suggestion()
			tm.choose_state_name(name)
			_log_msg("    Named: %s" % name)

		var r_draw: Dictionary = tm.execute_draw_phase()
		_log_msg("    Draw: p=%d e=%d" % [r_draw.get("player_drawn", 0), r_draw.get("enemy_drawn", 0)])

		var r_mgmt: Dictionary = tm.execute_management_phase()
		_log_msg("    Mgmt: deploy=%d move=%d p=%d e=%d" % [
			r_mgmt.get("deployed", 0), r_mgmt.get("moved", 0),
			r_mgmt.get("player_units_on_map", 0), r_mgmt.get("enemy_units_on_map", 0)])

		var r_combat: Dictionary = tm.execute_combat_phase()
		_log_msg("    Combat: battles=%d p_w=%d e_w=%d" % [
			r_combat.get("battles", 0), r_combat.get("player_wins", 0), r_combat.get("enemy_wins", 0)])

		if tm.is_ideology_pending():
			tm.choose_ideology("alcoholism")
			_log_msg("    Ideology chosen: alcoholism")

		if tm.is_religion_pending():
			var choices: Array = tm.get_religion_choices()
			var pick: String = choices[turn % choices.size()]["id"]
			tm.choose_religion(pick)
			_log_msg("    Religion chosen: %s" % pick)

		var r_events: Dictionary = tm.execute_events_phase()
		_log_msg("    Events: %d" % r_events.get("count", 0))

		var r_end: Dictionary = tm.execute_end_phase()
		_log_msg("    End: p=%d e=%d pop=%d ideology=%s religion=%s" % [
			r_end.get("player_territories", 0), r_end.get("enemy_territories", 0),
			r_end.get("population", 0), _gm.get_ideology(), _rs.get_religion()])

		_assert(r_end.get("player_territories", 0) >= 1, "Player has territory T%d" % t)

	_assert(_gm.is_state_named(), "State named by end")
	_log_msg("  Final: name=%s ideology=%s religion=%s p=%d e=%d" % [
		_gm.get_state_name(), _gm.get_ideology(), _rs.get_religion(),
		_gm.get_player_territory_count(), _gm.get_enemy_territory_count()])
	_log_msg("  OK")
