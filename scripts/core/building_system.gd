extends Node

signal building_built(building_id: String, territory_id: String, owner: String)
signal building_destroyed(building_id: String, territory_id: String)

var _BUILDINGS: Dictionary = {
	"nochlezhka": {
		"id": "nochlezhka",
		"name_ru": "Ночлежка",
		"cost": {"cardboard": 3},
		"production_cost": 3,
		"effect": {"population": 10},
		"description_ru": "+10 население",
		"max_per_territory": 2
	},
	"cardboard_fortress": {
		"id": "cardboard_fortress",
		"name_ru": "Картонная крепость",
		"cost": {"cardboard": 5},
		"production_cost": 5,
		"effect": {"defense": 3},
		"description_ru": "+3 защита территории",
		"max_per_territory": 1
	},
	"alcolesnica": {
		"id": "alcolesnica",
		"name_ru": "Алколесница",
		"cost": {"cardboard": 2, "bottles": 2},
		"production_cost": 4,
		"effect": {"vodka": 2},
		"description_ru": "Боевая техника. Требует 2 водки.",
		"max_per_territory": 2
	},
	"spirtank": {
		"id": "spirtank",
		"name_ru": "Спиртанк",
		"cost": {"cardboard": 2, "bottles": 3},
		"production_cost": 5,
		"effect": {"vodka": 3},
		"description_ru": "Тяжёлая техника. Требует 3 водки.",
		"max_per_territory": 1
	},
	"telezhka": {
		"id": "telezhka",
		"name_ru": "Тележка",
		"cost": {"cardboard": 2, "bottles": 1},
		"production_cost": 2,
		"effect": {"movement_bonus": 0.5},
		"description_ru": "Транспорт/логистика. +0.5 к движению.",
		"max_per_territory": 2
	},
	"paraplan": {
		"id": "paraplan",
		"name_ru": "Картонный параплан",
		"cost": {"cardboard": 3, "bottles": 2},
		"production_cost": 3,
		"effect": {"vision": 2},
		"description_ru": "Воздушная разведка. Видит 2 территории.",
		"max_per_territory": 1
	},
	"samogon_reactor": {
		"id": "samogon_reactor",
		"name_ru": "Самогонный реактор",
		"cost": {"cardboard": 2},
		"production_cost": 6,
		"effect": {"happiness": 15, "bottles_per_turn": 2},
		"description_ru": "+15 счастье, +2 бутылки за ход.",
		"max_per_territory": 1
	},
	"polotorashka_ammo": {
		"id": "polotorashka_ammo",
		"name_ru": "Снаряды-полторашки",
		"cost": {"bottles": 1},
		"production_cost": 1,
		"effect": {"attack_bonus": 1},
		"description_ru": "Боеприпасы. +1 атака отрядам на территории.",
		"max_per_territory": 3
	}
}

var _player_buildings: Dictionary = {}
var _enemy_buildings: Dictionary = {}

func _ready() -> void:
	pass

func get_building_data(building_id: String) -> Dictionary:
	return _BUILDINGS.get(building_id, {})

func get_all_building_ids() -> Array:
	return _BUILDINGS.keys()

func can_build(building_id: String, territory_id: String, owner: String) -> bool:
	var data: Dictionary = _BUILDINGS.get(building_id, {})
	if data.is_empty():
		return false
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	var count: int = 0
	if buildings.has(territory_id):
		for b in buildings[territory_id]:
			if b == building_id:
				count += 1
	if count >= data.get("max_per_territory", 1):
		return false
	var resources: Dictionary = GameManager.get_resources() if owner == "player" else GameManager.get_enemy_resources()
	var cost: Dictionary = data.get("cost", {})
	for res in cost:
		if resources.get(res, 0) < cost[res]:
			return false
	return true

func build(building_id: String, territory_id: String, owner: String) -> bool:
	if not can_build(building_id, territory_id, owner):
		return false
	var data: Dictionary = _BUILDINGS.get(building_id, {})
	var cost: Dictionary = data.get("cost", {})
	if owner == "player":
		GameManager.spend(cost)
	else:
		for r in cost:
			GameManager.change_enemy_resource(r, -cost[r])
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	if not buildings.has(territory_id):
		buildings[territory_id] = []
	buildings[territory_id].append(building_id)
	_apply_immediate_effect(data, owner)
	building_built.emit(building_id, territory_id, owner)
	Logger.info("BuildingSystem", "%s built %s at %s" % [owner, building_id, territory_id])
	return true

func _apply_immediate_effect(data: Dictionary, owner: String) -> void:
	var effect: Dictionary = data.get("effect", {})
	if effect.has("population"):
		GameManager.change_population(effect["population"])
	if effect.has("happiness"):
		if HappinessSystem != null:
			HappinessSystem.change_happiness(effect["happiness"], owner)

func get_territory_defense_bonus(territory_id: String, owner: String) -> int:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	var bonus: int = 0
	if not buildings.has(territory_id):
		return 0
	for b_id in buildings[territory_id]:
		var data: Dictionary = _BUILDINGS.get(b_id, {})
		var effect: Dictionary = data.get("effect", {})
		bonus += effect.get("defense", 0)
	return bonus

func get_territory_attack_bonus(territory_id: String, owner: String) -> int:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	var bonus: int = 0
	if not buildings.has(territory_id):
		return 0
	for b_id in buildings[territory_id]:
		var data: Dictionary = _BUILDINGS.get(b_id, {})
		var effect: Dictionary = data.get("effect", {})
		bonus += effect.get("attack_bonus", 0)
	return bonus

func apply_per_turn_effects(owner: String) -> Dictionary:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	var result: Dictionary = {"bottles": 0}
	for t_id in buildings:
		if GameManager.get_territory_owner(t_id) != owner:
			continue
		for b_id in buildings[t_id]:
			var data: Dictionary = _BUILDINGS.get(b_id, {})
			var effect: Dictionary = data.get("effect", {})
			if effect.has("bottles_per_turn"):
				var amount: int = effect["bottles_per_turn"]
				if owner == "player":
					GameManager.change_resource("bottles", amount)
				else:
					GameManager.change_enemy_resource("bottles", amount)
				result["bottles"] += amount
	return result

func destroy_building(territory_id: String, building_index: int, owner: String) -> bool:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	if not buildings.has(territory_id):
		return false
	if building_index < 0 or building_index >= buildings[territory_id].size():
		return false
	var b_id: String = buildings[territory_id][building_index]
	buildings[territory_id].remove_at(building_index)
	if buildings[territory_id].is_empty():
		buildings.erase(territory_id)
	building_destroyed.emit(b_id, territory_id)
	Logger.info("BuildingSystem", "Building %s destroyed at %s (owner: %s)" % [b_id, territory_id, owner])
	return true

func destroy_all_on_territory(territory_id: String, owner: String) -> int:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	if not buildings.has(territory_id):
		return 0
	var count: int = buildings[territory_id].size()
	buildings.erase(territory_id)
	return count

func get_buildings_on_territory(territory_id: String, owner: String) -> Array:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	return buildings.get(territory_id, []).duplicate()

func get_all_buildings(owner: String) -> Dictionary:
	return (_player_buildings if owner == "player" else _enemy_buildings).duplicate(true)

func get_total_building_count(owner: String) -> int:
	var buildings: Dictionary = _player_buildings if owner == "player" else _enemy_buildings
	var count: int = 0
	for t_id in buildings:
		count += buildings[t_id].size()
	return count

func clear() -> void:
	_player_buildings.clear()
	_enemy_buildings.clear()

func serialize() -> Dictionary:
	return {
		"player_buildings": _player_buildings.duplicate(true),
		"enemy_buildings": _enemy_buildings.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	_player_buildings = data.get("player_buildings", {})
	_enemy_buildings = data.get("enemy_buildings", {})
