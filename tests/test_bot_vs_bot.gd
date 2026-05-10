extends SceneTree

var _log: String = ""
var _errors: int = 0
var _passed: int = 0
var _gm: Variant = null
var _cd: Variant = null
var _rm: Variant = null
var _rs: Variant = null
var _is: Variant = null
var _ready_done: bool = false

var _player_left_deck: RefCounted = null
var _player_right_deck: RefCounted = null
var _player_hand: RefCounted = null
var _enemy_left_deck: RefCounted = null
var _enemy_right_deck: RefCounted = null
var _enemy_hand: RefCounted = null
var _player_deployed: Dictionary = {}
var _enemy_deployed: Dictionary = {}
var _combat_stats: Dictionary = {}
var _turn: int = 1
var _max_turns: int = 30

var _DeckScript: GDScript
var _HandScript: GDScript
var _BattleResolver: GDScript
var _CardInstanceScript: GDScript

func _init() -> void:
	print("BOT VS BOT: _init")

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	if _gm == null:
		_try_init()
		return false
	_ready_done = true
	_run_full_game()
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

func _log_msg(msg: String) -> void:
	_log += msg + "\n"
	print(msg)

func _run_full_game() -> void:
	_log_msg("========================================")
	_log_msg("  BOT vs BOT - FULL GAME SIMULATION")
	_log_msg("========================================")

	_DeckScript = load("res://scripts/cards/deck.gd")
	_HandScript = load("res://scripts/cards/hand.gd")
	_BattleResolver = load("res://scripts/combat/battle_resolver.gd")
	_CardInstanceScript = load("res://scripts/cards/card_instance.gd")

	_init_game()

	# Run multiple games to get stats
	var games_to_run: int = 5
	var game_results: Array = []
	for game_num in range(games_to_run):
		_log_msg("")
		_log_msg("========== GAME %d / %d ==========" % [game_num + 1, games_to_run])
		_init_game()
		var result: Dictionary = _play_game()
		game_results.append(result)

		# Reset religion/ideology for next game
		if _rs.get_religion() != "":
			_rs.set_religion("")

	_log_msg("")
	_log_msg("========================================")
	_log_msg("  MULTI-GAME SUMMARY (%d games)" % games_to_run)
	_log_msg("========================================")
	for i in range(game_results.size()):
		var r: Dictionary = game_results[i]
		_log_msg("Game %d: %s | P=%d E=%d terr | Duels=%d ZeroDmg=%.1f%% | Stalemates=%d" % [
			i + 1, r.get("winner", "?"),
			r.get("p_territories", 0), r.get("e_territories", 0),
			r.get("duels", 0),
			r.get("zero_damage_pct", 0.0),
			r.get("stalemates", 0)])

	var avg_duels: float = 0
	var avg_zero: float = 0
	var avg_stale: float = 0
	var p_wins: int = 0
	var e_wins: int = 0
	for r in game_results:
		avg_duels += r.get("duels", 0)
		avg_zero += r.get("zero_damage_pct", 0.0)
		avg_stale += r.get("stalemates", 0)
		if r.get("winner", "").find("PLAYER") >= 0:
			p_wins += 1
		elif r.get("winner", "").find("ENEMY") >= 0:
			e_wins += 1
	avg_duels /= maxi(games_to_run, 1)
	avg_zero /= maxi(games_to_run, 1)
	avg_stale /= maxi(games_to_run, 1)

	_log_msg("")
	_log_msg("Avg duels/game: %.1f | Avg zero-dmg%%: %.1f%% | Avg stalemates: %.1f" % [
		avg_duels, avg_zero, avg_stale])
	_log_msg("Player wins: %d | Enemy wins: %d" % [p_wins, e_wins])

	if avg_zero > 15.0:
		_log_msg("CRITICAL: Too many zero-damage rounds! Need to buff ATK or nerf DEF.")
	elif avg_zero > 8.0:
		_log_msg("WARNING: Moderate zero-damage. Consider minor balance tweaks.")
	else:
		_log_msg("OK: Combat balance looks reasonable.")

	_log_msg("PASSED: %d | ERRORS: %d" % [_passed, _errors])
	_log_msg("========================================")

	var file := FileAccess.open("user://bot_vs_bot_log.txt", FileAccess.WRITE)
	if file:
		file.store_string(_log)
		file.close()
	quit()

func _init_game() -> void:
	_player_deployed.clear()
	_enemy_deployed.clear()
	_combat_stats = {"stalemates": 0, "player_wins": 0, "enemy_wins": 0, "total_duels": 0, "zero_damage_rounds": 0, "total_rounds": 0}
	_turn = 1

	_player_left_deck = _DeckScript.new()
	_player_right_deck = _DeckScript.new()
	_player_hand = _HandScript.new(10)
	_player_left_deck.build_left_deck()
	_player_right_deck.build_right_deck()

	_enemy_left_deck = _DeckScript.new()
	_enemy_right_deck = _DeckScript.new()
	_enemy_hand = _HandScript.new(10)
	_enemy_left_deck.build_left_deck()
	_enemy_right_deck.build_right_deck()

	_gm.start_game()

func _play_game() -> Dictionary:
	for t in range(_max_turns):
		_turn = t + 1
		_log_msg("")
		_log_msg("--- TURN %d ---" % _turn)
		_phase_resources()
		_phase_draw()
		_phase_naming()
		_phase_ideology()
		_phase_religion()
		_phase_deploy_and_move()
		_phase_combat()
		_phase_end()

		var winner: String = _check_victory()
		if winner != "":
			_log_msg("=== VICTORY: %s on turn %d ===" % [winner, _turn])
			break

	var total_rounds: int = _combat_stats["total_rounds"]
	var zero_pct: float = (_combat_stats["zero_damage_rounds"] * 100.0 / maxi(total_rounds, 1))
	_log_msg("  Duels: %d | Rounds: %d | Zero-dmg: %d (%.1f%%) | Stalemates: %d" % [
		_combat_stats["total_duels"], total_rounds,
		_combat_stats["zero_damage_rounds"], zero_pct,
		_combat_stats["stalemates"]])

	return {
		"winner": _check_victory() if _check_victory() != "" else "timeout",
		"p_territories": _gm.get_player_territory_count(),
		"e_territories": _gm.get_enemy_territory_count(),
		"duels": _combat_stats["total_duels"],
		"zero_damage_pct": zero_pct,
		"stalemates": _combat_stats["stalemates"],
		"turns_played": _turn
	}

func _phase_resources() -> void:
	_rm.apply_income()
	_rm.apply_enemy_income()
	# Give both sides extra income so they can keep deploying
	_gm.change_resource("bottles", 10)
	_gm.change_resource("coins", 5)
	_gm.change_resource("rolltons", 5)
	_gm.change_resource("cardboard", 4)
	_gm.change_resource("aluminum", 3)
	_gm.change_enemy_resource("bottles", 10)
	_gm.change_enemy_resource("coins", 5)
	_gm.change_enemy_resource("rolltons", 5)
	_gm.change_enemy_resource("cardboard", 4)
	_gm.change_enemy_resource("aluminum", 3)

func _phase_draw() -> void:
	if _player_left_deck.is_empty() and _player_right_deck.is_empty():
		_player_left_deck.build_left_deck()
		_player_right_deck.build_right_deck()
	if _enemy_left_deck.is_empty() and _enemy_right_deck.is_empty():
		_enemy_left_deck.build_left_deck()
		_enemy_right_deck.build_right_deck()

	var p_drawn: int = 0
	for i in range(3):
		var c: Dictionary = _player_left_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			p_drawn += 1
	var right_count: int = 2
	if _gm.is_ideology_chosen():
		right_count += _is.get_extra_unit_draw()
	for i in range(right_count):
		var c: Dictionary = _player_right_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			p_drawn += 1

	var e_drawn: int = 0
	for i in range(3):
		var c: Dictionary = _enemy_left_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			e_drawn += 1
	for i in range(2):
		var c: Dictionary = _enemy_right_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			e_drawn += 1

func _phase_naming() -> void:
	if _turn == 2 and not _gm.is_state_named():
		_gm.set_state_name("Bot Empire Alpha")

func _phase_ideology() -> void:
	if _gm.get_player_territory_count() >= 5 and not _gm.is_ideology_chosen():
		_gm.choose_ideology("alcoholism")
		_log_msg("  IDEOLOGY: Player chose Alcoholism")

func _phase_religion() -> void:
	if _gm.get_player_territory_count() >= 3 and not _gm.is_religion_chosen():
		_rs.set_religion("mnogobomzhie")
		_gm.set_religion_chosen(true)

func _phase_deploy_and_move() -> void:
	var p_deployed: int = _bot_deploy("player", _player_hand, _player_deployed)
	var e_deployed: int = _bot_deploy("enemy", _enemy_hand, _enemy_deployed)
	var p_moved: int = _bot_move("player", _player_deployed)
	var e_moved: int = _bot_move("enemy", _enemy_deployed)

	_log_msg("  DEPLOY: P=%d E=%d | MOVE: P=%d E=%d | ON MAP: P=%d E=%d" % [
		p_deployed, e_deployed, p_moved, e_moved,
		_count_alive(_player_deployed), _count_alive(_enemy_deployed)])

func _can_side_afford(side: String, cost: Dictionary) -> bool:
	var resources: Dictionary = _gm.get_resources() if side == "player" else _gm.get_enemy_resources()
	for res in cost:
		if resources.get(res, 0) < cost[res]:
			return false
	return true

func _side_spend(side: String, cost: Dictionary) -> void:
	for res in cost:
		if side == "player":
			_gm.change_resource(res, -cost[res])
		else:
			_gm.change_enemy_resource(res, -cost[res])

func _bot_deploy(side: String, hand: RefCounted, deployed: Dictionary) -> int:
	var count: int = 0
	var units: Array = hand.get_cards_by_type("unit")
	var commanders: Array = hand.get_cards_by_type("commander")
	var all_deployable: Array = []
	for u in units:
		all_deployable.append(u)
	for c in commanders:
		all_deployable.append(c)

	for card_data in all_deployable:
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_side_afford(side, cost):
			continue
		_side_spend(side, cost)
		var instance: RefCounted = _CardInstanceScript.new(card_data)
		var target: String = _find_deploy_target(side, deployed)
		if target != "":
			if not deployed.has(target):
				deployed[target] = []
			deployed[target].append(instance)
			instance.territory_id = target
			hand.remove_by_id(card_data.get("id", ""))
			count += 1
	return count

func _find_deploy_target(side: String, deployed: Dictionary) -> String:
	var capital_id: String = "dump_west" if side == "player" else "dump_east"
	var capital_under_threat: bool = false
	var adj: Array = _cd.get_adjacent_territories(capital_id)
	for a_id in adj:
		if _gm.get_territory_owner(a_id) != side and _gm.get_territory_owner(a_id) != "neutral":
			capital_under_threat = true
			break
	if capital_under_threat:
		return capital_id

	var frontline: Array = []
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == side:
			var t_adj: Array = _cd.get_adjacent_territories(t_id)
			for a_id in t_adj:
				var a_owner: String = _gm.get_territory_owner(a_id)
				if a_owner != side:
					frontline.append(t_id)
					break

	var best: String = ""
	var best_score: float = -1.0
	for f_id in frontline:
		var td: Dictionary = _cd.get_territory(f_id)
		var score: float = 0.0
		if td.get("is_capital", false):
			score += 10.0
		if td.get("terrain", "") == "dump":
			score += 5.0
		score += td.get("resource_bottles", 0)
		var enemy_count: int = 0
		for a_id in _cd.get_adjacent_territories(f_id):
			if _gm.get_territory_owner(a_id) != side:
				enemy_count += 1
		score += enemy_count * 2.0
		var deployed_here: int = 0
		if deployed.has(f_id):
			for u in deployed[f_id]:
				if u.is_alive():
					deployed_here += 1
		if deployed_here == 0:
			score += 3.0
		if score > best_score:
			best_score = score
			best = f_id

	if best != "":
		return best

	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == side:
			var t: Dictionary = _cd.get_territory(t_id)
			if t.get("is_capital", false):
				return t_id
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == side:
			return t_id
	return ""

func _bot_move(side: String, deployed: Dictionary) -> int:
	var moved: int = 0
	var territories: Array = deployed.keys().duplicate()
	var enemy_side: String = "enemy" if side == "player" else "player"
	var capital_id: String = "dump_west" if side == "player" else "dump_east"

	for t_id in territories:
		var units: Array = deployed[t_id]
		if units.is_empty():
			continue

		var is_capital: bool = (t_id == capital_id)
		var t_data: Dictionary = _cd.get_territory(t_id)
		var terrain: String = t_data.get("terrain", "open_street")
		var is_dump: bool = (terrain == "dump")

		var defenders_to_keep: int = 0
		if is_capital:
			if units.size() >= 2:
				defenders_to_keep = 2
		elif is_dump and units.size() >= 4:
			defenders_to_keep = 1

		var adjacent: Array = _cd.get_adjacent_territories(t_id)
		var threats: Array = []
		var expansions: Array = []
		for adj_id in adjacent:
			var adj_owner: String = _gm.get_territory_owner(adj_id)
			if adj_owner == enemy_side:
				threats.append(adj_id)
			elif adj_owner == "neutral":
				expansions.append(adj_id)

		var best_target: String = ""
		var best_score: float = -999.0

		var threat_targets: Array = threats.duplicate()
		for exp_id in expansions:
			var has_threat_neighbor: bool = false
			for n_id in _cd.get_adjacent_territories(exp_id):
				if _gm.get_territory_owner(n_id) == enemy_side:
					has_threat_neighbor = true
					break
			if has_threat_neighbor:
				threat_targets.append(exp_id)

		if threats.size() > 0:
			for target_id in threats:
				var score: float = 8.0
				var td: Dictionary = _cd.get_territory(target_id)
				if td.get("is_capital", false):
					score += 15.0
				if td.get("terrain", "") == "dump":
					score += 5.0
				if score > best_score:
					best_score = score
					best_target = target_id
		elif threat_targets.size() > 0:
			for target_id in threat_targets:
				var score: float = 4.0
				if score > best_score:
					best_score = score
					best_target = target_id
		elif expansions.size() > 0:
			for exp_id in expansions:
				var td: Dictionary = _cd.get_territory(exp_id)
				var score: float = 0.0
				score += td.get("resource_bottles", 0) * 2.0
				score += td.get("resource_coins", 0) * 1.5
				score += td.get("resource_cardboard", 0) * 1.0
				if td.get("terrain", "") == "dump":
					score += 5.0
				if score > best_score:
					best_score = score
					best_target = exp_id
		else:
			for adj_id in adjacent:
				var adj_owner: String = _gm.get_territory_owner(adj_id)
				if adj_owner == side:
					var adj_adj: Array = _cd.get_adjacent_territories(adj_id)
					for aa_id in adj_adj:
						if _gm.get_territory_owner(aa_id) != side:
							var score: float = 1.0
							if score > best_score:
								best_score = score
								best_target = adj_id
								break

		if best_target != "":
			var sendable: int = maxi(units.size() - defenders_to_keep, 0)
			var to_send: int = mini(sendable, maxi(units.size() / 2, 1))
			for i in range(to_send):
				if units.is_empty():
					break
				var unit: RefCounted = units.pop_front()
				if not deployed.has(best_target):
					deployed[best_target] = []
				deployed[best_target].append(unit)
				unit.territory_id = best_target
				moved += 1
	return moved

func _phase_combat() -> void:
	var contested: Array = []
	for t_id in _player_deployed:
		if _enemy_deployed.has(t_id):
			contested.append(t_id)

	var resolver: RefCounted = _BattleResolver.new()

	for t_id in contested:
		var p_units: Array = _player_deployed[t_id]
		var e_units: Array = _enemy_deployed[t_id]
		var territory: Dictionary = _cd.get_territory(t_id)
		var terrain: String = territory.get("terrain", "open_street")

		var alive_p: int = 0
		var alive_e: int = 0
		for u in p_units:
			if u.is_alive():
				alive_p += 1
		for u in e_units:
			if u.is_alive():
				alive_e += 1
		if alive_p == 0 or alive_e == 0:
			continue

		var t_owner: String = _gm.get_territory_owner(t_id)
		var player_is_attacker: bool = true
		if t_owner == "player":
			player_is_attacker = false
		elif t_owner == "enemy":
			player_is_attacker = true
		else:
			player_is_attacker = alive_p >= alive_e

		var attackers: Array
		var defenders: Array
		if player_is_attacker:
			attackers = p_units
			defenders = e_units
		else:
			attackers = e_units
			defenders = p_units

		_log_msg("  BATTLE at %s [%s]: %d P vs %d E (%s attacks)" % [
			territory.get("name_ru", t_id), terrain, alive_p, alive_e,
			"P" if player_is_attacker else "E"])

		var result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)

		for duel in result.get("rounds", []):
			_combat_stats["total_duels"] += 1
			var rounds: Array = duel.get("rounds", [])
			for r in rounds:
				_combat_stats["total_rounds"] += 1
				if r.get("atk_damage", 0) == 0 and r.get("def_damage", 0) == 0:
					_combat_stats["zero_damage_rounds"] += 1
			if duel.get("attacker_destroyed", false) and duel.get("defender_destroyed", false):
				_combat_stats["stalemates"] += 1

		var attacker_won: bool = result.get("player_won", false)
		var winner_side: String
		if player_is_attacker:
			winner_side = "player" if attacker_won else "enemy"
		else:
			winner_side = "enemy" if attacker_won else "player"

		if winner_side == "player":
			_combat_stats["player_wins"] += 1
			_gm.set_territory_owner(t_id, "player")
			_enemy_deployed.erase(t_id)
			var alive: Array = []
			for u in p_units:
				if u.is_alive():
					alive.append(u)
			_player_deployed[t_id] = alive
			_log_msg("    -> PLAYER WINS (%d survived)" % alive.size())
		else:
			_combat_stats["enemy_wins"] += 1
			_gm.set_territory_owner(t_id, "enemy")
			_player_deployed.erase(t_id)
			var alive: Array = []
			for u in e_units:
				if u.is_alive():
					alive.append(u)
			_enemy_deployed[t_id] = alive
			_log_msg("    -> ENEMY WINS (%d survived)" % alive.size())

	_capture_uncontested(_player_deployed, "player")
	_capture_uncontested(_enemy_deployed, "enemy")

func _capture_uncontested(deployed: Dictionary, side: String) -> void:
	for t_id in deployed:
		var has_alive: bool = false
		for u in deployed[t_id]:
			if u.is_alive():
				has_alive = true
				break
		if has_alive:
			_gm.set_territory_owner(t_id, side)

func _phase_end() -> void:
	for t_id in _player_deployed:
		for unit in _player_deployed[t_id]:
			unit.tick_buffs()
			if unit.is_alive():
				unit.heal(1)
	for t_id in _enemy_deployed:
		for unit in _enemy_deployed[t_id]:
			unit.tick_buffs()
			if unit.is_alive():
				unit.heal(1)

	_log_msg("  STATUS: P=%d terr / %d units | E=%d terr / %d units" % [
		_gm.get_player_territory_count(), _count_alive(_player_deployed),
		_gm.get_enemy_territory_count(), _count_alive(_enemy_deployed)])

func _count_alive(deployed: Dictionary) -> int:
	var count: int = 0
	for t_id in deployed:
		for u in deployed[t_id]:
			if u.is_alive():
				count += 1
	return count

func _check_victory() -> String:
	if _gm.get_territory_owner("dump_east") == "player":
		return "PLAYER captured enemy capital"
	if _gm.get_territory_owner("dump_west") == "enemy":
		return "ENEMY captured player capital"
	var p: int = _gm.get_player_territory_count()
	var e: int = _gm.get_enemy_territory_count()
	var total: int = 0
	for t_id in _gm._territory_owners:
		var owner: String = _gm._territory_owners[t_id]
		if owner == "player" or owner == "enemy":
			total += 1
	if total >= 30:
		if p > e:
			return "PLAYER by territory count"
		elif e > p:
			return "ENEMY by territory count"
		else:
			return "DRAW"
	return ""
