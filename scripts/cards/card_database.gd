extends Node

var _units: Dictionary = {}
var _situations: Dictionary = {}
var _commanders: Dictionary = {}
var _spells: Dictionary = {}
var _territories: Dictionary = {}
var _connections: Array = []
var _achievements: Array = []

signal database_loaded

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	_load_json_array("res://data/cards/units.json", _units)
	_load_json_array("res://data/cards/situations.json", _situations)
	_load_json_array("res://data/cards/commanders.json", _commanders)
	_load_json_array("res://data/cards/spells.json", _spells)
	_load_json_dict("res://data/maps/territories.json", _territories)
	_load_connections()
	_load_json_raw("res://data/cards/achievements.json", _achievements)
	Logger.info("CardDatabase", "Loaded %d units, %d situations, %d commanders, %d spells, %d territories, %d achievements" % [_units.size(), _situations.size(), _commanders.size(), _spells.size(), _territories.size(), _achievements.size()])
	database_loaded.emit()

func _load_json_array(path: String, target: Dictionary) -> void:
	var data = _read_json(path)
	if data == null:
		return
	if data is Array:
		for item in data:
			if item.has("id"):
				target[item["id"]] = item

func _load_json_dict(path: String, target: Dictionary) -> void:
	var data = _read_json(path)
	if data == null:
		return
	if data is Array:
		for item in data:
			if item.has("id"):
				target[item["id"]] = item
	elif data is Dictionary:
		for key in data:
			target[key] = data[key]

func _load_connections() -> void:
	var data = _read_json("res://data/maps/connections.json")
	if data is Array:
		_connections = data

func _load_json_raw(path: String, target: Array) -> void:
	var data = _read_json(path)
	if data is Array:
		target.append_array(data)

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		Logger.warn("CardDatabase", "File not found: " + path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Logger.error("CardDatabase", "Cannot open: " + path)
		return null
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		Logger.error("CardDatabase", "Parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.get_data()

func get_unit(id: String) -> Dictionary:
	return _units.get(id, {})

func get_situation(id: String) -> Dictionary:
	return _situations.get(id, {})

func get_commander(id: String) -> Dictionary:
	return _commanders.get(id, {})

func get_spell(id: String) -> Dictionary:
	return _spells.get(id, {})

func get_territory(id: String) -> Dictionary:
	return _territories.get(id, {})

func get_all_units() -> Array:
	return _units.values()

func get_all_situations() -> Array:
	return _situations.values()

func get_all_commanders() -> Array:
	return _commanders.values()

func get_all_spells() -> Array:
	return _spells.values()

func get_all_achievements() -> Array:
	return _achievements

func get_card(id: String) -> Dictionary:
	if _units.has(id):
		return _units[id]
	if _situations.has(id):
		return _situations[id]
	if _commanders.has(id):
		return _commanders[id]
	if _spells.has(id):
		return _spells[id]
	return {}

func get_connections_for_territory(territory_id: String) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.get("from", "") == territory_id or conn.get("to", "") == territory_id:
			result.append(conn)
	return result

func get_adjacent_territories(territory_id: String) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.get("from", "") == territory_id:
			if not result.has(conn["to"]):
				result.append(conn["to"])
		elif conn.get("to", "") == territory_id:
			if not result.has(conn["from"]):
				result.append(conn["from"])
	return result
