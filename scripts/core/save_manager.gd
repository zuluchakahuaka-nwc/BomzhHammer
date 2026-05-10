extends Node

const SAVE_PATH: String = "user://bomzhhammer_save.json"

func save_game() -> bool:
	var data := GameManager.serialize()
	data["timestamp"] = Time.get_datetime_string_from_system()
	data["version"] = 1
	var json := JSON.new()
	var json_str: String = json.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		Logger.error("SaveManager", "Failed to open save file: %s" % SAVE_PATH)
		return false
	file.store_string(json_str)
	file.close()
	Logger.info("SaveManager", "Game saved to %s" % SAVE_PATH)
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		Logger.info("SaveManager", "No save file found")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		Logger.error("SaveManager", "Failed to open save file for reading")
		return false
	var json_str: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var err: Error = json.parse(json_str)
	if err != OK:
		Logger.error("SaveManager", "Failed to parse save JSON: %s" % json.get_error_message())
		return false
	var data: Dictionary = json.data
	GameManager.start_game()
	GameManager.deserialize(data)
	Logger.info("SaveManager", "Game loaded from %s (turn %d)" % [SAVE_PATH, GameManager.get_current_turn()])
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		Logger.info("SaveManager", "Save deleted")

func get_save_info() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json_str: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return {}
	var data: Dictionary = json.data
	return {
		"turn": data.get("turn", 1),
		"timestamp": data.get("timestamp", ""),
		"state_name": data.get("state_name", ""),
		"ideology": data.get("ideology", "")
	}
