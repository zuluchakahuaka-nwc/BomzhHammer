extends Node

var _errors: Array = []
var _warnings: Array = []
var _max_log: int = 500

signal error_logged(msg: String)
signal warning_logged(msg: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func log_error(source: String, msg: String) -> void:
	var entry: Dictionary = {
		"time": Time.get_time_string_from_system(),
		"source": source,
		"message": msg,
		"frame": Engine.get_process_frames()
	}
	_errors.append(entry)
	if _errors.size() > _max_log:
		_errors.pop_front()
	error_logged.emit("[%s] ERROR [%s]: %s" % [entry.time, source, msg])
	printerr("[%s] ERROR [%s]: %s" % [entry.time, source, msg])

func log_warning(source: String, msg: String) -> void:
	var entry: Dictionary = {
		"time": Time.get_time_string_from_system(),
		"source": source,
		"message": msg,
		"frame": Engine.get_process_frames()
	}
	_warnings.append(entry)
	if _warnings.size() > _max_log:
		_warnings.pop_front()
	warning_logged.emit("[%s] WARN [%s]: %s" % [entry.time, source, msg])

func get_errors() -> Array:
	return _errors

func get_warnings() -> Array:
	return _warnings

func get_error_count() -> int:
	return _errors.size()

func get_warning_count() -> int:
	return _warnings.size()

func has_errors() -> bool:
	return _errors.size() > 0

func clear() -> void:
	_errors.clear()
	_warnings.clear()

func validate_node(node: Node, required_children: Array) -> bool:
	var valid: bool = true
	for child_path in required_children:
		if node.get_node_or_null(child_path) == null:
			log_error(node.name, "Missing child node: %s" % child_path)
			valid = false
	return valid

func validate_resource(path: String) -> bool:
	if not FileAccess.file_exists(path):
		log_error("ResourceCheck", "Missing resource: %s" % path)
		return false
	return true

func validate_all_resources() -> Dictionary:
	var result: Dictionary = {"ok": 0, "missing": 0, "total": 0}
	var resources: Array = [
		"res://data/cards/units.json",
		"res://data/cards/situations.json",
		"res://data/cards/spells.json",
		"res://data/cards/commanders.json",
		"res://data/maps/territories.json",
		"res://data/maps/connections.json",
		"res://data/cards/achievements.json",
		"res://data/localization/translations.csv",
		"res://scenes/splash_screen.tscn",
		"res://scenes/main_menu.tscn",
		"res://scenes/game_map.tscn",
		"res://scenes/battle_screen.tscn",
		"res://scenes/settings.tscn",
		"res://assets/sprites/map/world_map.jpg",
		"res://assets/sprites/cards/backs/situation_back.jpg",
		"res://assets/sprites/cards/backs/unit_back.jpg",
		"res://scripts/core/save_manager.gd",
	]
	for r in resources:
		result.total += 1
		if FileAccess.file_exists(r):
			result.ok += 1
		else:
			result.missing += 1
			log_error("ResourceCheck", "Missing: %s" % r)
	return result

func get_report() -> String:
	var lines: PackedStringArray = []
	lines.append("=== ErrorParser Report ===")
	lines.append("Errors: %d | Warnings: %d" % [_errors.size(), _warnings.size()])
	for e in _errors:
		lines.append("  ERR [%s] %s: %s" % [e.time, e.source, e.message])
	for w in _warnings:
		lines.append("  WRN [%s] %s: %s" % [w.time, w.source, w.message])
	return "\n".join(lines)
