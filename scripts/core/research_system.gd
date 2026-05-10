extends Node

signal research_completed(invention_id: String)
signal research_choice_needed(turn: int)
signal periodic_triggered(invention_id: String)

const INVENTIONS_PATH: String = "res://data/cards/inventions.json"
const RESEARCH_INTERVAL: int = 4

var _all_inventions: Array = []
var _available: Array = []
var _current_research: Dictionary = {}
var _research_turns_left: int = 0
var _completed: Array = []
var _last_choice_turn: int = 0
var _periodic_cooldowns: Dictionary = {}
var _global_defense_bonus: int = 0
var _global_attack_bonus_tag: Dictionary = {}
var _global_movement_bonus: int = 0

func _ready() -> void:
	_load_inventions()

func _load_inventions() -> void:
	if not FileAccess.file_exists(INVENTIONS_PATH):
		return
	var file: FileAccess = FileAccess.open(INVENTIONS_PATH, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	_all_inventions = json.get_data()
	_available = _all_inventions.duplicate()

func check_research_turn(turn: int) -> bool:
	if turn == 2 or (turn > 2 and (turn - 2) % RESEARCH_INTERVAL == 0):
		if _current_research.is_empty():
			_last_choice_turn = turn
			research_choice_needed.emit(turn)
			return true
	return false

func start_research(invention_id: String) -> bool:
	if not _current_research.is_empty():
		return false
	var inv: Dictionary = {}
	for i in _available:
		if i.get("id", "") == invention_id:
			inv = i
			break
	if inv.is_empty():
		return false
	_current_research = inv
	_research_turns_left = inv.get("turns_to_research", 4)
	_available.erase(inv)
	Logger.info("ResearchSystem", "Started research: %s (%d turns)" % [inv.get("name_ru", ""), _research_turns_left])
	return true

func tick() -> void:
	if not _current_research.is_empty():
		_research_turns_left -= 1
		if _research_turns_left <= 0:
			var inv: Dictionary = _current_research
			_completed.append(inv)
			_apply_invention(inv)
			_current_research = {}
			if inv.get("periodic", false):
				_periodic_cooldowns[inv.get("id", "")] = inv.get("cooldown", 10)
			research_completed.emit(inv.get("id", ""))
			Logger.info("ResearchSystem", "Research completed: %s" % inv.get("name_ru", ""))
	_tick_periodics()

func _tick_periodics() -> void:
	for inv in _completed:
		if not inv.get("periodic", false):
			continue
		var inv_id: String = inv.get("id", "")
		if not _periodic_cooldowns.has(inv_id):
			_periodic_cooldowns[inv_id] = inv.get("cooldown", 10)
		_periodic_cooldowns[inv_id] -= 1
		if _periodic_cooldowns[inv_id] <= 0:
			_trigger_periodic(inv)
			_periodic_cooldowns[inv_id] = inv.get("cooldown", 10)

func _trigger_periodic(inv: Dictionary) -> void:
	var effect: String = inv.get("effect", "")
	match effect:
		"disinfection":
			_apply_disinfection()
	Logger.info("ResearchSystem", "Periodic triggered: %s" % inv.get("name_ru", ""))
	periodic_triggered.emit(inv.get("id", ""))

func _apply_disinfection() -> void:
	var active_effects: Array = []
	if GameManager.has_method("get_active_effects"):
		active_effects = GameManager.get_active_effects()
	var removed: int = 0
	for effect_data in active_effects:
		var tags: Array = effect_data.get("tags", [])
		if tags.has("antisanitariya"):
			if GameManager.has_method("remove_active_effect"):
				GameManager.remove_active_effect(effect_data.get("id", ""))
				removed += 1
	Logger.info("ResearchSystem", "Disinfection: removed %d antisanitariya effects" % removed)

func _apply_invention(inv: Dictionary) -> void:
	var effect: String = inv.get("effect", "")
	var amount: int = inv.get("amount", 0)
	match effect:
		"happiness_boost":
			HappinessSystem.change_happiness(amount, "player")
		"defense_bonus_all":
			_global_defense_bonus += amount
			Logger.info("ResearchSystem", "Global defense bonus: +%d (total: %d)" % [amount, _global_defense_bonus])
		"movement_bonus_all":
			_global_movement_bonus += amount
			Logger.info("ResearchSystem", "Global movement bonus: +%d (total: %d)" % [amount, _global_movement_bonus])
		"attack_bonus_tag":
			var tag: String = inv.get("tag", "drinker")
			_global_attack_bonus_tag[tag] = _global_attack_bonus_tag.get(tag, 0) + amount
			Logger.info("ResearchSystem", "Attack bonus for tag '%s': +%d" % [tag, _global_attack_bonus_tag[tag]])
		"production_bonus":
			GameManager.change_production(amount)
		"income_bonus":
			var res: String = inv.get("resource", "bottles")
			GameManager.change_resource(res, amount)
		"respect_and_spy":
			GameManager.change_respect(amount)
		"disinfection":
			_apply_disinfection()

func get_defense_bonus() -> int:
	return _global_defense_bonus

func get_movement_bonus() -> int:
	return _global_movement_bonus

func get_attack_bonus_for_tag(tag: String) -> int:
	return _global_attack_bonus_tag.get(tag, 0)

func get_periodic_cooldown(inv_id: String) -> int:
	return _periodic_cooldowns.get(inv_id, 0)

func get_available() -> Array:
	return _available

func get_current() -> Dictionary:
	return _current_research

func get_completed() -> Array:
	return _completed

func get_turns_left() -> int:
	return _research_turns_left

func is_researching() -> bool:
	return not _current_research.is_empty()

func serialize() -> Dictionary:
	return {
		"current_id": _current_research.get("id", ""),
		"turns_left": _research_turns_left,
		"completed_ids": _completed.map(func(i): return i.get("id", "")),
		"last_choice_turn": _last_choice_turn,
		"periodic_cooldowns": _periodic_cooldowns.duplicate(),
		"global_defense_bonus": _global_defense_bonus,
		"global_movement_bonus": _global_movement_bonus,
		"global_attack_bonus_tag": _global_attack_bonus_tag.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	_current_research = {}
	_completed.clear()
	_periodic_cooldowns.clear()
	var cur_id: String = data.get("current_id", "")
	if cur_id != "":
		for inv in _all_inventions:
			if inv.get("id", "") == cur_id:
				_current_research = inv
				break
	_research_turns_left = data.get("turns_left", 0)
	var done_ids: Array = data.get("completed_ids", [])
	for did in done_ids:
		for inv in _all_inventions:
			if inv.get("id", "") == did:
				_completed.append(inv)
				break
	_last_choice_turn = data.get("last_choice_turn", 0)
	_available = _all_inventions.filter(func(i): return not _completed.has(i) and i != _current_research)
	_periodic_cooldowns = data.get("periodic_cooldowns", {})
	_global_defense_bonus = data.get("global_defense_bonus", 0)
	_global_movement_bonus = data.get("global_movement_bonus", 0)
	_global_attack_bonus_tag = data.get("global_attack_bonus_tag", {})
