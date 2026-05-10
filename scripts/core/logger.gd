extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

var _log_file: FileAccess = null
var _min_level: int = Level.INFO

func _ready() -> void:
	var path: String = "user://bomzhhammer.log"
	_log_file = FileAccess.open(path, FileAccess.WRITE)
	if _log_file:
		_log_file.store_string("=== BOMZHAMMER Log Started: " + Time.get_datetime_string_from_system() + " ===\n")
	_log(Level.INFO, "Logger", "Logger initialized")

func _log(level: int, source: String, message: String) -> void:
	if level < _min_level:
		return
	var level_name: String = ["DEBUG", "INFO", "WARN", "ERROR"][level]
	var timestamp: String = Time.get_time_string_from_system()
	var line: String = "[%s] [%s] [%s] %s" % [timestamp, level_name, source, message]
	print(line)
	if _log_file:
		_log_file.store_string(line + "\n")
		_log_file.flush()

func debug(source: String, message: String) -> void:
	_log(Level.DEBUG, source, message)

func info(source: String, message: String) -> void:
	_log(Level.INFO, source, message)

func warn(source: String, message: String) -> void:
	_log(Level.WARN, source, message)

func error(source: String, message: String) -> void:
	_log(Level.ERROR, source, message)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _log_file:
		_log_file.store_string("=== BOMZHAMMER Log Ended ===\n")
		_log_file.close()
