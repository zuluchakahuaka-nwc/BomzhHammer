extends Node

signal riot_started(owner: String, reason: String, effects: Dictionary)

func _ready() -> void:
	pass

func check_and_trigger_riot(owner: String) -> Dictionary:
	if HappinessSystem == null:
		return {"rioted": false}
	if not HappinessSystem.should_riot(owner):
		return {"rioted": false}
	
	var reason: String = HappinessSystem.get_riot_reason(owner)
	var effects: Dictionary = _apply_riot_effects(owner, reason)
	
	if owner == "player":
		HappinessSystem.set_happiness(30, "player")
	else:
		HappinessSystem.set_happiness(30, "enemy")
	
	riot_started.emit(owner, reason, effects)
	Logger.info("RiotSystem", "RIOT by %s! Reason: %s. Effects: %s" % [owner, reason, str(effects)])
	
	return {"rioted": true, "owner": owner, "reason": reason, "effects": effects}

func _apply_riot_effects(owner: String, reason: String) -> Dictionary:
	var effects: Dictionary = {"territories_lost": 0, "population_lost": 0, "resources_lost": {}}
	var is_player: bool = (owner == "player")
	
	match reason:
		"starvation":
			effects.population_lost = _lose_population(owner, 20)
			effects.resources_lost = _lose_random_resources(owner, 30)
			effects.territories_lost = _lose_random_territory(owner)
			if is_player:
				GameManager.change_respect(-5)
			effects.respect_change = -5
		"complacency":
			effects.population_lost = _lose_population(owner, 10)
			effects.resources_lost = _lose_random_resources(owner, 20)
			effects.territories_lost = _lose_random_territory(owner)
			if is_player:
				GameManager.change_respect(-3)
			effects.respect_change = -3
	
	return effects

func _lose_population(owner: String, percent: int) -> int:
	var pop: int = GameManager.get_population()
	var lost: int = int(pop * percent / 100.0)
	GameManager.change_population(-lost)
	return lost

func _lose_random_resources(owner: String, percent: int) -> Dictionary:
	var lost: Dictionary = {}
	var resources: Dictionary = GameManager.get_resources() if owner == "player" else GameManager.get_enemy_resources()
	for res in ["bottles", "coins", "cardboard", "aluminum", "rolltons"]:
		var amount: int = resources.get(res, 0)
		if amount <= 0:
			continue
		var loss: int = int(amount * percent / 100.0)
		if loss > 0:
			if owner == "player":
				GameManager.change_resource(res, -loss)
			else:
				GameManager.change_enemy_resource(res, -loss)
			lost[res] = loss
	return lost

func _lose_random_territory(owner: String) -> int:
	var territories: Array = []
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == owner:
			var t: Dictionary = CardDatabase.get_territory(t_id)
			if not t.get("is_capital", false):
				territories.append(t_id)
	if territories.is_empty():
		return 0
	territories.shuffle()
	var lost_id: String = territories[0]
	GameManager.set_territory_owner(lost_id, "neutral")
	if BuildingSystem != null:
		BuildingSystem.destroy_all_on_territory(lost_id, owner)
	return 1

func get_riot_chance(owner: String) -> float:
	if HappinessSystem == null:
		return 0.0
	var h: int = HappinessSystem.get_happiness(owner)
	if h <= 0 or h >= 100:
		return 1.0
	if h <= 10:
		return 0.5
	if h >= 90:
		return 0.5
	if h <= 20:
		return 0.2
	if h >= 80:
		return 0.2
	return 0.0

func clear() -> void:
	pass

func serialize() -> Dictionary:
	return {}

func deserialize(_data: Dictionary) -> void:
	pass
