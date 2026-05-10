extends RefCounted

var id: String = ""
var territory_data: Dictionary = {}
var owner: String = "neutral"
var units: Array = []
var defense_bonus: int = 0

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	territory_data = data
	id = data.get("id", "")
	owner = data.get("initial_owner", "neutral")
	defense_bonus = 0

func get_name() -> String:
	return Localization.get_card_name(territory_data)

func get_terrain() -> String:
	return territory_data.get("terrain", "open_street")

func get_resource_income() -> Dictionary:
	return {
		"bottles": territory_data.get("resource_bottles", 0),
		"aluminum": territory_data.get("resource_aluminum", 0),
		"coins": territory_data.get("resource_coins", 0),
		"rolltons": territory_data.get("resource_rolltons", 0),
		"cardboard": territory_data.get("resource_cardboard", 0)
	}

func get_movement_cost() -> float:
	return territory_data.get("movement_cost", 1.0)

func get_map_position() -> Vector2:
	return Vector2(territory_data.get("map_x", 0), territory_data.get("map_y", 0))

func add_unit(unit: CardInstance) -> void:
	units.append(unit)

func remove_unit(unit_id: String) -> void:
	for i in range(units.size()):
		if units[i].id == unit_id:
			units.remove_at(i)
			return

func get_units() -> Array:
	return units

func get_unit_count() -> int:
	return units.size()

func get_total_attack() -> int:
	var total: int = 0
	for u in units:
		total += u.get_effective_attack()
	return total

func get_total_defense() -> int:
	var total: int = 0
	for u in units:
		total += u.get_effective_defense()
	total += defense_bonus
	return total

func set_owner(new_owner: String) -> void:
	owner = new_owner
	GameManager.set_territory_owner(id, new_owner)

func get_owner() -> String:
	return owner
