extends Node

var _territories: Dictionary = {}

func _ready() -> void:
	CardDatabase.database_loaded.connect(_build_territories)

func _build_territories() -> void:
	_territories.clear()
	for t_id in CardDatabase._territories:
		var data: Dictionary = CardDatabase.get_territory(t_id)
		var t: RefCounted = load("res://scripts/map/territory.gd").new(data)
		_territories[t_id] = t
	Logger.info("MapController", "Built %d territories" % _territories.size())

func get_territory(id: String) -> RefCounted:
	return _territories.get(id, null)

func get_all_territories() -> Dictionary:
	return _territories

func get_player_territories() -> Array:
	var result: Array = []
	for t_id in _territories:
		if _territories[t_id].owner == "player":
			result.append(_territories[t_id])
	return result

func get_enemy_territories() -> Array:
	var result: Array = []
	for t_id in _territories:
		if _territories[t_id].owner == "enemy":
			result.append(_territories[t_id])
	return result

func get_adjacent_owned(territory_id: String, owner: String) -> Array:
	var adjacent: Array = CardDatabase.get_adjacent_territories(territory_id)
	var result: Array = []
	for adj_id in adjacent:
		if _territories.has(adj_id) and _territories[adj_id].owner == owner:
			result.append(_territories[adj_id])
	return result

func move_units(from_id: String, to_id: String, unit_indices: Array) -> bool:
	if not _territories.has(from_id) or not _territories.has(to_id):
		return false
	var adjacent: Array = CardDatabase.get_adjacent_territories(from_id)
	if not adjacent.has(to_id):
		return false
	var from_t = _territories[from_id]
	var to_t = _territories[to_id]
	var to_move: Array = []
	for idx in unit_indices:
		if idx >= 0 and idx < from_t.units.size():
			to_move.append(from_t.units[idx])
	for u in to_move:
		from_t.units.erase(u)
		to_t.units.append(u)
		u.territory_id = to_id
	return true

func capture_territory(territory_id: String, new_owner: String) -> void:
	if _territories.has(territory_id):
		_territories[territory_id].set_owner(new_owner)

func buyout_territory(territory_id: String) -> bool:
	if not _territories.has(territory_id):
		return false
	if not GameManager.can_buyout_territory(territory_id):
		return false
	if not GameManager.buyout_territory(territory_id):
		return false
	_territories[territory_id].set_owner("player")
	return true
