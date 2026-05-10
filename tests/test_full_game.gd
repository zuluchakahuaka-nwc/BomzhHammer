extends SceneTree

var _gm: Variant = null
var _cd: Variant = null
var _rm: Variant = null
var _rs: Variant = null
var _is: Variant = null
var _bs: Variant = null
var _hs: Variant = null
var _rts: Variant = null
var _qs: Variant = null
var _ready_done: bool = false

var _CardEffect: GDScript
var _CardInstance: GDScript
var _Deck: GDScript
var _Hand: GDScript
var _BattleResolver: GDScript
var _PathFinder: GDScript
var _EventTrigger: GDScript

var _player_left_deck: Variant = null
var _player_right_deck: Variant = null
var _player_hand: Variant = null
var _enemy_left_deck: Variant = null
var _enemy_right_deck: Variant = null
var _enemy_hand: Variant = null

var _player_deployed: Dictionary = {}
var _enemy_deployed: Dictionary = {}

var _turn: int = 1
var _max_turns: int = 30

var _log: String = ""
var _spell_plays: int = 0
var _situation_plays: int = 0
var _commander_deploys: int = 0
var _buffs_applied: int = 0
var _buildings_built: int = 0
var _riots_triggered: int = 0
var _quests_completed: int = 0
var _religion_turn: int = -1
var _ideology_turn: int = -1
var _enemy_religion_chosen: bool = false
var _enemy_ideology_chosen: bool = false

func _init() -> void:
	print("FULL GAME BOT")

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	var root: Node = get_root()
	if root == null:
		return false
	_gm = root.get_node_or_null("GameManager")
	_cd = root.get_node_or_null("CardDatabase")
	_rm = root.get_node_or_null("ResourceManager")
	_rs = root.get_node_or_null("ReligionSystem")
	_is = root.get_node_or_null("IdeologySystem")
	_bs = root.get_node_or_null("BuildingSystem")
	_hs = root.get_node_or_null("HappinessSystem")
	_rts = root.get_node_or_null("RiotSystem")
	_qs = root.get_node_or_null("QuestSystem")
	if _gm == null or _bs == null or _hs == null:
		return false
	_ready_done = true
	_run()
	return false

func _lm(msg: String) -> void:
	_log += msg + "\n"
	print(msg)

func _run() -> void:
	_lm("============================================")
	_lm("  FULL GAME BOT — Complete Mechanics Test")
	_lm("============================================")

	_CardEffect = load("res://scripts/cards/card_effect.gd")
	_CardInstance = load("res://scripts/cards/card_instance.gd")
	_Deck = load("res://scripts/cards/deck.gd")
	_Hand = load("res://scripts/cards/hand.gd")
	_BattleResolver = load("res://scripts/combat/battle_resolver.gd")
	_PathFinder = load("res://scripts/map/path_finder.gd")
	_EventTrigger = load("res://scripts/combat/event_trigger.gd")

	_init_game()

	for t in range(_max_turns):
		_turn = t + 1
		_lm("\n=== TURN %d ===" % _turn)

		_phase_resources()
		_phase_draw()
		_phase_play_spells_and_situations("player", _player_hand, _player_deployed)
		_phase_play_spells_and_situations("enemy", _enemy_hand, _enemy_deployed)
		_phase_deploy_units("player", _player_hand, _player_deployed)
		_phase_deploy_units("enemy", _enemy_hand, _enemy_deployed)
		_phase_move("player", _player_deployed)
		_phase_move("enemy", _enemy_deployed)
		_phase_combat()
		_phase_build()
		_phase_happiness()
		_phase_quests()
		_phase_events()
		_phase_end()

		if _turn % 3 == 0 or _turn <= 5:
			_print_status()

		var winner: String = _check_victory()
		if winner != "":
			_lm("\n=== GAME OVER: %s on turn %d ===" % [winner, _turn])
			break

	_lm("\n============================================")
	_lm("  FULL GAME REPORT")
	_lm("============================================")
	_lm("Turns played: %d" % _turn)
	_lm("Spells played: %d" % _spell_plays)
	_lm("Situations played: %d" % _situation_plays)
	_lm("Commanders deployed: %d" % _commander_deploys)
	_lm("Buffs applied to units: %d" % _buffs_applied)
	_lm("Buildings built: %d" % _buildings_built)
	_lm("Riots triggered: %d" % _riots_triggered)
	_lm("Quests completed: %d" % _quests_completed)
	_lm("Religion chosen: turn %d" % _religion_turn if _religion_turn > 0 else "Religion: not chosen")
	_lm("Ideology chosen: turn %d" % _ideology_turn if _ideology_turn > 0 else "Ideology: not chosen")
	_lm("Player territories: %d" % _gm.get_player_territory_count())
	_lm("Enemy territories: %d" % _gm.get_enemy_territory_count())
	_lm("Player units on map: %d" % _count_alive(_player_deployed))
	_lm("Enemy units on map: %d" % _count_alive(_enemy_deployed))
	_lm("Player population: %d | Respect: %d" % [_gm.get_population(), _gm.get_respect()])
	_lm("Player happiness: %d | Enemy happiness: %d" % [_hs.get_happiness("player"), _hs.get_happiness("enemy")])
	_lm("Player buildings: %d | Enemy buildings: %d" % [_bs.get_total_building_count("player"), _bs.get_total_building_count("enemy")])
	_lm("Player resources: %s" % str(_gm.get_resources()))
	_lm("============================================")

	var file := FileAccess.open("user://full_game_bot_log.txt", FileAccess.WRITE)
	if file:
		file.store_string(_log)
		file.close()
	_lm("Log saved to user://full_game_bot_log.txt")
	quit()

func _init_game() -> void:
	_player_deployed.clear()
	_enemy_deployed.clear()
	_turn = 1
	_spell_plays = 0
	_situation_plays = 0
	_commander_deploys = 0
	_buffs_applied = 0
	_buildings_built = 0
	_riots_triggered = 0
	_quests_completed = 0
	_religion_turn = -1
	_ideology_turn = -1
	_enemy_religion_chosen = false
	_enemy_ideology_chosen = false

	_player_left_deck = _Deck.new()
	_player_right_deck = _Deck.new()
	_player_hand = _Hand.new(12)
	_player_left_deck.build_left_deck()
	_player_right_deck.build_right_deck()

	_enemy_left_deck = _Deck.new()
	_enemy_right_deck = _Deck.new()
	_enemy_hand = _Hand.new(12)
	_enemy_left_deck.build_left_deck()
	_enemy_right_deck.build_right_deck()

	_gm.start_game()
	_lm("Game started. Player: Svalka Zapad, Enemy: Svalka Vostok")

func _phase_resources() -> void:
	_rm.apply_income()
	_rm.apply_enemy_income()

	_check_religion_trigger()
	_check_ideology_trigger()

	if _turn == 2 and not _gm.is_state_named():
		_gm.set_state_name("Knyazhestvo Stakania")
		_lm("  State named: Knyazhestvo Stakania")

func _check_religion_trigger() -> void:
	if _gm.is_religion_chosen():
		return
	if _gm.get_player_territory_count() >= 3:
		var choices: Array = ["mnogobomzhie", "alcoteism", "etanolstvo", "trezvost"]
		var pick: String = choices[randi() % choices.size()]
		_rs.set_religion(pick)
		_gm.set_religion_chosen(true)
		_religion_turn = _turn
		_lm("  RELIGION chosen: %s (player has %d territories)" % [pick, _gm.get_player_territory_count()])

	if not _enemy_religion_chosen and _gm.get_enemy_territory_count() >= 3:
		var choices: Array = ["mnogobomzhie", "alcoteism", "etanolstvo"]
		var pick: String = choices[randi() % choices.size()]
		_enemy_religion_chosen = true
		_lm("  ENEMY also benefits from religion: %s" % pick)

func _check_ideology_trigger() -> void:
	if _gm.is_ideology_chosen():
		return
	if _gm.get_player_territory_count() >= 5:
		var pick: String = "alcoholism" if randi() % 2 == 0 else "dermocracy"
		_gm.choose_ideology(pick)
		_ideology_turn = _turn
		_lm("  IDEOLOGY chosen: %s (player has %d territories)" % [pick, _gm.get_player_territory_count()])

	if not _enemy_ideology_chosen and _gm.get_enemy_territory_count() >= 5:
		_enemy_ideology_chosen = true
		_lm("  ENEMY also benefits from ideology")

func _phase_draw() -> void:
	_refill(_player_left_deck, _player_right_deck)
	_refill(_enemy_left_deck, _enemy_right_deck)

	var right_count: int = 2
	if _gm.is_ideology_chosen():
		right_count += _is.get_extra_unit_draw()

	var drawn: int = 0
	for i in range(3):
		var c: Dictionary = _player_left_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			drawn += 1
	for i in range(right_count):
		var c: Dictionary = _player_right_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			drawn += 1
	for i in range(3):
		var c: Dictionary = _enemy_left_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			drawn += 1
	for i in range(2):
		var c: Dictionary = _enemy_right_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			drawn += 1

	_lm("  DRAW: P=%d E=%d cards in hand" % [_player_hand.size(), _enemy_hand.size()])

func _phase_play_spells_and_situations(side: String, hand: Variant, deployed: Dictionary) -> void:
	var spells: Array = hand.get_cards_by_type("spell")
	for card_data in spells:
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_afford(side, cost):
			continue
		_spend(side, cost)
		var effect_result: Dictionary = _apply_card_effect(card_data, side, deployed)
		hand.remove_by_id(card_data.get("id", ""))
		_spell_plays += 1
		_lm("  %s casts %s => %s" % [
			"P" if side == "player" else "E",
			card_data.get("id", "?"),
			_effect_summary(effect_result)])

	var situations: Array = hand.get_cards_by_type("situation")
	var to_discard: int = maxi(situations.size() - 2, 0)
	var discarded: int = 0
	for card_data in situations:
		if discarded >= to_discard:
			break
		hand.remove_by_id(card_data.get("id", ""))
		discarded += 1

	situations = hand.get_cards_by_type("situation")
	for card_data in situations:
		if card_data.get("auto_trigger", false):
			continue
		var cost: Dictionary = card_data.get("cost", {})
		if not cost.is_empty() and not _can_afford(side, cost):
			continue
		if not cost.is_empty():
			_spend(side, cost)
		var effect_result: Dictionary = _apply_card_effect(card_data, side, deployed)
		hand.remove_by_id(card_data.get("id", ""))
		_situation_plays += 1
		_lm("  %s plays %s => %s" % [
			"P" if side == "player" else "E",
			card_data.get("id", "?"),
			_effect_summary(effect_result)])
		break

func _apply_card_effect(card_data: Dictionary, side: String, deployed: Dictionary) -> Dictionary:
	var effect_type: String = card_data.get("effect_type", "")
	var amount: int = card_data.get("amount", 0)
	var result: Dictionary = {"success": true}

	match effect_type:
		"buff_attack", "pohmele_self":
			var bonus: int = amount
			var all_units: Array = _get_all_alive(deployed)
			if all_units.size() > 0:
				var target: RefCounted = all_units[randi() % all_units.size()]
				target.add_buff({"attack": bonus}, 3)
				_buffs_applied += 1
				result["buff_target"] = target.id
				result["attack_bonus"] = bonus
		"buff_defense":
			var all_units: Array = _get_all_alive(deployed)
			if all_units.size() > 0:
				var target: RefCounted = all_units[randi() % all_units.size()]
				target.add_buff({"defense": amount}, 3)
				_buffs_applied += 1
				result["defense_bonus"] = amount
		"buff_all_attack":
			for unit in _get_all_alive(deployed):
				unit.add_buff({"attack": amount}, 2)
				_buffs_applied += 1
			result["all_attack_bonus"] = amount
		"buff_all_defense":
			for unit in _get_all_alive(deployed):
				unit.add_buff({"defense": amount}, 2)
				_buffs_applied += 1
			result["all_defense_bonus"] = amount
		"debuff_attack", "pohmele_enemy":
			var enemy_deployed: Dictionary = _enemy_deployed if side == "player" else _player_deployed
			var enemies: Array = _get_all_alive(enemy_deployed)
			if enemies.size() > 0:
				var target: RefCounted = enemies[randi() % enemies.size()]
				target.add_buff({"attack": -amount}, 3)
				_buffs_applied += 1
				result["debuff_target"] = target.id
		"debuff_defense":
			var enemy_deployed: Dictionary = _enemy_deployed if side == "player" else _player_deployed
			var enemies: Array = _get_all_alive(enemy_deployed)
			if enemies.size() > 0:
				var target: RefCounted = enemies[randi() % enemies.size()]
				target.add_buff({"defense": -amount}, 3)
				_buffs_applied += 1
		"heal":
			var all_units: Array = _get_all_alive(deployed)
			for u in all_units:
				if u.current_hp < u.max_hp:
					u.heal(amount)
					result["healed"] = u.id
					break
		"resource_gain":
			var res: String = card_data.get("resource", "bottles")
			if side == "player":
				_gm.change_resource(res, amount)
			else:
				_gm.change_enemy_resource(res, amount)
			result["resource"] = res
			result["amount"] = amount
		"resource_gain_multi":
			var resources: Dictionary = card_data.get("resources", {})
			for res in resources:
				if side == "player":
					_gm.change_resource(res, resources[res])
				else:
					_gm.change_enemy_resource(res, resources[res])
			result["resources"] = resources
		"respect_change":
			_gm.change_respect(amount)
			result["respect"] = amount
		"population_change":
			_gm.change_population(amount)
			result["population"] = amount
		"production_bonus":
			_gm.change_production(amount)
			result["production"] = amount
		"bomond_bonus":
			if side == "player":
				_gm.change_resource("bottles", 5)
				_gm.change_resource("coins", 5)
			else:
				_gm.change_enemy_resource("bottles", 5)
				_gm.change_enemy_resource("coins", 5)
			result["bottles"] = 5
			result["coins"] = 5
		"bukhnut_odnogo":
			_gm.change_respect(-10)
			_gm.change_production(5)
			result["respect"] = -10
		"golod", "oblava", "steklotara":
			var pop: int = _gm.get_population()
			var pct: int = absi(amount)
			var lost: int = int(pop * pct / 100.0)
			_gm.change_population(-lost)
			result["population_lost"] = lost
		"coins_penalty_percent":
			var penalty: int = int(_gm.get_resources().get("coins", 0) * absi(amount) / 100.0)
			_gm.change_resource("coins", -penalty)
			result["coins_penalty"] = penalty
		"draw_cards":
			var deck: Variant = _player_left_deck if side == "player" else _enemy_left_deck
			var h: Variant = _player_hand if side == "player" else _enemy_hand
			for i in range(amount):
				var c: Dictionary = deck.draw_card()
				if not c.is_empty():
					h.add_card(c)
			result["drawn"] = amount
		"global_atk_buff":
			for unit in _get_all_alive(deployed):
				unit.add_buff({"attack": amount}, 99)
				_buffs_applied += 1
			result["global_atk"] = amount
		"global_def_buff":
			for unit in _get_all_alive(deployed):
				unit.add_buff({"defense": amount}, 99)
				_buffs_applied += 1
			result["global_def"] = amount
		"global_buff":
			for unit in _get_all_alive(deployed):
				unit.add_buff({"attack": amount, "defense": amount}, 99)
				_buffs_applied += 1
			result["global_buff"] = amount
		"resource_per_turn":
			var res: String = card_data.get("resource", "bottles")
			if side == "player":
				_gm.change_resource(res, amount)
			else:
				_gm.change_enemy_resource(res, amount)
			result["per_turn"] = "%s +%d" % [res, amount]
		_:
			result["success"] = true
			result["note"] = "effect '%s' applied (passive/pending)" % effect_type

	return result

func _effect_summary(result: Dictionary) -> String:
	var parts: Array = []
	if result.has("attack_bonus"):
		parts.append("ATK+%d" % result["attack_bonus"])
	if result.has("defense_bonus"):
		parts.append("DEF+%d" % result["defense_bonus"])
	if result.has("all_attack_bonus"):
		parts.append("ALL_ATK+%d" % result["all_attack_bonus"])
	if result.has("all_defense_bonus"):
		parts.append("ALL_DEF+%d" % result["all_defense_bonus"])
	if result.has("global_atk"):
		parts.append("GLOBAL_ATK+%d" % result["global_atk"])
	if result.has("global_def"):
		parts.append("GLOBAL_DEF+%d" % result["global_def"])
	if result.has("resource"):
		parts.append("%s+%d" % [result["resource"], result.get("amount", 0)])
	if result.has("resources"):
		for r in result["resources"]:
			parts.append("%s+%d" % [r, result["resources"][r]])
	if result.has("respect"):
		parts.append("respect%+d" % result["respect"])
	if result.has("population"):
		parts.append("pop%+d" % result["population"])
	if result.has("population_lost"):
		parts.append("pop-%d" % result["population_lost"])
	if result.has("production"):
		parts.append("prod+%d" % result["production"])
	if result.has("drawn"):
		parts.append("draw %d" % result["drawn"])
	if result.has("debuff_target"):
		parts.append("debuff %s" % result["debuff_target"])
	if result.has("healed"):
		parts.append("heal %s" % result["healed"])
	if result.has("note"):
		parts.append(result["note"])
	if parts.is_empty():
		return "OK"
	return " ".join(parts)

func _phase_deploy_units(side: String, hand: Variant, deployed: Dictionary) -> int:
	var count: int = 0
	var deployable: Array = hand.get_cards_by_type("unit")
	deployable.append_array(hand.get_cards_by_type("commander"))

	for card_data in deployable:
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_afford(side, cost):
			continue
		_spend(side, cost)
		var instance: RefCounted = _CardInstance.new(card_data)
		var target: String = _find_deploy_target(side, deployed)
		if target == "":
			target = "dump_west" if side == "player" else "dump_east"
		if not deployed.has(target):
			deployed[target] = []
		deployed[target].append(instance)
		instance.territory_id = target
		hand.remove_by_id(card_data.get("id", ""))
		count += 1

		if card_data.get("type", "") == "commander":
			_commander_deploys += 1
			var comm_result: Dictionary = _apply_card_effect(card_data, side, deployed)
			_lm("  %s deploys COMMANDER %s => %s" % [
				"P" if side == "player" else "E",
				card_data.get("id", "?"),
				_effect_summary(comm_result)])

	if count > 0 and _turn % 3 == 0:
		_lm("  %s deployed %d units" % ["P" if side == "player" else "E", count])
	return count

func _phase_move(side: String, deployed: Dictionary) -> int:
	var moved: int = 0
	var enemy_side: String = "enemy" if side == "player" else "player"
	var capital: String = "dump_west" if side == "player" else "dump_east"
	var enemy_capital: String = "dump_east" if side == "player" else "dump_west"
	var pf: RefCounted = _PathFinder.new()
	var territories: Array = deployed.keys().duplicate()
	territories.shuffle()

	for t_id in territories:
		var units: Array = deployed[t_id]
		var alive: Array = []
		for u in units:
			if u.is_alive():
				alive.append(u)
		if alive.is_empty():
			continue

		var is_capital: bool = (t_id == capital)
		var has_enemy_neighbor: bool = false
		var adjacent: Array = _cd.get_adjacent_territories(t_id)
		for a_id in adjacent:
			if _gm.get_territory_owner(a_id) == enemy_side:
				has_enemy_neighbor = true
				break

		var keep: int = 0
		if is_capital and has_enemy_neighbor:
			keep = 2
		elif has_enemy_neighbor:
			keep = 1

		var sendable: int = maxi(alive.size() - keep, 0)
		if sendable <= 0:
			var is_frontline: bool = false
			for a_id in adjacent:
				if _gm.get_territory_owner(a_id) != side:
					is_frontline = true
					break
			if not is_frontline:
				sendable = alive.size()
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
			elif adj_owner == "neutral":
				score += 7.0
				score += td.get("resource_bottles", 0) * 1.0
				score += td.get("resource_coins", 0) * 1.5
			else:
				var adj_adj: Array = _cd.get_adjacent_territories(adj_id)
				for aa_id in adj_adj:
					if _gm.get_territory_owner(aa_id) == enemy_side:
						score += 3.0
					elif _gm.get_territory_owner(aa_id) == "neutral":
						score += 1.0
				if score <= 0:
					score -= 5.0

			if score > best_score:
				best_score = score
				best_target = adj_id

		if best_target == "" or best_score <= -4.0:
			var path: Array = pf.find_path(t_id, enemy_capital)
			if path.size() > 1:
				best_target = path[1]

		if best_target != "":
			var to_send: int = mini(sendable, 3)
			for i in range(to_send):
				if alive.is_empty():
					break
				var unit: RefCounted = alive.pop_front()
				units.erase(unit)
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
	if contested.is_empty():
		return

	var resolver: RefCounted = _BattleResolver.new()

	for t_id in contested:
		var p_units: Array = _player_deployed[t_id]
		var e_units: Array = _enemy_deployed[t_id]
		var territory: Dictionary = _cd.get_territory(t_id)

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

		var t_owner: String = _gm.get_territory_owner(t_id)
		var player_is_attacker: bool = false if t_owner == "player" else true if t_owner == "enemy" else alive_p.size() >= alive_e.size()

		var attackers: Array = p_units if player_is_attacker else e_units
		var defenders: Array = e_units if player_is_attacker else p_units

		var result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)

		var attacker_won: bool = result.get("player_won", false)
		var winner: String
		if player_is_attacker:
			winner = "player" if attacker_won else "enemy"
		else:
			winner = "enemy" if attacker_won else "player"

		_gm.set_territory_owner(t_id, winner)

		if winner == "player":
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

		_lm("  BATTLE %s [%s]: %dP vs %dE => %s WINS" % [
			t_id, territory.get("terrain", "?"),
			alive_p.size(), alive_e.size(),
			"PLAYER" if winner == "player" else "ENEMY"])

	_capture_uncontested(_player_deployed, "player")
	_capture_uncontested(_enemy_deployed, "enemy")

func _phase_events() -> void:
	var trigger: RefCounted = _EventTrigger.new()
	var checked: Array = []
	for t_id in _player_deployed:
		if checked.has(t_id):
			continue
		checked.append(t_id)
		var triggered: Array = trigger.check_events(t_id, {"owner": "player"})
		for evt in triggered:
			_lm("  EVENT at %s: %s" % [t_id, str(evt)])

func _phase_build() -> void:
	var building_ids: Array = _bs.get_all_building_ids()
	var p_targets: Array = []
	var e_targets: Array = []
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] == "player":
			p_targets.append(t_id)
		elif _gm._territory_owners[t_id] == "enemy":
			e_targets.append(t_id)
	
	if p_targets.size() > 0:
		var b_id: String = building_ids[randi() % building_ids.size()]
		var t_id: String = p_targets[randi() % p_targets.size()]
		if _bs.can_build(b_id, t_id, "player"):
			_bs.build(b_id, t_id, "player")
			_buildings_built += 1
			if _turn % 5 == 0:
				_lm("  P builds %s at %s" % [b_id, t_id])
	
	if e_targets.size() > 0:
		var b_id: String = building_ids[randi() % building_ids.size()]
		var t_id: String = e_targets[randi() % e_targets.size()]
		if _bs.can_build(b_id, t_id, "enemy"):
			_bs.build(b_id, t_id, "enemy")
			_buildings_built += 1

func _phase_happiness() -> void:
	var p_delta: int = _hs.apply_happiness_turn("player")
	var e_delta: int = _hs.apply_happiness_turn("enemy")
	
	_bs.apply_per_turn_effects("player")
	_bs.apply_per_turn_effects("enemy")
	
	var p_riot: Dictionary = _rts.check_and_trigger_riot("player")
	var e_riot: Dictionary = _rts.check_and_trigger_riot("enemy")
	
	if p_riot.get("rioted", false):
		_riots_triggered += 1
		_lm("  !! PLAYER RIOT! Reason: %s | Effects: %s" % [p_riot.get("reason", "?"), str(p_riot.get("effects", {}))])
	if e_riot.get("rioted", false):
		_riots_triggered += 1
		_lm("  !! ENEMY RIOT! Reason: %s" % e_riot.get("reason", "?"))
	
	if _turn % 5 == 0:
		_lm("  HAPPINESS: P=%d(%+d) E=%d(%+d)" % [
			_hs.get_happiness("player"), p_delta,
			_hs.get_happiness("enemy"), e_delta])

func _phase_quests() -> void:
	var p_steps: Array = _qs.check_all_quests("player")
	var e_steps: Array = _qs.check_all_quests("enemy")
	for step_info in p_steps:
		_lm("  QUEST STEP: %s step %d" % [step_info.quest, step_info.step])
		if _qs.is_quest_completed(step_info.quest, "player"):
			_quests_completed += 1
			_lm("  QUEST COMPLETED: %s!" % step_info.quest)
	_qs.check_all_quests("enemy")

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

	var growth: int = _is.get_population_growth_mod() if _gm.is_ideology_chosen() else 0
	if growth != 0:
		_gm.change_population(growth)

func _find_deploy_target(side: String, deployed: Dictionary) -> String:
	var enemy_side: String = "enemy" if side == "player" else "player"
	var capital: String = "dump_west" if side == "player" else "dump_east"

	var frontline: Array = []
	for t_id in _gm._territory_owners:
		if _gm._territory_owners[t_id] != side:
			continue
		for a_id in _cd.get_adjacent_territories(t_id):
			if _gm.get_territory_owner(a_id) != side:
				frontline.append(t_id)
				break

	var best: String = ""
	var best_score: float = -999.0
	for f_id in frontline:
		var score: float = 0.0
		var td: Dictionary = _cd.get_territory(f_id)
		var enemy_n: int = 0
		for a_id in _cd.get_adjacent_territories(f_id):
			if _gm.get_territory_owner(a_id) == enemy_side:
				enemy_n += 1
		score += enemy_n * 3.0
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
		if score > best_score:
			best_score = score
			best = f_id

	if best != "":
		return best
	return capital

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

func _refill(left: Variant, right: Variant) -> void:
	if left.is_empty() and right.is_empty():
		left.build_left_deck()
		right.build_right_deck()

func _capture_uncontested(deployed: Dictionary, side: String) -> void:
	for t_id in deployed:
		var has_alive: bool = false
		for u in deployed[t_id]:
			if u.is_alive():
				has_alive = true
				break
		if has_alive:
			_gm.set_territory_owner(t_id, side)

func _get_all_alive(deployed: Dictionary) -> Array:
	var result: Array = []
	for t_id in deployed:
		for u in deployed[t_id]:
			if u.is_alive():
				result.append(u)
	return result

func _count_alive(deployed: Dictionary) -> int:
	return _get_all_alive(deployed).size()

func _check_victory() -> String:
	if _gm.get_territory_owner("dump_east") == "player":
		return "PLAYER captured enemy capital"
	if _gm.get_territory_owner("dump_west") == "enemy":
		return "ENEMY captured player capital"
	var p: int = _gm.get_player_territory_count()
	var e: int = _gm.get_enemy_territory_count()
	if _turn >= _max_turns:
		if p > e:
			return "PLAYER wins by territory (%d vs %d)" % [p, e]
		elif e > p:
			return "ENEMY wins by territory (%d vs %d)" % [e, p]
		else:
			return "DRAW"
	return ""

func _print_status() -> void:
	var p_res: Dictionary = _gm.get_resources()
	_lm("  STATUS: P=%dterr %dunits | E=%dterr %dunits | pop=%d respect=%d | happy: P=%d E=%d | bld: P=%d E=%d | res: b=%d c=%d r=%d cb=%d al=%d" % [
		_gm.get_player_territory_count(), _count_alive(_player_deployed),
		_gm.get_enemy_territory_count(), _count_alive(_enemy_deployed),
		_gm.get_population(), _gm.get_respect(),
		_hs.get_happiness("player"), _hs.get_happiness("enemy"),
		_bs.get_total_building_count("player"), _bs.get_total_building_count("enemy"),
		p_res.get("bottles", 0), p_res.get("coins", 0),
		p_res.get("rolltons", 0), p_res.get("cardboard", 0),
		p_res.get("aluminum", 0)])
