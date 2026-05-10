extends RefCounted

const DeckScript := preload("res://scripts/cards/deck.gd")
const HandScript := preload("res://scripts/cards/hand.gd")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const PathFinderScript := preload("res://scripts/map/path_finder.gd")

var id: String = "player"
var display_name: String = "Синие"
var accent_color: Color = Color(0.3, 0.6, 1.0)
var _left_deck: RefCounted = null
var _right_deck: RefCounted = null
var _hand: RefCounted = null
var _deployed: Dictionary = {}

func _init(player_id: String, player_name: String, color: Color) -> void:
	id = player_id
	display_name = player_name
	accent_color = color
	_hand = HandScript.new(12)

func init_decks() -> void:
	_left_deck = DeckScript.new()
	_right_deck = DeckScript.new()
	_left_deck.build_left_deck()
	_right_deck.build_right_deck()
	_deployed.clear()

func get_resources() -> Dictionary:
	if id == "player":
		return GameManager.get_resources()
	return GameManager.get_enemy_resources()

func change_resource(res: String, amount: int) -> void:
	if id == "player":
		GameManager.change_resource(res, amount)
	else:
		GameManager.change_enemy_resource(res, amount)

func can_afford(cost: Dictionary) -> bool:
	var res := get_resources()
	for r in cost:
		if res.get(r, 0) < cost[r]:
			return false
	return true

func spend(cost: Dictionary) -> void:
	for r in cost:
		change_resource(r, -cost[r])

func get_hand() -> RefCounted:
	return _hand

func get_deployed() -> Dictionary:
	return _deployed

func phase_income() -> Dictionary:
	var income := {"bottles": 0, "aluminum": 0, "coins": 0, "rolltons": 0, "cardboard": 0}
	var t_count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == id:
			var t := CardDatabase.get_territory(t_id)
			income["bottles"] += t.get("resource_bottles", 0)
			income["aluminum"] += t.get("resource_aluminum", 0)
			income["coins"] += t.get("resource_coins", 0)
			income["rolltons"] += t.get("resource_rolltons", 0)
			income["cardboard"] += t.get("resource_cardboard", 0)
			t_count += 1
	for r in income:
		change_resource(r, income[r])
	return {"type": "income", "player": display_name, "income": income, "territories": t_count}

func phase_draw() -> Dictionary:
	if _left_deck == null:
		init_decks()
	if _left_deck.is_empty() and _right_deck.is_empty():
		_left_deck.build_left_deck()
		_right_deck.build_right_deck()
	var drawn: Array = []
	for i in range(3):
		var c: Dictionary = _left_deck.draw_card()
		if not c.is_empty() and _hand.add_card(c):
			drawn.append(c.get("name_ru", c.get("id", "")))
	for i in range(2):
		var c: Dictionary = _right_deck.draw_card()
		if not c.is_empty() and _hand.add_card(c):
			drawn.append(c.get("name_ru", c.get("id", "")))
	return {"type": "draw", "player": display_name, "cards": drawn}

func phase_play_cards() -> Dictionary:
	var played: Array = []
	var spells: Array = _hand.get_cards_by_type("spell")
	var count: int = 0
	for card_data in spells:
		if count >= 2:
			break
		var cost: Dictionary = card_data.get("cost", {})
		if not can_afford(cost):
			continue
		spend(cost)
		_apply_effect(card_data)
		_hand.remove_by_id(card_data.get("id", ""))
		count += 1
		played.append(card_data.get("name_ru", ""))
	var situations: Array = _hand.get_cards_by_type("situation")
	for card_data in situations:
		if count >= 3:
			break
		if card_data.get("auto_trigger", false):
			continue
		var cost: Dictionary = card_data.get("cost", {})
		if not cost.is_empty() and not can_afford(cost):
			continue
		if not cost.is_empty():
			spend(cost)
		_apply_effect(card_data)
		_hand.remove_by_id(card_data.get("id", ""))
		count += 1
		played.append(card_data.get("name_ru", ""))
	return {"type": "play", "player": display_name, "cards": played}

func _apply_effect(data: Dictionary) -> void:
	var effect: String = data.get("effect_type", "")
	var amount: int = data.get("amount", 0)
	match effect:
		"resource_gain":
			change_resource(data.get("resource", "bottles"), amount)
		"resource_gain_multi":
			for res in data.get("resources", {}):
				change_resource(res, data["resources"][res])
		"respect_change":
			if id == "player":
				GameManager.change_respect(amount)
			else:
				GameManager.change_enemy_respect(amount)
		"population_change":
			GameManager.change_population(amount)
		"buff_all_attack":
			for t_id in _deployed:
				for unit in _deployed[t_id]:
					unit.add_buff({"attack": amount}, 2)
		"buff_all_defense":
			for t_id in _deployed:
				for unit in _deployed[t_id]:
					unit.add_buff({"defense": amount}, 2)
		"production_bonus":
			GameManager.change_production(amount)

func phase_deploy() -> Dictionary:
	var units: Array = _hand.get_cards_by_type("unit")
	var commanders: Array = _hand.get_cards_by_type("commander")
	var all_cards: Array = []
	for u in units:
		all_cards.append(u)
	for c in commanders:
		all_cards.append(c)
	var deployed: Array = []
	for card_data in all_cards:
		var cost: Dictionary = card_data.get("cost", {})
		if not can_afford(cost):
			continue
		spend(cost)
		var instance: RefCounted = CardInstanceScript.new(card_data)
		var target: String = _find_deploy_target()
		if target != "":
			if not _deployed.has(target):
				_deployed[target] = []
			_deployed[target].append(instance)
			instance.territory_id = target
			_hand.remove_by_id(card_data.get("id", ""))
			var t_name: String = CardDatabase.get_territory(target).get("name_ru", target)
			deployed.append({"card": card_data.get("name_ru", ""), "territory": t_name, "t_id": target})
	return {"type": "deploy", "player": display_name, "units": deployed}

func _find_deploy_target() -> String:
	var my_capital: String = "dump_east" if id == "enemy" else "dump_west"
	var other_id := "enemy" if id == "player" else "player"
	var frontline: Array = []
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == id:
			for a_id in CardDatabase.get_adjacent_territories(t_id):
				if GameManager.get_territory_owner(a_id) != id:
					frontline.append(t_id)
					break
	if frontline.is_empty():
		if GameManager._territory_owners.has(my_capital) and GameManager._territory_owners[my_capital] == id:
			return my_capital
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == id:
				return t_id
		return ""
	var best: String = ""
	var best_score: float = -999.0
	for f_id in frontline:
		var score: float = 0.0
		var td := CardDatabase.get_territory(f_id)
		var enemy_n: int = 0
		for a_id in CardDatabase.get_adjacent_territories(f_id):
			if GameManager.get_territory_owner(a_id) == other_id:
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
		if td.get("terrain", "") in ["dump", "station"]:
			score += 2.0
		if score > best_score:
			best_score = score
			best = f_id
	return best if best != "" else my_capital

func phase_move() -> Dictionary:
	var pf := PathFinderScript.new()
	var other_id := "enemy" if id == "player" else "player"
	var territories := _deployed.keys().duplicate()
	territories.shuffle()
	var moves: Array = []
	for t_id in territories:
		var units: Array = _deployed[t_id]
		var alive: Array = []
		for u in units:
			if u.is_alive():
				alive.append(u)
		if alive.is_empty():
			continue
		var adjacent := CardDatabase.get_adjacent_territories(t_id)
		var has_enemy_neighbor: bool = false
		var enemy_adjacent_ids: Array = []
		for a_id in adjacent:
			if GameManager.get_territory_owner(a_id) == other_id:
				has_enemy_neighbor = true
				enemy_adjacent_ids.append(a_id)
		var keep: int = 1
		if alive.size() <= 2 and not has_enemy_neighbor:
			keep = 1
		elif has_enemy_neighbor and alive.size() >= 5:
			keep = 2
		if has_enemy_neighbor and alive.size() >= 2:
			var attack_target: String = ""
			var atk_score: float = -999.0
			for e_id in enemy_adjacent_ids:
				var td := CardDatabase.get_territory(e_id)
				var sc: float = 15.0
				if td.get("is_capital", false):
					sc += 25.0
				if td.get("terrain", "") == "dump":
					sc += 10.0
				if td.get("terrain", "") == "station":
					sc += 8.0
				if sc > atk_score:
					atk_score = sc
					attack_target = e_id
			if attack_target != "":
				var atk_count: int = mini(alive.size() - keep, alive.size())
				if atk_count <= 0:
					atk_count = alive.size()
				var sending: Array = alive.duplicate()
				sending.resize(atk_count)
				for unit in sending:
					units.erase(unit)
					if not _deployed.has(attack_target):
						_deployed[attack_target] = []
					_deployed[attack_target].append(unit)
					unit.territory_id = attack_target
				var from_name: String = CardDatabase.get_territory(t_id).get("name_ru", t_id)
				var to_name: String = CardDatabase.get_territory(attack_target).get("name_ru", attack_target)
				moves.append({"from": from_name, "to": to_name, "from_id": t_id, "to_id": attack_target, "count": atk_count})
				continue
		var sendable := alive.duplicate()
		var send_count: int = maxi(alive.size() - keep, 0)
		if send_count == 0:
			continue
		sendable.resize(send_count)
		var best_target: String = ""
		var best_score: float = -999.0
		var best_path: Array = []
		for unit in sendable:
			var max_move: int = unit.movement
			var reachable := pf.get_reachable_territories(t_id, float(max_move))
			for r_id in reachable:
				var r_owner := GameManager.get_territory_owner(r_id)
				var td := CardDatabase.get_territory(r_id)
				var score: float = 0.0
				if r_owner == other_id:
					score += 15.0
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
			var to_send: int = mini(sendable.size(), 3)
			for i in range(to_send):
				if sendable.is_empty():
					break
				var unit: RefCounted = sendable.pop_front()
				units.erase(unit)
				if not _deployed.has(path_target):
					_deployed[path_target] = []
				_deployed[path_target].append(unit)
				unit.territory_id = path_target
			var from_name: String = CardDatabase.get_territory(t_id).get("name_ru", t_id)
			var to_name: String = CardDatabase.get_territory(path_target).get("name_ru", path_target)
			moves.append({"from": from_name, "to": to_name, "from_id": t_id, "to_id": path_target, "count": to_send})
	return {"type": "move", "player": display_name, "moves": moves}

func phase_end() -> Dictionary:
	var captured: Array = []
	for t_id in _deployed:
		for unit in _deployed[t_id]:
			unit.tick_buffs()
			if unit.is_alive():
				unit.heal(1)
	for t_id in _deployed:
		var has_alive: bool = false
		for u in _deployed[t_id]:
			if u.is_alive():
				has_alive = true
				break
		if has_alive:
			var old_owner := GameManager.get_territory_owner(t_id)
			if old_owner != id:
				GameManager.set_territory_owner(t_id, id)
				var t_name: String = CardDatabase.get_territory(t_id).get("name_ru", t_id)
				captured.append(t_name)
	return {"type": "end", "player": display_name, "captured": captured, "units_alive": count_alive()}

func count_alive() -> int:
	var count: int = 0
	for t_id in _deployed:
		for u in _deployed[t_id]:
			if u.is_alive():
				count += 1
	return count

func count_territories() -> int:
	var count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == id:
			count += 1
	return count
