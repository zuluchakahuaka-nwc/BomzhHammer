extends Node

signal religion_set(religion: String)
signal religion_effect_triggered(effect: String)

var _religion: String = ""
var _modifiers: Dictionary = {}

func _ready() -> void:
	pass

func set_religion(religion: String) -> void:
	_religion = religion
	match religion:
		"mnogobomzhie":
			_modifiers = {
				"unit_attack_bonus": 1,
				"income_per_territory": {},
				"blocks_vodka_cards": false
			}
		"alcoteism":
			_modifiers = {
				"unit_attack_bonus": 0,
				"income_per_territory": {"coins": 2},
				"blocks_vodka_cards": false
			}
		"etanolstvo":
			_modifiers = {
				"unit_attack_bonus": 0,
				"income_per_territory": {"aluminum": 1, "bottles": 1, "cardboard": 1},
				"blocks_vodka_cards": false
			}
		"trezvost":
			_modifiers = {
				"unit_attack_bonus": 0,
				"income_per_territory": {},
				"building_speed_bonus": 2,
				"riot_reduction": 2,
				"blocks_vodka_cards": true
			}
	religion_set.emit(religion)
	Logger.info("ReligionSystem", "Religion set: %s" % religion)

func get_religion() -> String:
	return _religion

func get_income_modifiers() -> Dictionary:
	var base: Dictionary = {"bottles": 1.0, "aluminum": 1.0, "coins": 1.0, "rolltons": 1.0, "cardboard": 1.0}
	match _religion:
		"mnogobomzhie":
			pass
		"alcoteism":
			base["coins"] = 1.2
		"etanolstvo":
			base["aluminum"] = 1.15
			base["bottles"] = 1.15
			base["cardboard"] = 1.15
		"trezvost":
			base["rolltons"] = 0.0
	return base

func get_unit_attack_bonus() -> int:
	return _modifiers.get("unit_attack_bonus", 0)

func get_income_per_territory() -> Dictionary:
	return _modifiers.get("income_per_territory", {})

func get_territory_defense_bonus() -> int:
	if _religion == "mnogobomzhie":
		return 1
	return 0

func blocks_vodka_cards() -> bool:
	return _modifiers.get("blocks_vodka_cards", false)

func get_building_speed_bonus() -> int:
	return _modifiers.get("building_speed_bonus", 0)

func get_riot_reduction() -> int:
	return _modifiers.get("riot_reduction", 0)

func get_religion_name() -> String:
	match _religion:
		"mnogobomzhie": return "Многобомжие"
		"alcoteism": return "Алкотеизм"
		"etanolstvo": return "Этанольство"
		"trezvost": return "Трезвость"
		_: return ""

func get_religion_description() -> String:
	match _religion:
		"mnogobomzhie": return "Атака всех отрядов +1"
		"alcoteism": return "Мелочишка +2 с каждой захваченной точки"
		"etanolstvo": return "Алюминь +1, Бутылки +1, Картон +1 с каждой захваченной точки"
		"trezvost": return "Строительство +2, бунты -2, алкогольные карты заблокированы"
		_: return ""
