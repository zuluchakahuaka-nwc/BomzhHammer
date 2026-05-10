extends Node

signal ideology_set(ideology: String)
signal ideology_effect_triggered(effect: String, value: int)

var _ideology: String = ""
var _modifiers: Dictionary = {}

func _ready() -> void:
	pass

func set_ideology(ideology: String) -> void:
	_ideology = ideology
	match ideology:
		"alcoholism":
			_modifiers = {
				"income_multiplier": {"rolltons": 1.0, "bottles": 1.0, "aluminum": 1.0, "coins": 1.0, "cardboard": 1.0},
				"combat_bonus_vodka": 2,
				"population_growth": -1,
				"building_cost_mult": 1.0,
				"risk_alco_coma": true,
				"extra_unit_draw": 1
			}
		"dermocracy":
			_modifiers = {
				"income_multiplier": {"rolltons": 1.0, "bottles": 1.0, "aluminum": 1.0, "coins": 1.25, "cardboard": 1.0},
				"combat_bonus_vodka": 0,
				"population_growth": 1,
				"building_cost_mult": 0.8,
				"risk_alco_coma": false,
				"extra_unit_draw": 0
			}
	ideology_set.emit(ideology)
	Logger.info("IdeologySystem", "Ideology set: %s" % ideology)

func get_ideology() -> String:
	return _ideology

func get_extra_unit_draw() -> int:
	return _modifiers.get("extra_unit_draw", 0)

func get_income_modifiers() -> Dictionary:
	return _modifiers.get("income_multiplier", {"bottles": 1.0, "aluminum": 1.0, "coins": 1.0, "rolltons": 1.0, "cardboard": 1.0})

func get_combat_vodka_bonus() -> int:
	return _modifiers.get("combat_bonus_vodka", 0)

func get_population_growth_mod() -> int:
	return _modifiers.get("population_growth", 0)

func get_building_cost_mult() -> float:
	return _modifiers.get("building_cost_mult", 1.0)

func has_risk_alco_coma() -> bool:
	return _modifiers.get("risk_alco_coma", false)

func get_ideology_name() -> String:
	match _ideology:
		"alcoholism": return "ideology.alcoholism"
		"dermocracy": return "ideology.dermocracy"
		_: return "ideology.none"

func get_ideology_description() -> String:
	match _ideology:
		"alcoholism": return "ideology.alcoholism.desc"
		"dermocracy": return "ideology.dermocracy.desc"
		_: return ""
