extends Node

signal happiness_changed(value: int, owner: String)
signal riot_triggered(owner: String, reason: String)

var _player_happiness: int = 50
var _enemy_happiness: int = 50

func _ready() -> void:
	pass

func get_happiness(owner: String) -> int:
	return _player_happiness if owner == "player" else _enemy_happiness

func set_happiness(value: int, owner: String) -> void:
	if owner == "player":
		_player_happiness = clampi(value, 0, 100)
	else:
		_enemy_happiness = clampi(value, 0, 100)
	happiness_changed.emit(get_happiness(owner), owner)

func change_happiness(amount: int, owner: String) -> void:
	var old: int = get_happiness(owner)
	var new_val: int = clampi(old + amount, 0, 100)
	if owner == "player":
		_player_happiness = new_val
	else:
		_enemy_happiness = new_val
	if old != new_val:
		happiness_changed.emit(new_val, owner)

func calculate_happiness_change(owner: String) -> int:
	var delta: int = 0
	var ideology: String = GameManager.get_ideology()
	var is_player: bool = (owner == "player")
	
	if is_player and GameManager.is_ideology_chosen():
		if ideology == "alcoholism":
			delta -= 3
		elif ideology == "dermocracy":
			delta += 2
	
	if is_player:
		var population: int = GameManager.get_population()
		if population > 50:
			delta -= 2
		elif population < 10:
			delta -= 3
	
	if is_player and ReligionSystem.get_religion() == "trezvost":
		delta += 2
	
	delta -= 1
	
	return delta

func apply_happiness_turn(owner: String) -> int:
	var delta: int = calculate_happiness_change(owner)
	change_happiness(delta, owner)
	return delta

func should_riot(owner: String) -> bool:
	var h: int = get_happiness(owner)
	if h <= 0:
		return true
	if h >= 100:
		return true
	if ReligionSystem.get_religion() == "trezvost":
		var reduction: int = ReligionSystem.get_riot_reduction()
		if h <= reduction:
			return false
	return false

func get_riot_reason(owner: String) -> String:
	var h: int = get_happiness(owner)
	if h <= 0:
		return "starvation"
	if h >= 100:
		return "complacency"
	return ""

func get_happiness_status(owner: String) -> String:
	var h: int = get_happiness(owner)
	if h >= 95:
		return Localization.t("happiness.obnoxious")
	elif h >= 80:
		return Localization.t("happiness.complacent")
	elif h >= 60:
		return Localization.t("happiness.happy")
	elif h >= 40:
		return Localization.t("happiness.normal")
	elif h >= 20:
		return Localization.t("happiness.unhappy")
	elif h >= 5:
		return Localization.t("happiness.rebellious")
	else:
		return Localization.t("happiness.riot")

func clear() -> void:
	_player_happiness = 50
	_enemy_happiness = 50

func serialize() -> Dictionary:
	return {
		"player_happiness": _player_happiness,
		"enemy_happiness": _enemy_happiness
	}

func deserialize(data: Dictionary) -> void:
	_player_happiness = data.get("player_happiness", 50)
	_enemy_happiness = data.get("enemy_happiness", 50)
