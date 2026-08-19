extends Node

signal language_changed(lang: String)

const SAVE_PATH: String = "user://settings.json"

var _current_lang: String = "ru"
var _translations: Dictionary = {}
var _available_languages: PackedStringArray = []
var _tr_resources: Dictionary = {}

func _ready() -> void:
	_load_translations()
	_load_saved_language()

func _load_translations() -> void:
	_load_translation_resources()
	var path: String = "res://data/localization/translations.csv"
	if FileAccess.file_exists(path):
		_load_from_csv(path)

func _load_translation_resources() -> void:
	for lang in ["ru", "en"]:
		var tpath: String = "res://data/localization/translations." + lang + ".translation"
		if ResourceLoader.exists(tpath):
			var tr: Translation = load(tpath)
			if tr:
				_tr_resources[lang] = tr
				if not _available_languages.has(lang):
					_available_languages.append(lang)

func _load_from_csv(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var header: PackedStringArray = file.get_csv_line()
	if header.size() > 0:
		header[0] = header[0].strip_edges().lstrip("\ufeff").lstrip("\ufffe")
	var lang_idx: Dictionary = {}
	for i in range(1, header.size()):
		var lang: String = header[i].strip_edges().lstrip("\ufeff").lstrip("\ufffe")
		lang_idx[lang] = i
		if not _available_languages.has(lang):
			_available_languages.append(lang)
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() < 2 or line[0].strip_edges() == "":
			continue
		var key: String = line[0].strip_edges()
		for lang in lang_idx:
			var idx: int = lang_idx[lang]
			if idx < line.size():
				if not _translations.has(lang):
					_translations[lang] = {}
				_translations[lang][key] = line[idx].strip_edges()
	file.close()

func _load_saved_language() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_current_lang = "ru"
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	if data.has("language"):
		var saved: String = data["language"]
		if _available_languages.has(saved):
			_current_lang = saved

func _save_settings() -> void:
	var data: Dictionary = {"language": _current_lang}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func set_language(lang: String) -> void:
	if lang == _current_lang:
		return
	_current_lang = lang
	_save_settings()
	language_changed.emit(lang)

func get_language() -> String:
	return _current_lang

func get_available_languages() -> PackedStringArray:
	return _available_languages

func has_key(key: String) -> bool:
	if _translations.has(_current_lang) and _translations[_current_lang].has(key):
		return true
	if _tr_resources.has(_current_lang) and _tr_resources[_current_lang].get_message(key) != "":
		return true
	if _translations.has("ru") and _translations["ru"].has(key):
		return true
	if _tr_resources.has("ru") and _tr_resources["ru"].get_message(key) != "":
		return true
	return false

func t(key: String) -> String:
	if _translations.has(_current_lang) and _translations[_current_lang].has(key):
		return _translations[_current_lang][key]
	if _tr_resources.has(_current_lang):
		var val: String = _tr_resources[_current_lang].get_message(key)
		if val != "" and val != key:
			return val
	if _translations.has("ru") and _translations["ru"].has(key):
		return _translations["ru"][key]
	if _tr_resources.has("ru"):
		var val: String = _tr_resources["ru"].get_message(key)
		if val != "" and val != key:
			return val
	return key

func get_card_name(card_data: Dictionary) -> String:
	var field: String = "name_" + _current_lang
	if card_data.has(field):
		return card_data[field]
	if card_data.has("name_ru"):
		return card_data["name_ru"]
	return card_data.get("id", "???")

func get_card_description(card_data: Dictionary) -> String:
	var field: String = "description_" + _current_lang
	if card_data.has(field):
		return card_data[field]
	if card_data.has("description_ru"):
		return card_data["description_ru"]
	return ""

func get_territory_name(data: Dictionary) -> String:
	var field: String = "name_" + _current_lang
	if data.has(field):
		return data[field]
	if data.has("name_ru"):
		return data["name_ru"]
	return data.get("id", "???")
