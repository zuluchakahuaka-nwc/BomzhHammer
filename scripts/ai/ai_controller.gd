extends Node

enum Strategy { CONSERVATIVE, AGGRESSIVE, BALANCED }

const DeckScript := preload("res://scripts/cards/deck.gd")
const HandScript := preload("res://scripts/cards/hand.gd")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const BattleResolverScript := preload("res://scripts/combat/battle_resolver.gd")
const PathFinderScript := preload("res://scripts/map/path_finder.gd")
const CardEffectScript := preload("res://scripts/cards/card_effect.gd")

var _strategy: Strategy = Strategy.BALANCED
var _left_deck: RefCounted = null
var _right_deck: RefCounted = null
var _hand: RefCounted = null
var _deployed: Dictionary = {}
var _combat_results: Array = []

func _ready() -> void:
	pass

func set_strategy(strategy: Strategy) -> void:
	_strategy = strategy

func init_decks() -> void:
	_left_deck = DeckScript.new()
	_right_deck = DeckScript.new()
	_hand = HandScript.new(12)
	_left_deck.build_left_deck()
	_right_deck.build_right_deck()
	_combat_results.clear()

func execute_full_turn() -> Dictionary:
	var result := {}
	result["income"] = _phase_income()
	result["draw"] = _phase_draw()
	result["spells"] = _phase_play_cards()
	result["deploy"] = _phase_deploy()
	result["move"] = _phase_move()
	result["combat"] = _phase_combat()
	result["capture"] = _phase_capture()
	result["events"] = _phase_events()
	result["end"] = _phase_end()
	return result

func execute_pre_combat() -> Dictionary:
	var result := {}
	result["income"] = _phase_income()
	result["draw"] = _phase_draw()
	result["spells"] = _phase_play_cards()
	result["deploy"] = _phase_deploy()
	result["move"] = _phase_move()
	return result

func execute_post_combat() -> Dictionary:
	var result := {}
	result["capture"] = _phase_capture()
	result["events"] = _phase_events()
	result["end"] = _phase_end()
	return result

func get_enemy_contested() -> Array:
	var player_deployed := _get_player_deployed()
	var contested := []
	for t_id in _deployed:
		if player_deployed.has(t_id):
			contested.append(t_id)
	return contested

func _phase_income() -> Dictionary:
	var rm: Node = get_node_or_null("/root/ResourceManager")
	if rm != null:
		rm.apply_enemy_income()
	if GameManager.is_ideology_chosen():
		var growth: int = IdeologySystem.get_population_growth_mod()
		if growth != 0:
			GameManager.change_population(growth)
	var income: Dictionary = rm.calculate_enemy_income() if rm != null else {}
	return {"income": income}

func _phase_draw() -> Dictionary:
	if _left_deck == null:
		init_decks()
	if _left_deck.is_empty() and _right_deck.is_empty():
		_left_deck.build_left_deck()
		_right_deck.build_right_deck()
	var drawn: int = 0
	for i in range(3):
		var c: Dictionary = _left_deck.draw_card()
		if not c.is_empty() and _hand.add_card(c):
			drawn += 1
	var right_count: int = 2
	for i in range(right_count):
		var c: Dictionary = _right_deck.draw_card()
		if not c.is_empty() and _hand.add_card(c):
			drawn += 1
	while _hand.size() > 12:
		var non_units: Array = _hand.get_cards_by_type("situation")
		if non_units.size() > 0:
			_hand.remove_by_id(non_units[0].get("id", ""))
		else:
			var all: Array = _hand.get_all()
			if all.size() > 0:
				_hand.remove_by_id(all[0].get("id", ""))
			else:
				break
	return {"drawn": drawn, "hand_size": _hand.size()}

func _phase_play_cards() -> Dictionary:
	var played: int = 0
	var spells: Array = _hand.get_cards_by_type("spell")
	for card_data in spells:
		if played >= 2:
			break
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_afford(cost):
			continue
		_spend(cost)
		_apply_effect(card_data)
		_hand.remove_by_id(card_data.get("id", ""))
		played += 1
	var situations: Array = _hand.get_cards_by_type("situation")
	for card_data in situations:
		if played >= 3:
			break
		if card_data.get("auto_trigger", false):
			continue
		var cost: Dictionary = card_data.get("cost", {})
		if not cost.is_empty() and not _can_afford(cost):
			continue
		if not cost.is_empty():
			_spend(cost)
		_apply_effect(card_data)
		_hand.remove_by_id(card_data.get("id", ""))
		played += 1
	return {"played": played}

func _apply_effect(data: Dictionary) -> void:
	var effect: String = data.get("effect_type", "")
	var amount: int = data.get("amount", 0)
	match effect:
		"resource_gain":
			var res: String = data.get("resource", "bottles")
			GameManager.change_enemy_resource(res, amount)
		"resource_gain_multi":
			var resources: Dictionary = data.get("resources", {})
			for res in resources:
				GameManager.change_enemy_resource(res, resources[res])
		"respect_change":
			GameManager.change_enemy_respect(amount)
		"population_change":
			GameManager.change_population(amount)
		"production_bonus":
			GameManager.change_production(amount)
		"buff_all_attack", "buff_all_defense":
			for t_id in _deployed:
				for unit in _deployed[t_id]:
					if effect == "buff_all_attack":
						unit.add_buff({"attack": amount}, 2)
					else:
						unit.add_buff({"defense": amount}, 2)
		"coins_penalty_percent":
			pass

func _phase_deploy() -> Dictionary:
	var deployed_count: int = 0
	var units: Array = _hand.get_cards_by_type("unit")
	var commanders: Array = _hand.get_cards_by_type("commander")
	var all: Array = []
	for u in units:
		all.append(u)
	for c in commanders:
		all.append(c)
	for card_data in all:
		var cost: Dictionary = card_data.get("cost", {})
		if not _can_afford(cost):
			continue
		_spend(cost)
		var instance: RefCounted = CardInstanceScript.new(card_data)
		var target: String = _find_deploy_target()
		if target != "":
			if not _deployed.has(target):
				_deployed[target] = []
			_deployed[target].append(instance)
			instance.territory_id = target
			_hand.remove_by_id(card_data.get("id", ""))
			deployed_count += 1
	return {"deployed": deployed_count, "total_units": _count_alive()}

func _find_deploy_target() -> String:
	var capital: String = "dump_east"
	var capital_threatened: bool = false
	var adj: Array = CardDatabase.get_adjacent_territories(capital)
	for a_id in adj:
		if GameManager.get_territory_owner(a_id) == "player":
			capital_threatened = true
			break
	var capital_units: int = 0
	if _deployed.has(capital):
		for u in _deployed[capital]:
			if u.is_alive():
				capital_units += 1
	if capital_threatened and capital_units < 2:
		return capital
	var frontline: Array = []
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "enemy":
			for a_id in CardDatabase.get_adjacent_territories(t_id):
				if GameManager.get_territory_owner(a_id) != "enemy":
					frontline.append(t_id)
					break
	if frontline.is_empty():
		if GameManager._territory_owners.has(capital):
			return capital
		return ""
	var best: String = ""
	var best_score: float = -999.0
	for f_id in frontline:
		var score: float = 0.0
		var td: Dictionary = CardDatabase.get_territory(f_id)
		var enemy_n: int = 0
		for a_id in CardDatabase.get_adjacent_territories(f_id):
			if GameManager.get_territory_owner(a_id) == "player":
				enemy_n += 1
		score += enemy_n * 3.0
		var deployed_here: int = 0
		if _deployed.has(f_id):
			for u in _deployed[f_id]:
				if u.is_alive():
					deployed_here += 1
		if deployed_here == 0:
			score += 3.0
		elif deployed_here >= 4:
			score -= 2.0
		if td.get("terrain", "") == "dump":
			score += 2.0
		if score > best_score:
			best_score = score
			best = f_id
	if best != "":
		return best
	return capital

func _phase_move() -> Dictionary:
	var moved: int = 0
	var pf: RefCounted = PathFinderScript.new()
	var territories: Array = _deployed.keys().duplicate()
	territories.shuffle()
	for t_id in territories:
		var units: Array = _deployed[t_id]
		var alive: Array = []
		for u in units:
			if u.is_alive():
				alive.append(u)
		if alive.is_empty():
			continue
		var is_capital: bool = (t_id == "dump_east")
		var adjacent: Array = CardDatabase.get_adjacent_territories(t_id)
		var has_player_neighbor: bool = false
		for a_id in adjacent:
			if GameManager.get_territory_owner(a_id) == "player":
				has_player_neighbor = true
				break
		var keep: int = 0
		if is_capital and has_player_neighbor:
			keep = 2
		elif has_player_neighbor:
			keep = 1
		elif alive.size() > 3:
			keep = 1
		var sendable_units: Array = alive.duplicate()
		sendable_units.resize(maxi(alive.size() - keep, 0))
		if sendable_units.is_empty():
			continue
		var best_target: String = ""
		var best_score: float = -999.0
		var best_path: Array = []
		for unit in sendable_units:
			var max_move: int = unit.movement
			var reachable: Array = pf.get_reachable_territories(t_id, float(max_move))
			for r_id in reachable:
				var r_owner: String = GameManager.get_territory_owner(r_id)
				var td: Dictionary = CardDatabase.get_territory(r_id)
				var score: float = 0.0
				if r_owner == "player":
					score += 12.0
					if td.get("is_capital", false):
						score += 25.0
					if td.get("terrain", "") == "dump":
						score += 8.0
				elif r_owner == "neutral":
					score += 7.0
					score += td.get("resource_bottles", 0) * 1.0
					score += td.get("resource_coins", 0) * 1.5
				else:
					score -= 5.0
				if score > best_score:
					best_score = score
					best_target = r_id
					best_path = pf.find_path(t_id, r_id)
		if best_target != "" and best_score > -4.0 and best_path.size() > 1:
			var path_target: String = best_path[1]
			var to_send: int = mini(sendable_units.size(), 3)
			for i in range(to_send):
				if sendable_units.is_empty():
					break
				var unit: RefCounted = sendable_units.pop_front()
				units.erase(unit)
				if not _deployed.has(path_target):
					_deployed[path_target] = []
				_deployed[path_target].append(unit)
				unit.territory_id = path_target
				moved += 1
	return {"moved": moved}

func _phase_combat() -> Dictionary:
	_combat_results.clear()
	var player_deployed: Dictionary = _get_player_deployed()
	var contested: Array = []
	for t_id in player_deployed:
		if _deployed.has(t_id):
			contested.append(t_id)
	var resolver: RefCounted = BattleResolverScript.new()
	for t_id in contested:
		var p_units: Array = player_deployed[t_id]
		var e_units: Array = _deployed[t_id]
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
		var territory: Dictionary = CardDatabase.get_territory(t_id)
		var t_owner: String = GameManager.get_territory_owner(t_id)
		var enemy_is_attacker: bool = false
		if t_owner == "enemy":
			enemy_is_attacker = false
		elif t_owner == "player":
			enemy_is_attacker = true
		else:
			enemy_is_attacker = alive_e.size() >= alive_p.size()
		var attackers: Array = e_units if enemy_is_attacker else p_units
		var defenders: Array = p_units if enemy_is_attacker else e_units
		var result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)
		var attacker_won: bool = result.get("player_won", false)
		var winner: String
		if enemy_is_attacker:
			winner = "enemy" if attacker_won else "player"
		else:
			winner = "player" if attacker_won else "enemy"
		if winner == "enemy":
			GameManager.set_territory_owner(t_id, "enemy")
			player_deployed.erase(t_id)
			var alive: Array = []
			for u in e_units:
				if u.is_alive():
					alive.append(u)
			_deployed[t_id] = alive
		else:
			GameManager.set_territory_owner(t_id, "player")
			_deployed.erase(t_id)
		_combat_results.append({"territory": t_id, "winner": winner})
	return {"battles": _combat_results.size(), "results": _combat_results}

func _phase_capture() -> Dictionary:
	var captured: int = 0
	for t_id in _deployed:
		var has_alive: bool = false
		for u in _deployed[t_id]:
			if u.is_alive():
				has_alive = true
				break
		if has_alive:
			var old_owner: String = GameManager.get_territory_owner(t_id)
			if old_owner != "enemy":
				GameManager.set_territory_owner(t_id, "enemy")
				captured += 1
	return {"captured": captured}

func _phase_events() -> Dictionary:
	return {"events": 0}

func _phase_end() -> Dictionary:
	for t_id in _deployed:
		for unit in _deployed[t_id]:
			unit.tick_buffs()
			if unit.is_alive():
				unit.heal(1)
	return {"units_alive": _count_alive(), "territories": GameManager.get_enemy_territory_count()}

func _get_player_deployed() -> Dictionary:
	return GameManager.get_player_deployed()

func _can_afford(cost: Dictionary) -> bool:
	var res: Dictionary = GameManager.get_enemy_resources()
	for r in cost:
		if res.get(r, 0) < cost[r]:
			return false
	return true

func _spend(cost: Dictionary) -> void:
	for r in cost:
		GameManager.change_enemy_resource(r, -cost[r])

func _count_alive() -> int:
	var count: int = 0
	for t_id in _deployed:
		for u in _deployed[t_id]:
			if u.is_alive():
				count += 1
	return count

func get_deployed() -> Dictionary:
	return _deployed

func get_hand_size() -> int:
	return _hand.size() if _hand != null else 0

func get_combat_results() -> Array:
	return _combat_results
