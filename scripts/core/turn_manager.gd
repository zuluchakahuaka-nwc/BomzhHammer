extends RefCounted

signal religion_choice_required
signal naming_required
signal ideology_choice_required

var _DeckScript: GDScript
var _HandScript: GDScript
var _EventTriggerScript: GDScript

var _player_left_deck: RefCounted
var _player_right_deck: RefCounted
var _player_hand: RefCounted
var _enemy_left_deck: RefCounted
var _enemy_right_deck: RefCounted
var _enemy_hand: RefCounted

var _player_deployed: Dictionary = {}
var _enemy_deployed: Dictionary = {}
var _combat_log: Array = []
var _turn_log: Array = []
var _current_turn: int = 1
var _pending_religion: bool = false
var _pending_naming: bool = false
var _pending_ideology: bool = false
var _name_suggestion_index: int = 0

var _STATE_NAMES: Array = [
	"Пьяная Империя",
	"Страна Ветров и Перегара",
	"Княжество Стакания",
	"Герцогство Бухарское",
	"Монетный Двор Великого Владыки Алюминя",
	"Высокий Прованс Тухлых Сыров",
	"Непризнанное Государство Микропластик"
]

var _RELIGION_CHOICES: Array = [
	{"id": "mnogobomzhie", "name": "Многобомжие", "desc": "Атака всех отрядов +1"},
	{"id": "alcoteism", "name": "Алкотеизм", "desc": "Мелочишка +2 с каждой захваченной точки"},
	{"id": "etanolstvo", "name": "Этанольство", "desc": "Алюминь +1, Бутылки +1, Картон +1 с каждой точки"},
	{"id": "trezvost", "name": "Трезвость", "desc": "Алкогольные карты заблокированы, строительство +2"}
]

func _init() -> void:
	_DeckScript = load("res://scripts/cards/deck.gd")
	_HandScript = load("res://scripts/cards/hand.gd")
	_EventTriggerScript = load("res://scripts/combat/event_trigger.gd")

func new_game() -> void:
	_player_deployed.clear()
	_enemy_deployed.clear()
	_combat_log.clear()
	_turn_log.clear()
	_pending_religion = false
	_pending_naming = false
	_pending_ideology = false
	_name_suggestion_index = 0

	_player_left_deck = _DeckScript.new()
	_player_right_deck = _DeckScript.new()
	_player_left_deck.build_left_deck()
	_player_right_deck.build_right_deck()
	_player_hand = _HandScript.new(7)

	_enemy_left_deck = _DeckScript.new()
	_enemy_right_deck = _DeckScript.new()
	_enemy_left_deck.build_left_deck()
	_enemy_right_deck.build_right_deck()
	_enemy_hand = _HandScript.new(7)

	GameManager.start_game()
	_current_turn = 1

func get_religion_choices() -> Array:
	return _RELIGION_CHOICES.duplicate(true)

func get_current_name_suggestion() -> String:
	if _name_suggestion_index < _STATE_NAMES.size():
		return _STATE_NAMES[_name_suggestion_index]
	return ""

func get_next_name_suggestion() -> String:
	_name_suggestion_index = (_name_suggestion_index + 1) % _STATE_NAMES.size()
	return _STATE_NAMES[_name_suggestion_index]

func choose_religion(religion_id: String) -> void:
	ReligionSystem.set_religion(religion_id)
	GameManager.set_religion_chosen(true)
	_pending_religion = false
	Logger.info("TurnManager", "Religion chosen: %s" % religion_id)

func choose_state_name(name: String) -> void:
	GameManager.set_state_name(name)
	_pending_naming = false
	Logger.info("TurnManager", "State named: %s" % name)

func is_religion_pending() -> bool:
	return _pending_religion

func is_naming_pending() -> bool:
	return _pending_naming

func is_ideology_pending() -> bool:
	return _pending_ideology

func choose_ideology(ideology_id: String) -> void:
	GameManager.choose_ideology(ideology_id)
	_pending_ideology = false
	Logger.info("TurnManager", "Ideology chosen: %s" % ideology_id)

func execute_resource_phase() -> Dictionary:
	_check_naming()
	ResourceManager.apply_income()
	ResourceManager.apply_enemy_income()
	var result := {
		"player_income": ResourceManager.calculate_income(),
		"enemy_income": ResourceManager.calculate_enemy_income(),
		"player_resources": GameManager.get_resources().duplicate(true),
		"enemy_resources": GameManager.get_enemy_resources().duplicate(true),
		"naming_pending": _pending_naming,
		"religion_pending": _pending_religion,
		"ideology_pending": _pending_ideology
	}
	_turn_log.append({"phase": "resources", "result": result})
	return result

func execute_draw_phase() -> Dictionary:
	var player_drawn := 0
	for i in range(3):
		var c: Dictionary = _player_left_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			player_drawn += 1
	var right_draw_count: int = 2
	if GameManager.is_ideology_chosen():
		right_draw_count += IdeologySystem.get_extra_unit_draw()
	for i in range(right_draw_count):
		var c: Dictionary = _player_right_deck.draw_card()
		if not c.is_empty() and _player_hand.add_card(c):
			player_drawn += 1

	var enemy_drawn := 0
	for i in range(3):
		var c: Dictionary = _enemy_left_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			enemy_drawn += 1
	for i in range(2):
		var c: Dictionary = _enemy_right_deck.draw_card()
		if not c.is_empty() and _enemy_hand.add_card(c):
			enemy_drawn += 1

	var result := {
		"player_drawn": player_drawn,
		"enemy_drawn": enemy_drawn,
		"player_hand_size": _player_hand.size(),
		"enemy_hand_size": _enemy_hand.size()
	}
	_turn_log.append({"phase": "draw", "result": result})
	return result

func execute_management_phase() -> Dictionary:
	var deployed := 0
	var moved := 0

	deployed += _deploy_units_for_side("player", _player_hand, _player_deployed)
	moved += _move_units_for_side("player", _player_deployed)

	deployed += _deploy_units_for_side("enemy", _enemy_hand, _enemy_deployed)
	moved += _move_units_for_side("enemy", _enemy_deployed)

	var result := {
		"deployed": deployed,
		"moved": moved,
		"player_units_on_map": _count_alive_units(_player_deployed),
		"enemy_units_on_map": _count_alive_units(_enemy_deployed)
	}
	_turn_log.append({"phase": "management", "result": result})
	return result

func execute_combat_phase() -> Dictionary:
	_combat_log.clear()
	var battles := 0
	var player_wins := 0
	var enemy_wins := 0

	var contested: Array = []
	for t_id in _player_deployed:
		if _enemy_deployed.has(t_id):
			contested.append(t_id)

	var resolver := BattleResolver.new()

	for t_id in contested:
		var p_units: Array = _player_deployed[t_id]
		var e_units: Array = _enemy_deployed[t_id]
		var territory: Dictionary = CardDatabase.get_territory(t_id)

		var t_owner: String = GameManager.get_territory_owner(t_id)
		var player_is_attacker: bool = true
		if t_owner == "player":
			player_is_attacker = false
		elif t_owner == "enemy":
			player_is_attacker = true
		else:
			player_is_attacker = p_units.size() >= e_units.size()

		var attackers: Array
		var defenders: Array
		if player_is_attacker:
			attackers = p_units
			defenders = e_units
		else:
			attackers = e_units
			defenders = p_units

		var result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)
		result["territory_id"] = t_id
		_combat_log.append(result)
		battles += 1

		var attacker_won: bool = result.get("player_won", false)
		var winner: String
		if player_is_attacker:
			winner = "player" if attacker_won else "enemy"
		else:
			winner = "enemy" if attacker_won else "player"

		if winner == "player":
			player_wins += 1
			GameManager.set_territory_owner(t_id, "player")
			_enemy_deployed.erase(t_id)
			var alive: Array = []
			for u in p_units:
				if u.is_alive():
					alive.append(u)
			_player_deployed[t_id] = alive
		else:
			enemy_wins += 1
			GameManager.set_territory_owner(t_id, "enemy")
			_player_deployed.erase(t_id)
			var alive: Array = []
			for u in e_units:
				if u.is_alive():
					alive.append(u)
			_enemy_deployed[t_id] = alive

	_capture_uncontested(_player_deployed, "player")
	_capture_uncontested(_enemy_deployed, "enemy")
	_check_ideology()
	_check_religion()

	var result := {
		"battles": battles,
		"player_wins": player_wins,
		"enemy_wins": enemy_wins,
		"combat_log": _combat_log,
		"religion_pending": _pending_religion,
		"ideology_pending": _pending_ideology
	}
	_turn_log.append({"phase": "combat", "result": result})
	return result

func execute_events_phase() -> Dictionary:
	var trigger: RefCounted = _EventTriggerScript.new()
	var events: Array = []
	var checked: Array = []
	for t_id in _player_deployed:
		if checked.has(t_id):
			continue
		checked.append(t_id)
		var triggered: Array = trigger.check_events(t_id, {"owner": "player"})
		for evt in triggered:
			var applied: Dictionary = trigger.apply_event(evt)
			events.append({"territory": t_id, "event": applied})
	var result := {"events": events, "count": events.size()}
	_turn_log.append({"phase": "events", "result": result})
	return result

func execute_building_phase() -> Dictionary:
	var built := 0
	var building_ids: Array = BuildingSystem.get_all_building_ids()
	
	for b_id in building_ids:
		var targets: Array = _find_build_targets("player", b_id)
		for t_id in targets:
			if BuildingSystem.build(b_id, t_id, "player"):
				built += 1
				break
	for b_id in building_ids:
		var targets: Array = _find_build_targets("enemy", b_id)
		for t_id in targets:
			if BuildingSystem.build(b_id, t_id, "enemy"):
				built += 1
				break
	
	var result := {"buildings_built": built}
	_turn_log.append({"phase": "building", "result": result})
	return result

func execute_happiness_phase() -> Dictionary:
	var p_delta: int = HappinessSystem.apply_happiness_turn("player")
	var e_delta: int = HappinessSystem.apply_happiness_turn("enemy")
	
	var p_per_turn: Dictionary = BuildingSystem.apply_per_turn_effects("player")
	var e_per_turn: Dictionary = BuildingSystem.apply_per_turn_effects("enemy")
	
	var p_riot: Dictionary = RiotSystem.check_and_trigger_riot("player")
	var e_riot: Dictionary = RiotSystem.check_and_trigger_riot("enemy")
	
	var result := {
		"player_happiness_delta": p_delta,
		"enemy_happiness_delta": e_delta,
		"player_per_turn": p_per_turn,
		"enemy_per_turn": e_per_turn,
		"player_riot": p_riot,
		"enemy_riot": e_riot
	}
	_turn_log.append({"phase": "happiness", "result": result})
	return result

func execute_quest_phase() -> Dictionary:
	var p_completed: Array = QuestSystem.check_all_quests("player")
	var e_completed: Array = QuestSystem.check_all_quests("enemy")
	var result := {
		"player_quest_steps": p_completed,
		"enemy_quest_steps": e_completed
	}
	_turn_log.append({"phase": "quests", "result": result})
	return result

func execute_end_phase() -> Dictionary:
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

	var growth: int = IdeologySystem.get_population_growth_mod()
	if growth != 0:
		GameManager.change_population(growth)

	var result := {
		"player_territories": GameManager.get_player_territory_count(),
		"enemy_territories": GameManager.get_enemy_territory_count(),
		"population": GameManager.get_population(),
		"player_units": _count_alive_units(_player_deployed),
		"enemy_units": _count_alive_units(_enemy_deployed),
		"player_happiness": HappinessSystem.get_happiness("player"),
		"enemy_happiness": HappinessSystem.get_happiness("enemy"),
		"player_buildings": BuildingSystem.get_total_building_count("player"),
		"enemy_buildings": BuildingSystem.get_total_building_count("enemy"),
		"player_quests_active": QuestSystem.get_active_quests("player").size(),
		"player_quests_done": QuestSystem.get_completed_quests("player").size()
	}
	_turn_log.append({"phase": "end", "result": result})
	_current_turn += 1
	return result

func execute_full_turn() -> Dictionary:
	var r := {}
	r["resources"] = execute_resource_phase()
	r["draw"] = execute_draw_phase()
	r["management"] = execute_management_phase()
	r["combat"] = execute_combat_phase()
	r["events"] = execute_events_phase()
	r["building"] = execute_building_phase()
	r["happiness"] = execute_happiness_phase()
	r["quests"] = execute_quest_phase()
	r["end"] = execute_end_phase()
	return r

func _check_naming() -> void:
	if _current_turn == 2 and not GameManager.is_state_named():
		_pending_naming = true
		naming_required.emit()

func _check_religion() -> void:
	if GameManager.get_player_territory_count() >= 3 and not GameManager.is_religion_chosen():
		_pending_religion = true
		religion_choice_required.emit()

func _check_ideology() -> void:
	if GameManager.get_player_territory_count() >= 5 and not GameManager.is_ideology_chosen():
		_pending_ideology = true
		ideology_choice_required.emit()

func _deploy_units_for_side(side: String, hand: RefCounted, deployed: Dictionary) -> int:
	var count := 0
	var units: Array = hand.get_cards_by_type("unit")
	for card_data in units:
		var cost: Dictionary = card_data.get("cost", {})
		var can_afford := false
		if side == "player":
			can_afford = GameManager.can_afford(cost)
			if can_afford:
				GameManager.spend(cost)
		else:
			can_afford = _enemy_can_afford(cost)
			if can_afford:
				_enemy_spend(cost)

		if can_afford:
			var instance := CardInstance.new(card_data)
			var target := _find_deploy_target(side, deployed)
			if target != "":
				if not deployed.has(target):
					deployed[target] = []
				deployed[target].append(instance)
				instance.territory_id = target
				hand.remove_by_id(card_data.get("id", ""))
				count += 1
	return count

func _move_units_for_side(side: String, deployed: Dictionary) -> int:
	var count := 0
	var territories: Array = deployed.keys().duplicate()
	for t_id in territories:
		var units: Array = deployed[t_id]
		if units.size() <= 1:
			continue
		var adjacent: Array = CardDatabase.get_adjacent_territories(t_id)
		for adj_id in adjacent:
			var owner: String = GameManager.get_territory_owner(adj_id)
			if owner != side:
				var unit: CardInstance = units.pop_front()
				if not deployed.has(adj_id):
					deployed[adj_id] = []
				deployed[adj_id].append(unit)
				unit.territory_id = adj_id
				count += 1
				break
	return count

func _capture_uncontested(deployed: Dictionary, side: String) -> void:
	for t_id in deployed:
		var has_alive := false
		for u in deployed[t_id]:
			if u.is_alive():
				has_alive = true
				break
		if has_alive:
			GameManager.set_territory_owner(t_id, side)

func _find_deploy_target(side: String, deployed: Dictionary) -> String:
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == side:
			var t: Dictionary = CardDatabase.get_territory(t_id)
			if t.get("is_capital", false):
				return t_id
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == side:
			return t_id
	return ""

func _enemy_can_afford(cost: Dictionary) -> bool:
	var res: Dictionary = GameManager.get_enemy_resources()
	for r in cost:
		if res.get(r, 0) < cost[r]:
			return false
	return true

func _enemy_spend(cost: Dictionary) -> void:
	for r in cost:
		GameManager.change_enemy_resource(r, -cost[r])

func _count_alive_units(deployed: Dictionary) -> int:
	var count := 0
	for t_id in deployed:
		for u in deployed[t_id]:
			if u.is_alive():
				count += 1
	return count

func get_player_hand() -> RefCounted:
	return _player_hand

func get_enemy_hand() -> RefCounted:
	return _enemy_hand

func get_player_deployed() -> Dictionary:
	return _player_deployed

func get_enemy_deployed() -> Dictionary:
	return _enemy_deployed

func get_combat_log() -> Array:
	return _combat_log

func get_turn_log() -> Array:
	return _turn_log

func get_current_turn() -> int:
	return _current_turn

func get_state_names() -> Array:
	return _STATE_NAMES.duplicate()

func _find_build_targets(side: String, building_id: String) -> Array:
	var targets: Array = []
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == side:
			if BuildingSystem.can_build(building_id, t_id, side):
				targets.append(t_id)
	return targets
