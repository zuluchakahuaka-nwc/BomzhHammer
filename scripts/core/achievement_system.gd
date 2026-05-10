extends Node

signal achievement_unlocked(achievement_id: String, achievement_name: String)

var _unlocked: Array = []

func _ready() -> void:
	_load_progress()

func unlock(achievement_id: String) -> void:
	if _unlocked.has(achievement_id):
		return
	_unlocked.append(achievement_id)
	var ach: Dictionary = _get_achievement_data(achievement_id)
	achievement_unlocked.emit(achievement_id, ach.get("name_ru", achievement_id))
	Logger.info("AchievementSystem", "Achievement unlocked: %s" % achievement_id)
	_save_progress()

func is_unlocked(achievement_id: String) -> bool:
	return _unlocked.has(achievement_id)

func get_all_unlocked() -> Array:
	return _unlocked

func _get_achievement_data(achievement_id: String) -> Dictionary:
	var all: Array = CardDatabase.get_all_achievements()
	for ach in all:
		if ach.get("id", "") == achievement_id:
			return ach
	return {}

func _load_progress() -> void:
	if not FileAccess.file_exists("user://achievements.json"):
		return
	var file: FileAccess = FileAccess.open("user://achievements.json", FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.get_data() is Array:
		_unlocked = json.get_data()
	file.close()

func _save_progress() -> void:
	var file: FileAccess = FileAccess.open("user://achievements.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_unlocked, "\t"))
		file.close()
