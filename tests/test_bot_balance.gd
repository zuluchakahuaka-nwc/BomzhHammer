extends SceneTree

var _log: String = ""
var _gm: Variant = null
var _cd: Variant = null
var _rm: Variant = null
var _rs: Variant = null
var _is: Variant = null
var _ready_done: bool = false

var _player_deployed: Dictionary = {}
var _enemy_deployed: Dictionary = {}
var _player_hand: Variant = null
var _enemy_hand: Variant = null
var _player_left_deck: Variant = null
var _player_right_deck: Variant = null
var _enemy_left_deck: Variant = null
var _enemy_right_deck: Variant = null

var _DeckScript: GDScript
var _HandScript: GDScript
var _BattleResolver: GDScript
var _CardInstanceScript: GDScript
var _PathFinderScript: GDScript

var _turn: int = 1
var _max_turns: int = 40

var _total_duels: int = 0
var _total_rounds: int = 0
var _zero_damage_rounds: int = 0
var _stalemates: int = 0
var _player_combat_wins: int = 0
var _enemy_combat_wins: int = 0
var _total_moves: int = 0
var _territory_flips: int = 0
var _stuck_battles: Array = []
var _zero_dmg_unit_pairs: Dictionary = {}

func _init() -> void:
	print("BOT BALANCE v3")

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	if _gm == null:
		var root_node: Node = get_root()
		if root_node == null:
			return false
		_gm = root_node.get_node_or_null("GameManager")
		_cd = root_node.get_node_or_null("CardDatabase")
		_rm = root_node.get_node_or_null("ResourceManager")
		_rs = root_node.get_node_or_null("ReligionSystem")
		_is = root_node.get_node_or_null("IdeologySystem")
		return false
	_ready_done = true
	_run()
	return false

func _lm(msg: String) -> void:
	_log += msg + "\n"
	print(msg)

func _run() -> void:
	_lm("======================================================")
	_lm("  BOT vs BOT BALANCE v3 — 10 games x %d turns" % _max_turns)
	_lm("======================================================")

	_DeckScript = load("res://scripts/cards/deck.gd")
	_HandScript = load("res://scripts/cards/hand.gd")
	_BattleResolver = load("res://scripts/combat/battle_resolver.gd")
	_CardInstanceScript = load("res://scripts/cards/card_instance.gd")
	_PathFinderScript = load("res://scripts/map/path_finder.gd")

	var all_results: Array = []
	var num_games: int = 10
	for g in range(num_games):
		_lm("")
		_lm("============ GAME %d / %d ============" % [g + 1, num_games])
		_reset_game()
		var res: Dictionary = _play_game()
		all_results.append(res)
		if _rs.get_religion() != "":
			_rs.set_religion("")
		if _is.get_ideology() != "":
			_is.set_ideology("")

	_print_summary(all_results, num_games)

	var file := FileAccess.open("user://bot_balance_log.txt", FileAccess.WRITE)
	if file:
		file.store_string(_log)
		file.close()
	_lm("Log saved to user://bot_balance_log.txt")
	quit()

func _reset_game() -> void:
	_player_deployed.clear()
	_enemy_deployed.clear()
	_total_duels = 0
	_total_rounds = 0
	_zero_damage_rounds = 0
	_stalemates = 0
	_player_combat_wins = 0
	_enemy_combat_wins = 0
	_total_moves = 0
	_territory_flips = 0
	_stuck_battles.clear()
	_zero_dmg_unit_pairs.clear()
	_turn = 1

	_player_left_deck = _DeckScript.new()
	_player_right_deck = _DeckScript.new()
	_player_hand = _HandScript.new(15)
	_player_left_deck.build_left_deck()
	_player_right_deck.build_right_deck()

	_enemy_left_deck = _DeckScript.new()
	_enemy_right_deck = _DeckScript.new()
	_enemy_hand = _HandScript.new(15)
	_enemy_left_deck.build_left_deck()
	_enemy_right_deck.build_right_deck()

	_gm.start_game()

func _play_game() -> Dictionary:
	var prev_owners: Dictionary = {}
	for t_id in _gm._territory_owners:
		prev_owners[t_id] = _gm._territory_owners[t_id]

	for t in range(_max_turns):
		_turn = t + 1

		_phase_resources()
		_discard_non_units(_player_hand)
		_discard_non_units(_enemy_hand)
		_phase_draw()
		_phase_deploy()
		_phase_move()
		_phase_combat()
		_phase_end()

		for t_id in _gm._territory_owners:
			var new_owner: String = _gm._territory_owners[t_id]
			if prev_owners.get(t_id, "") != new_owner and new_owner != "neutral":
				if prev_owners.get(t_id, "") != "" and prev_owners.get(t_id, "") != "neutral":
					_territory_flips += 1
				prev_owners[t_id] = new_owner

		if _turn <= 10 or _turn % 5 == 0:
			_lm("  T%02d: P=%dterr %dunits | E=%dterr %dunits | hand P=%d E=%d | moves=%d" % [
				_turn,
				_gm.get_player_territory_count(), _count_alive(_player_deployed),
				_gm.get_enemy_territory_count(), _count_alive(_enemy_deployed),
				_player_hand.size(), _enemy_hand.size(),
				_total_moves])

		var winner: String = _check_victory()
		if winner != "":
			_lm("  === VICTORY: %s on turn %d ===" % [winner, _turn])
			break

	var zero_pct: float = _zero_damage_rounds * 100.0 / maxi(_total_rounds, 1)
	_lm("  FINAL: Duels=%d Rounds=%d ZeroDmg=%d(%.1f%%) Stale=%d Moves=%d Flips=%d" % [
		_total_duels, _total_rounds, _zero_damage_rounds, zero_pct,
		_stalemates, _total_moves, _territory_flips])

	return {
		"winner": _check_victory() if _check_victory() != "" else "timeout",
		"p_territories": _gm.get_player_territory_count(),
		"e_territories": _gm.get_enemy_territory_count(),
		"duels": _total_duels,
		"zero_pct": zero_pct,
		"stalemates": _stalemates,
		"turns_played": _turn,
		"total_moves": _total_moves,
		"territory_flips": _territory_flips
	}

func _discard_non_units(hand: Variant) -> void:
	var non_units: Array = hand.get_cards_by_type("situation")
	non_units.append_array(hand.get_cards_by_type("spell"))
	var to_discard: int = maxi(non_units.size() - 3, 0)
	var discarded: int = 0
	for card_data in non_units:
		if discarded >= to_discard:
			break
		hand.remove_by_id(card_data.get("id", ""))
		discarded += 1

func _phase_resources() -> void:
	_rm.apply_income()
	_rm.apply_enemy_income()
	_gm.change_resource("bottles", 12)
	_gm.change_resource("coins", 6)
	_gm.change_resource("rolltons", 6)
	_gm.change_resource("cardboard", 5)
	_gm.change_resource("aluminum", 3)
	_gm.change_enemy_resource("bottles", 12)
	_gm.change_enemy_resource("coins", 6)
	_gm.change_enemy_resource("rolltons", 6)
	_gm.change_enemy_resource("cardboard", 5)
	_gm.change_enemy_resource("aluminum", 3)

	if _gm.get_player_territory_count() >= 5 and not _gm.is_ideology_chosen():
		_gm.choose_ideology("alcoholism")
	if _gm.get_player_territory_count() >= 3 and not _gm.is_religion_chosen():
		_rs.set_religion("mnogobomzhie")
		_gm.set_religion_chosen(true)
	if _turn == 2 and not _gm.is_state_named():
		_gm.set_state_name("Bot Empire")

func _phase_draw() -> void:
	_refill_decks(_player_left_deck, _player_right_deck)
	_refill_decks(_enemy_left_deck, _enemy_right_deck)

	var right_count: int = 2
	if _gm.is_ideology_chosen():
		right_count += _is.get_extra_unit_draw()

	for i in range(3):
		var c: Dictionary = _player_left_deck.draw_card()
		if not c.is_empty():
			_player_hand.add_card(c)
	for i in range(right_count):
		var c: Dictionary = _player_right_deck.draw_card()
		if not c.is_empty():
			_player_hand.add_card(c)

	for i in range(3):
		var c: Dictionary = _enemy_left_deck.draw_card()
		if not c.is_empty():
			_enemy_hand.add_card(c)
	for i in range(2):
		var c: Dictionary = _enemy_right_deck.draw_card()
		if not c.is_empty():
			_enemy_hand.add_card(c)

func _refill_decks(left: Variant, right: Variant) -> void:
	if left.is_empty() and right.is_empty():
		left.build_left_deck()
		right.build_right_deck()

func _phase_deploy() -> void:
	var pd: int = _bot_deploy("player", _player_hand, _player_deployed)
	var ed: int = _bot_deploy("enemy", _enemy_hand, _enemy_deployed)
	if pd > 0 or ed > 0:
		_lm("  T%02d DEPLOY: P=%d E=%d new units" % [_turn, pd, ed])

func _can_afford(side: String, cost: Dictionary) -> bool:
	var res: Dictionary = _gm.get_resources() if side == "player" else _gm.get_enemy_resources()
	for r in cost:
		if res.get(r, 0) < cost[r]:
			return false
	return true

func _spend(side: String, cost: Dictionary) -> void:
	for r in cost:
		if side == "player":
			_gm.change_resource(r, -cost[r])
		else:
			_gm.change_enemy_resource(r, -cost[r])

func _bot_deploy(side: String, hand: Variant, deployed: Dictionary) -> int:
	var count: int = 0
	var deployable: Array = hand.get_cards_by_type("unit")
	deployable.append_array(hand.get_cards_by_type("commander"))

	deployable.sort_custom(func(a, b): return (
		a.get("attack", 0) + a.get("defense", 0)
	) > (
		b.get("attack", 0) + b.get("defense", 0)
	))

	for card_data in deployable:
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_afford(side, cost):
			continue
		_spend(side, cost)
		var instance: RefCounted = _CardInstanceScript.new(card_data)
		var target: String = _smart_deploy_target(side, deployed)
		if target == "":
			var capital: String = "dump_west" if side == "player" else "dump_east"
			target = capital
		if target != "":
			if not deployed.has(target):
				deployed[target] = []
			deployed[target].append(instance)
			instance.territory_id = target
			hand.remove_by_id(card_data.get("id", ""))
			count += 1
	return count

func _smart_deploy_target(side: String, deployed: Dictionary) -> String:
	var enemy_side: String = "enemy" if side == "player" else "player"
	var capital: String = "dump_west" if side == "player" else "dump_east"

	var capital_threatened: bool = false
	for a_id in _cd.get_adjacent_territories(capital):
		if _gm.get_territory_owner(a_id) == enemy_side:
			var enemy_units: int = 0
			if side == "player" and _enemy_deployed.has(a_id):
				for eu in _enemy_deployed[a_id]:
					if eu.is_alive():
						enemy_units += 1
			elif side == "enemy" and _player_deployed.has(a_id):
				for eu in _player_deployed[a_id]:
					if eu.is_alive():
						enemy_units += 1
			if enemy_units > 0:
				capital_threatened = true
				break

	if capital_threatened:
		var capital_defenders: int = 0
		if deployed.has(capital):
			for u in deployed[capital]:
				if u.is_alive():
					capital_defenders += 1
		if capital_defenders < 3:
			return capital

	var frontline: Array = []
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] != side:
			continue
		for a_id in _cd.get_adjacent_territories(t_id):
			var a_owner: String = _gm.get_territory_owner(a_id)
			if a_owner != side:
				frontline.append(t_id)
				break

	var best: String = ""
	var best_score: float = -999.0

	for f_id in frontline:
		var td: Dictionary = _cd.get_territory(f_id)
		var score: float = 0.0

		var enemy_neighbors: int = 0
		var enemy_units_nearby: int = 0
		for a_id in _cd.get_adjacent_territories(f_id):
			if _gm.get_territory_owner(a_id) == enemy_side:
				enemy_neighbors += 1
				if side == "player" and _enemy_deployed.has(a_id):
					for eu in _enemy_deployed[a_id]:
						if eu.is_alive():
							enemy_units_nearby += 1
				elif side == "enemy" and _player_deployed.has(a_id):
					for eu in _player_deployed[a_id]:
						if eu.is_alive():
							enemy_units_nearby += 1
			elif _gm.get_territory_owner(a_id) == "neutral":
				score += 1.0

		score += enemy_neighbors * 3.0
		if enemy_units_nearby > 0:
			score += 5.0

		var deployed_here: int = 0
		if deployed.has(f_id):
			for u in deployed[f_id]:
				if u.is_alive():
					deployed_here += 1
		if deployed_here == 0:
			score += 3.0
		elif deployed_here >= 4:
			score -= 4.0

		if td.get("terrain", "") == "dump":
			score += 2.0
		if td.get("is_capital", false):
			score -= 3.0

		if score > best_score:
			best_score = score
			best = f_id

	if best != "":
		return best

	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == side:
			return t_id
	return ""

func _phase_move() -> void:
	var pm: int = _smart_move("player", _player_deployed)
	var em: int = _smart_move("enemy", _enemy_deployed)
	_total_moves += pm + em

func _smart_move(side: String, deployed: Dictionary) -> int:
	var moved: int = 0
	var enemy_side: String = "enemy" if side == "player" else "player"
	var my_capital: String = "dump_west" if side == "player" else "dump_east"
	var enemy_capital: String = "dump_east" if side == "player" else "dump_west"
	var pf: RefCounted = _PathFinderScript.new()

	var territories: Array = deployed.keys().duplicate()
	territories.shuffle()

	var moved_this_turn: Dictionary = {}

	for t_id in territories:
		if moved_this_turn.has(t_id):
			continue
		var units: Array = deployed[t_id]
		var alive_units: Array = []
		for u in units:
			if u.is_alive():
				alive_units.append(u)
		if alive_units.is_empty():
			continue

		var is_my_capital: bool = (t_id == my_capital)
		var is_frontline: bool = false
		var has_enemy_neighbor: bool = false
		var adjacent: Array = _cd.get_adjacent_territories(t_id)
		for a_id in adjacent:
			var a_owner: String = _gm.get_territory_owner(a_id)
			if a_owner == enemy_side:
				is_frontline = true
				has_enemy_neighbor = true
			elif a_owner == "neutral":
				is_frontline = true

		var keep: int = 0
		if is_my_capital and has_enemy_neighbor:
			keep = 2
		elif is_frontline and has_enemy_neighbor:
			keep = 1

		var sendable: int = maxi(alive_units.size() - keep, 0)
		if sendable <= 0:
			if not is_frontline and alive_units.size() > 0:
				sendable = alive_units.size()
			else:
				continue

		var best_target: String = ""
		var best_score: float = -999.0

		for adj_id in adjacent:
			var adj_owner: String = _gm.get_territory_owner(adj_id)
			var td: Dictionary = _cd.get_territory(adj_id)
			var score: float = 0.0

			if adj_owner == enemy_side:
				score += 12.0
				if td.get("is_capital", false):
					score += 25.0
				if td.get("terrain", "") == "dump":
					score += 8.0
				var enemy_garrison: int = 0
				if side == "player" and _enemy_deployed.has(adj_id):
					for eu in _enemy_deployed[adj_id]:
						if eu.is_alive():
							enemy_garrison += 1
				elif side == "enemy" and _player_deployed.has(adj_id):
					for eu in _player_deployed[adj_id]:
						if eu.is_alive():
							enemy_garrison += 1
				if enemy_garrison == 0:
					score += 10.0
				else:
					var my_attack: float = 0
					for u in alive_units:
						my_attack += u.get_effective_attack()
					if my_attack > enemy_garrison * 2:
						score += 5.0
					else:
						score -= enemy_garrison * 2.0
			elif adj_owner == "neutral":
				score += 7.0
				score += td.get("resource_bottles", 0) * 1.0
				score += td.get("resource_coins", 0) * 1.5
				if td.get("terrain", "") == "dump":
					score += 5.0
				if td.get("terrain", "") == "station":
					score += 3.0
			else:
				var adj_adj: Array = _cd.get_adjacent_territories(adj_id)
				var enemy_adj: int = 0
				var neutral_adj: int = 0
				for aa_id in adj_adj:
					var aa_owner: String = _gm.get_territory_owner(aa_id)
					if aa_owner == enemy_side:
						enemy_adj += 1
					elif aa_owner == "neutral":
						neutral_adj += 1
				if enemy_adj > 0:
					score += 3.0 + enemy_adj * 2.0
				elif neutral_adj > 0:
					score += 2.0
				else:
					score -= 5.0

			if score > best_score:
				best_score = score
				best_target = adj_id

		if best_target == "" or best_score <= -4.0:
			var path: Array = pf.find_path(t_id, enemy_capital)
			if path.size() > 1:
				var next_step: String = path[1]
				if adjacent.has(next_step):
					best_target = next_step
					best_score = 0.0

		if best_target != "" and best_score > -4.0:
			var to_send: int = mini(sendable, 3)
			for i in range(to_send):
				if alive_units.is_empty():
					break
				var unit: RefCounted = alive_units.pop_front()
				units.erase(unit)
				if not deployed.has(best_target):
					deployed[best_target] = []
				deployed[best_target].append(unit)
				unit.territory_id = best_target
				moved += 1
			moved_this_turn[best_target] = true

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
		var terrain_def: int = resolver._terrain_defense.get(terrain, 0)

		var alive_p: Array = []
		var alive_e: Array = []
		for u in p_units:
			if u.is_alive():
				alive_p.append(u)
		for u in e_units:
			if u.is_alive():
				alive_e.append(u)
		if alive_p.is_empty() or alive_e.is_empty():
			continue

		var p_count: int = alive_p.size()
		var e_count: int = alive_e.size()

		var t_owner: String = _gm.get_territory_owner(t_id)
		var player_is_attacker: bool = true
		if t_owner == "player":
			player_is_attacker = false
		elif t_owner == "enemy":
			player_is_attacker = true
		else:
			player_is_attacker = p_count >= e_count

		var attackers: Array
		var defenders: Array
		if player_is_attacker:
			attackers = p_units
			defenders = e_units
		else:
			attackers = e_units
			defenders = p_units

		_lm("  BATTLE %s [%s]: %dP vs %dE (%s attacks)" % [
			territory.get("name_ru", t_id), terrain,
			p_count, e_count,
			"P" if player_is_attacker else "E"])

		var result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)

		var battle_zero: int = 0
		var battle_rounds: int = 0
		var battle_stale: bool = false

		for duel in result.get("rounds", []):
			_total_duels += 1
			var rounds: Array = duel.get("rounds", [])
			battle_rounds += rounds.size()
			var atk_id: String = duel.get("attacker_id", "?")
			var def_id: String = duel.get("defender_id", "?")
			var atk_val: int = 0
			var def_val: int = 0
			var atk_source: Array = attackers
			var def_source: Array = defenders
			for u in atk_source:
				if u.id == atk_id:
					atk_val = u.get_effective_attack()
			for u in def_source:
				if u.id == def_id:
					def_val = u.get_effective_defense()

			for r in rounds:
				_total_rounds += 1
				if r.get("atk_damage", 0) == 0 and r.get("def_damage", 0) == 0:
					_zero_damage_rounds += 1
					battle_zero += 1
					var pair_key: String = "%s_vs_%s" % [atk_id, def_id]
					if not _zero_dmg_unit_pairs.has(pair_key):
						_zero_dmg_unit_pairs[pair_key] = {
							"atk_id": atk_id, "atk": atk_val,
							"def_id": def_id, "def": def_val,
							"terrain_def": terrain_def,
							"count": 0
						}
					_zero_dmg_unit_pairs[pair_key]["count"] += 1

			if duel.get("attacker_destroyed", false) and duel.get("defender_destroyed", false):
				_stalemates += 1
				battle_stale = true

		if battle_rounds >= 8 and battle_zero >= 5:
			_stuck_battles.append({
				"territory": territory.get("name_ru", t_id),
				"terrain": terrain,
				"rounds": battle_rounds,
				"zero_rounds": battle_zero,
				"atk_id": result["rounds"][0].get("attacker_id", "?") if result["rounds"].size() > 0 else "?",
				"def_id": result["rounds"][0].get("defender_id", "?") if result["rounds"].size() > 0 else "?"
			})

		var attacker_won: bool = result.get("player_won", false)
		var winner_side: String
		if player_is_attacker:
			winner_side = "player" if attacker_won else "enemy"
		else:
			winner_side = "enemy" if attacker_won else "player"

		if winner_side == "player":
			_player_combat_wins += 1
		else:
			_enemy_combat_wins += 1

		_gm.set_territory_owner(t_id, winner_side)

		if winner_side == "player":
			_enemy_deployed.erase(t_id)
			var alive: Array = []
			for u in p_units:
				if u.is_alive():
					alive.append(u)
			_player_deployed[t_id] = alive
		else:
			_player_deployed.erase(t_id)
			var alive: Array = []
			for u in e_units:
				if u.is_alive():
					alive.append(u)
			_enemy_deployed[t_id] = alive

		var survived: int = 0
		if winner_side == "player" and _player_deployed.has(t_id):
			for u in _player_deployed[t_id]:
				if u.is_alive():
					survived += 1
		elif _enemy_deployed.has(t_id):
			for u in _enemy_deployed[t_id]:
				if u.is_alive():
					survived += 1

		_lm("    => %s WINS | rounds=%d zero=%d stale=%s survived=%d" % [
			"PLAYER" if winner_side == "player" else "ENEMY",
			battle_rounds, battle_zero,
			"YES" if battle_stale else "no",
			survived
		])

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
	if total >= _gm._territory_owners.size() - 2:
		if p > e:
			return "PLAYER domination (%d vs %d)" % [p, e]
		elif e > p:
			return "ENEMY domination (%d vs %d)" % [e, p]
		else:
			return "DRAW"
	if _turn >= _max_turns:
		if p > e:
			return "PLAYER timeout (%d vs %d)" % [p, e]
		elif e > p:
			return "ENEMY timeout (%d vs %d)" % [e, p]
		else:
			return "DRAW timeout"
	return ""

func _print_summary(all_results: Array, num_games: int) -> void:
	_lm("")
	_lm("======================================================")
	_lm("  GLOBAL SUMMARY (%d games)" % num_games)
	_lm("======================================================")

	var avg_duels: float = 0
	var avg_zero_pct: float = 0
	var avg_stale: float = 0
	var avg_turns: float = 0
	var p_wins: int = 0
	var e_wins: int = 0
	var draws: int = 0
	var avg_p_terr: float = 0
	var avg_e_terr: float = 0
	var avg_moves: float = 0
	var avg_flips: float = 0
	var max_zero_pct: float = 0.0
	var worst_game: int = -1
	var capital_captures: int = 0

	for i in range(all_results.size()):
		var r: Dictionary = all_results[i]
		_lm("Game %2d: %-30s | P=%d E=%d | T=%2d | Duels=%2d Zero=%5.1f%% Stale=%d | Moves=%2d Flip=%d" % [
			i + 1,
			r.get("winner", "?"),
			r.get("p_territories", 0),
			r.get("e_territories", 0),
			r.get("turns_played", 0),
			r.get("duels", 0),
			r.get("zero_pct", 0.0),
			r.get("stalemates", 0),
			r.get("total_moves", 0),
			r.get("territory_flips", 0)
		])
		avg_duels += r.get("duels", 0)
		avg_zero_pct += r.get("zero_pct", 0.0)
		avg_stale += r.get("stalemates", 0)
		avg_turns += r.get("turns_played", 0)
		avg_p_terr += r.get("p_territories", 0)
		avg_e_terr += r.get("e_territories", 0)
		avg_moves += r.get("total_moves", 0)
		avg_flips += r.get("territory_flips", 0)
		if r.get("zero_pct", 0.0) > max_zero_pct:
			max_zero_pct = r.get("zero_pct", 0.0)
			worst_game = i + 1
		var w: String = r.get("winner", "")
		if w.find("PLAYER") >= 0:
			p_wins += 1
		elif w.find("ENEMY") >= 0:
			e_wins += 1
		else:
			draws += 1
		if w.find("capital") >= 0:
			capital_captures += 1

	var n: float = maxi(num_games, 1)
	_lm("")
	_lm("AVG duels=%.1f  zero_dmg=%.1f%%  stalemates=%.1f  turns=%.1f" % [
		avg_duels / n, avg_zero_pct / n, avg_stale / n, avg_turns / n])
	_lm("AVG P_terr=%.1f  E_terr=%.1f  moves=%.1f  flips=%.1f" % [
		avg_p_terr / n, avg_e_terr / n, avg_moves / n, avg_flips / n])
	_lm("WINS: Player=%d Enemy=%d Draw=%d | Capital captures=%d" % [p_wins, e_wins, draws, capital_captures])
	_lm("WORST zero_dmg: %.1f%% (game %d)" % [max_zero_pct, worst_game])

	_lm("")
	_lm("--- ZERO-DAMAGE UNIT PAIRS ---")
	var sorted_pairs: Array = _zero_dmg_unit_pairs.values()
	sorted_pairs.sort_custom(func(a, b): return a["count"] > b["count"])
	for i in range(mini(sorted_pairs.size(), 10)):
		var p: Dictionary = sorted_pairs[i]
		_lm("  %s (ATK=%d) vs %s (DEF=%d+terrain +%d) => %d zero-rounds" % [
			p["atk_id"], p["atk"], p["def_id"], p["def"], p["terrain_def"], p["count"]])

	_lm("")
	_lm("--- DIAGNOSIS ---")
	var global_zero: float = avg_zero_pct / n
	if global_zero > 20.0:
		_lm("CRITICAL: Zero-damage %.1f%%! Battles stall! Need ATK buff or DEF nerf." % global_zero)
	elif global_zero > 10.0:
		_lm("WARNING: Zero-damage %.1f%% elevated. Minor tweaks needed." % global_zero)
	else:
		_lm("OK: Zero-damage %.1f%%" % global_zero)

	var avg_flip_f: float = avg_flips / n
	if avg_flip_f < 3.0:
		_lm("CRITICAL: Flips %.1f/game — map static!" % avg_flip_f)
	elif avg_flip_f < 8.0:
		_lm("MODERATE: Flips %.1f/game — some activity but could be better" % avg_flip_f)
	else:
		_lm("OK: Flips %.1f/game — active warfare" % avg_flip_f)

	var avg_duels_f: float = avg_duels / n
	if avg_duels_f < 5.0:
		_lm("CRITICAL: %.1f duels/game — bots barely fight!" % avg_duels_f)
	elif avg_duels_f < 10.0:
		_lm("MODERATE: %.1f duels/game" % avg_duels_f)
	else:
		_lm("OK: %.1f duels/game — lots of combat" % avg_duels_f)

	_lm("")
	_lm("--- STUCK BATTLES ---")
	if _stuck_battles.size() > 0:
		for s in _stuck_battles:
			_lm("  %s [%s]: rounds=%d zero=%d atk=%s def=%s" % [
				s["territory"], s["terrain"], s["rounds"], s["zero_rounds"],
				s["atk_id"], s["def_id"]])
	else:
		_lm("  None detected.")

	_lm("======================================================")
