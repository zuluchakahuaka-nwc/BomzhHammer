extends Node

signal resource_changed(resource: String, new_value: int)
signal income_calculated(income: Dictionary)

func _ready() -> void:
	pass

func calculate_income() -> Dictionary:
	var income: Dictionary = {"bottles": 0, "aluminum": 0, "coins": 0, "rolltons": 0, "cardboard": 0}
	var p_count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "player":
			var t: Dictionary = CardDatabase.get_territory(t_id)
			income["bottles"] += t.get("resource_bottles", 0)
			income["aluminum"] += t.get("resource_aluminum", 0)
			income["coins"] += t.get("resource_coins", 0)
			income["rolltons"] += t.get("resource_rolltons", 0)
			income["cardboard"] += t.get("resource_cardboard", 0)
			p_count += 1
	var religion_bonus: Dictionary = ReligionSystem.get_income_per_territory()
	for res in religion_bonus:
		income[res] = income.get(res, 0) + religion_bonus[res] * p_count
	if GameManager.is_ideology_chosen():
		var mods: Dictionary = IdeologySystem.get_income_modifiers()
		for res in income:
			income[res] = int(ceil(income[res] * mods.get(res, 1.0)))
	return income

func calculate_production() -> int:
	var base: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "player":
			var t: Dictionary = CardDatabase.get_territory(t_id)
			base += t.get("production", 0)
			base += t.get("resource_cardboard", 0)
	return base

func calculate_profit() -> int:
	var base: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "player":
			var t: Dictionary = CardDatabase.get_territory(t_id)
			base += t.get("resource_bottles", 0)
			base += t.get("resource_coins", 0)
	if GameManager.is_ideology_chosen():
		var mods: Dictionary = IdeologySystem.get_income_modifiers()
		var coin_mult: float = mods.get("coins", 1.0)
		if coin_mult > 1.0:
			base = int(ceil(base * coin_mult))
	return base

func apply_income() -> void:
	var income: Dictionary = calculate_income()
	for res in income:
		GameManager.change_resource(res, income[res])
		resource_changed.emit(res, GameManager.get_resources().get(res, 0))
	GameManager.set_production(calculate_production())
	GameManager.set_profit(calculate_profit())

func calculate_enemy_income() -> Dictionary:
	var income: Dictionary = {"bottles": 0, "aluminum": 0, "coins": 0, "rolltons": 0, "cardboard": 0}
	var e_count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "enemy":
			var t: Dictionary = CardDatabase.get_territory(t_id)
			income["bottles"] += t.get("resource_bottles", 0)
			income["aluminum"] += t.get("resource_aluminum", 0)
			income["coins"] += t.get("resource_coins", 0)
			income["rolltons"] += t.get("resource_rolltons", 0)
			income["cardboard"] += t.get("resource_cardboard", 0)
			e_count += 1
	var religion_bonus: Dictionary = ReligionSystem.get_income_per_territory()
	for res in religion_bonus:
		income[res] = income.get(res, 0) + religion_bonus[res] * e_count
	if GameManager.is_ideology_chosen():
		var mods: Dictionary = IdeologySystem.get_income_modifiers()
		for res in income:
			income[res] = int(ceil(income[res] * mods.get(res, 1.0)))
	return income

func apply_enemy_income() -> void:
	var income: Dictionary = calculate_enemy_income()
	for res in income:
		GameManager.change_enemy_resource(res, income[res])

func get_resource_display() -> Dictionary:
	var res: Dictionary = GameManager.get_resources()
	var income: Dictionary = calculate_income()
	return {
		"bottles": res.get("bottles", 0),
		"bottles_income": income.get("bottles", 0),
		"aluminum": res.get("aluminum", 0),
		"aluminum_income": income.get("aluminum", 0),
		"coins": res.get("coins", 0),
		"coins_income": income.get("coins", 0),
		"rolltons": res.get("rolltons", 0),
		"rolltons_income": income.get("rolltons", 0),
		"cardboard": res.get("cardboard", 0),
		"cardboard_income": income.get("cardboard", 0),
		"production": GameManager.get_production(),
		"profit": GameManager.get_profit()
	}

func format_resource_line(resource_name: String, current: int, income: int) -> String:
	if income > 0:
		return "%s: %d (+%d за ход)" % [resource_name, current, income]
	elif income < 0:
		return "%s: %d (%d за ход)" % [resource_name, current, income]
	else:
		return "%s: %d" % [resource_name, current]

func get_formatted_display() -> Dictionary:
	var display: Dictionary = get_resource_display()
	return {
		"bottles": format_resource_line("Бутылки", display.bottles, display.bottles_income),
		"aluminum": format_resource_line("Алюминь", display.aluminum, display.aluminum_income),
		"coins": format_resource_line("Мелочишка", display.coins, display.coins_income),
		"rolltons": format_resource_line("Роллтоны", display.rolltons, display.rolltons_income),
		"cardboard": format_resource_line("Картон", display.cardboard, display.cardboard_income)
	}
