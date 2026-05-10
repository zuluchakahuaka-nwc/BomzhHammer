extends Node

enum Phase { RESOURCES, DRAW, MOVEMENT, COMBAT, EVENTS, END }

signal phase_changed(phase: Phase)
signal turn_changed(turn_number: int)
signal game_over(winner: String, reason: String)

var _current_turn: int = 1
var _current_phase: Phase = Phase.RESOURCES
var _max_turns: int = 99

var _ideology: String = ""
var _religion: String = ""
var _ideology_chosen: bool = false

var _resources: Dictionary = {
	"bottles": 5,
	"aluminum": 3,
	"coins": 3,
	"rolltons": 2,
	"cardboard": 4
}

var _production: int = 0
var _profit: int = 0

var _territory_owners: Dictionary = {}
var _player_hand: Array = []
var _enemy_hand: Array = []
var _respect: int = 0
var _population: int = 10

var _enemy_respect: int = 0
var _state_name: String = ""
var _religion_chosen: bool = false
var _state_named: bool = false
var _player_deployed_ref: Dictionary = {}
var _enemy_deployed_ref: Dictionary = {}
var _intro_shown: bool = false
var _enemy_resources: Dictionary = {
	"bottles": 5,
	"aluminum": 3,
	"coins": 3,
	"rolltons": 2,
	"cardboard": 4
}

func _ready() -> void:
	pass

func start_game() -> void:
	_current_turn = 1
	_current_phase = Phase.RESOURCES
	_respect = 0
	_enemy_respect = 0
	_population = 10
	_state_name = ""
	_religion_chosen = false
	_state_named = false
	_ideology = ""
	_ideology_chosen = false
	_intro_shown = false
	_resources = {"bottles": 5, "aluminum": 3, "coins": 3, "rolltons": 2, "cardboard": 4}
	_enemy_resources = {"bottles": 5, "aluminum": 3, "coins": 3, "rolltons": 2, "cardboard": 4}
	_load_territory_owners()
	Logger.info("GameManager", "Game started: no ideology yet")
	turn_changed.emit(_current_turn)
	phase_changed.emit(_current_phase)

func _load_territory_owners() -> void:
	_territory_owners.clear()
	for t_id in CardDatabase._territories:
		var t: Dictionary = CardDatabase.get_territory(t_id)
		_territory_owners[t_id] = t.get("initial_owner", "neutral")

func get_current_turn() -> int:
	return _current_turn

func get_current_phase() -> Phase:
	return _current_phase

func get_ideology() -> String:
	return _ideology

func get_religion() -> String:
	return _religion

func get_respect() -> int:
	return _respect

func get_enemy_respect() -> int:
	return _enemy_respect

func change_respect(amount: int) -> void:
	_respect = clampi(_respect + amount, -20, 20)
	if _respect <= -20:
		game_over.emit("enemy", "respect_collapse")

func change_enemy_respect(amount: int) -> void:
	_enemy_respect = clampi(_enemy_respect + amount, -20, 20)
	if _enemy_respect <= -20:
		game_over.emit("player", "enemy_respect_collapse")

func get_resources() -> Dictionary:
	return _resources

func get_enemy_resources() -> Dictionary:
	return _enemy_resources

func change_resource(resource: String, amount: int) -> void:
	if _resources.has(resource):
		_resources[resource] = maxi(_resources[resource] + amount, 0)

func change_enemy_resource(resource: String, amount: int) -> void:
	if _enemy_resources.has(resource):
		_enemy_resources[resource] = maxi(_enemy_resources[resource] + amount, 0)

func can_afford(cost: Dictionary) -> bool:
	for res in cost:
		if _resources.get(res, 0) < cost[res]:
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for res in cost:
		_resources[res] = maxi(_resources[res] - cost[res], 0)
	return true

func get_production() -> int:
	return _production

func set_production(amount: int) -> void:
	_production = amount

func change_production(amount: int) -> void:
	_production = maxi(_production + amount, 0)

func get_profit() -> int:
	return _profit

func set_profit(amount: int) -> void:
	_profit = amount

func change_profit(amount: int) -> void:
	_profit = maxi(_profit + amount, 0)

func get_population() -> int:
	return _population

func change_population(amount: int) -> void:
	_population = maxi(_population + amount, 0)

func get_state_name() -> String:
	return _state_name

func set_state_name(name: String) -> void:
	_state_name = name
	_state_named = true

func is_state_named() -> bool:
	return _state_named

func is_religion_chosen() -> bool:
	return _religion_chosen

func set_religion_chosen(chosen: bool) -> void:
	_religion_chosen = chosen

func was_intro_shown() -> bool:
	return _intro_shown

func set_intro_shown() -> void:
	_intro_shown = true

func get_territory_owner(territory_id: String) -> String:
	return _territory_owners.get(territory_id, "neutral")

func set_territory_owner(territory_id: String, owner: String) -> void:
	_territory_owners[territory_id] = owner

func choose_ideology(ideology: String) -> void:
	_ideology = ideology
	_ideology_chosen = true
	IdeologySystem.set_ideology(ideology)
	Logger.info("GameManager", "Ideology chosen: %s at %d territories" % [ideology, get_player_territory_count()])

func is_ideology_chosen() -> bool:
	return _ideology_chosen

func get_buyout_cost(territory_id: String) -> Dictionary:
	var t: Dictionary = CardDatabase.get_territory(territory_id)
	var terrain: String = t.get("terrain", "open_street")
	match terrain:
		"dump":
			return {"coins": 15}
		"station":
			return {"coins": 10}
		"den":
			return {"coins": 5}
		"supermarket_dumpster":
			return {"coins": 4}
		"pharmacy_dumpster":
			return {"coins": 6}
		"dacha":
			return {"coins": 8}
		"square_three_stations":
			return {"coins": 25}
		_:
			return {"coins": 3}

func can_buyout_territory(territory_id: String) -> bool:
	if _territory_owners.get(territory_id, "neutral") != "neutral":
		return false
	var cost: Dictionary = get_buyout_cost(territory_id)
	return can_afford(cost)

func buyout_territory(territory_id: String) -> bool:
	if not can_buyout_territory(territory_id):
		return false
	var cost: Dictionary = get_buyout_cost(territory_id)
	spend(cost)
	_territory_owners[territory_id] = "player"
	Logger.info("GameManager", "Territory bought out: %s for %s" % [territory_id, str(cost)])
	return true

func get_player_territory_count() -> int:
	var count: int = 0
	for t_id in _territory_owners:
		if _territory_owners[t_id] == "player":
			count += 1
	return count

func get_enemy_territory_count() -> int:
	var count: int = 0
	for t_id in _territory_owners:
		if _territory_owners[t_id] == "enemy":
			count += 1
	return count

func register_player_deployed(deployed: Dictionary) -> void:
	_player_deployed_ref = deployed

func register_enemy_deployed(deployed: Dictionary) -> void:
	_enemy_deployed_ref = deployed

func get_player_deployed() -> Dictionary:
	return _player_deployed_ref

func get_enemy_deployed() -> Dictionary:
	return _enemy_deployed_ref

func get_respect_status() -> String:
	var m: int = _respect
	if m >= 15:
		return "respect.legend"
	elif m >= 10:
		return "respect.authority"
	elif m >= 1:
		return "respect.normal"
	elif m == 0:
		return "respect.neutral"
	elif m >= -9:
		return "respect.disrespect"
	elif m >= -14:
		return "respect.panik"
	else:
		return "respect.collapse"

func advance_phase() -> void:
	match _current_phase:
		Phase.RESOURCES:
			_current_phase = Phase.DRAW
		Phase.DRAW:
			_current_phase = Phase.MOVEMENT
		Phase.MOVEMENT:
			_current_phase = Phase.COMBAT
		Phase.COMBAT:
			_current_phase = Phase.EVENTS
		Phase.EVENTS:
			_current_phase = Phase.END
		Phase.END:
			_end_turn()
			return
	Logger.debug("GameManager", "Phase: %d (turn %d)" % [_current_phase, _current_turn])
	phase_changed.emit(_current_phase)

func _end_turn() -> void:
	_current_turn += 1
	if _current_turn > _max_turns:
		_check_time_victory()
		return
	_current_phase = Phase.RESOURCES
	Logger.info("GameManager", "Turn %d started" % _current_turn)
	turn_changed.emit(_current_turn)
	phase_changed.emit(_current_phase)

func _check_time_victory() -> void:
	var p_count: int = get_player_territory_count()
	var e_count: int = get_enemy_territory_count()
	if p_count > e_count:
		game_over.emit("player", "timeout")
	elif e_count > p_count:
		game_over.emit("enemy", "timeout")
	else:
		game_over.emit("draw", "timeout")

func serialize() -> Dictionary:
	return {
		"turn": _current_turn,
		"phase": _current_phase,
		"ideology": _ideology,
		"religion": _religion,
		"resources": _resources.duplicate(true),
		"enemy_resources": _enemy_resources.duplicate(true),
		"production": _production,
		"profit": _profit,
		"territory_owners": _territory_owners.duplicate(true),
		"respect": _respect,
		"enemy_respect": _enemy_respect,
		"population": _population,
		"ideology_chosen": _ideology_chosen,
		"state_name": _state_name,
		"religion_chosen": _religion_chosen,
		"state_named": _state_named
	}

func deserialize(data: Dictionary) -> void:
	_current_turn = data.get("turn", 1)
	_current_phase = data.get("phase", 0) as Phase
	_ideology = data.get("ideology", "")
	_ideology_chosen = data.get("ideology_chosen", false)
	_religion = data.get("religion", "")
	_resources = data.get("resources", {"bottles": 5, "coins": 3, "rolltons": 2, "cardboard": 4})
	_enemy_resources = data.get("enemy_resources", {"bottles": 5, "coins": 3, "rolltons": 2, "cardboard": 4})
	_territory_owners = data.get("territory_owners", {})
	_respect = data.get("respect", 0)
	_production = data.get("production", 0)
	_profit = data.get("profit", 0)
	_population = data.get("population", 10)
	_state_name = data.get("state_name", "")
	_religion_chosen = data.get("religion_chosen", false)
	_state_named = data.get("state_named", false)
