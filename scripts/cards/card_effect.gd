extends RefCounted

enum EffectType {
	BUFF_ATTACK,
	BUFF_DEFENSE,
	DEBUFF_ATTACK,
	DEBUFF_DEFENSE,
	HEAL,
	DAMAGE,
	DRAW_CARDS,
	RESOURCE_GAIN,
	RESOURCE_STEAL,
	BLOCK_MOVEMENT,
	EXTRA_ACTION,
	MORALE_CHANGE,
	POPULATION_CHANGE,
	TERRITORY_DEFENSE,
	FREEZE_UNITS,
	ALCO_COMA,
	POHMELE_SELF,
	POHMELE_ENEMY
}

var _permanent_debuffs: Dictionary = {}

func resolve_spell(spell_id: String, context: Dictionary = {}) -> Dictionary:
	var spell: Dictionary = CardDatabase.get_spell(spell_id)
	if spell.is_empty():
		return {"success": false, "reason": "spell_not_found"}
	if ReligionSystem.blocks_vodka_cards() and spell.get("tags", []).has("vodka"):
		return {"success": false, "reason": "blocked_by_religion"}
	var cost: Dictionary = spell.get("cost", {})
	if not GameManager.can_afford(cost):
		return {"success": false, "reason": "cannot_afford"}
	GameManager.spend(cost)
	var result: Dictionary = _apply_spell_effect(spell, context)
	Logger.info("CardEffect", "Spell %s resolved: %s" % [spell_id, str(result)])
	return result

func resolve_situation(situation_id: String, context: Dictionary = {}) -> Dictionary:
	var sit: Dictionary = CardDatabase.get_situation(situation_id)
	if sit.is_empty():
		return {"success": false, "reason": "situation_not_found"}
	if sit.get("one_time_use", false) and context.get("used", false):
		return {"success": false, "reason": "already_used"}
	if sit.get("subtype", "") == "science" and context.get("already_unlocked", false):
		return {"success": false, "reason": "already_unlocked"}
	var cost: Dictionary = sit.get("cost", {})
	if not cost.is_empty() and not GameManager.can_afford(cost):
		return {"success": false, "reason": "cannot_afford"}
	if not cost.is_empty():
		GameManager.spend(cost)
	var result: Dictionary = _apply_situation_effect(sit, context)
	return result

func get_permanent_debuffs() -> Dictionary:
	return _permanent_debuffs

func clear_debuffs_by_tag(tag: String) -> void:
	var to_remove: Array = []
	for debuff_id in _permanent_debuffs:
		var tags: Array = _permanent_debuffs[debuff_id].get("tags", [])
		if tags.has(tag):
			to_remove.append(debuff_id)
	for d_id in to_remove:
		_permanent_debuffs.erase(d_id)

func _apply_spell_effect(spell: Dictionary, context: Dictionary) -> Dictionary:
	var result: Dictionary = {"success": true, "spell_id": spell.get("id", "")}
	var effect: String = spell.get("effect_type", "")
	var amount: int = spell.get("amount", 0)
	var target: String = spell.get("target", "self")
	match effect:
		"buff_attack":
			result["attack_bonus"] = amount
		"buff_defense":
			result["defense_bonus"] = amount
		"debuff_attack":
			result["attack_penalty"] = amount
		"debuff_defense":
			result["defense_penalty"] = amount
		"heal":
			result["heal_amount"] = amount
		"damage":
			result["damage"] = amount
		"draw_cards":
			result["cards_drawn"] = amount
		"resource_gain":
			var res: String = spell.get("resource", "bottles")
			GameManager.change_resource(res, amount)
			result["resource"] = res
			result["amount"] = amount
		"block_movement":
			result["blocked"] = true
		"alco_coma":
			result["coma"] = true
			result["duration"] = amount
		"pohmele_self":
			result["attack_bonus"] = amount
			result["movement_bonus"] = spell.get("movement_bonus", 0)
		"pohmele_enemy":
			result["attack_penalty"] = amount
		"respect_change":
			GameManager.change_respect(amount)
			result["respect_change"] = amount
		"population_change":
			GameManager.change_population(amount)
			result["population_change"] = amount
		_:
			result["success"] = false
			result["reason"] = "unknown_effect"
	return result

func _apply_situation_effect(sit: Dictionary, context: Dictionary) -> Dictionary:
	var result: Dictionary = {"success": true, "situation_id": sit.get("id", "")}
	var effect: String = sit.get("effect_type", "")
	var amount: int = sit.get("amount", 0)
	match effect:
		"resource_gain":
			var res: String = sit.get("resource", "bottles")
			GameManager.change_resource(res, amount)
			result["resource"] = res
			result["amount"] = amount
		"resource_gain_multi":
			var resources: Dictionary = sit.get("resources", {})
			for res in resources:
				GameManager.change_resource(res, resources[res])
			result["resources_gained"] = resources
		"respect_change":
			GameManager.change_respect(amount)
			result["respect_change"] = amount
		"golod":
			var percent: int = absi(amount)
			var pop: int = GameManager.get_population()
			var lost: int = int(pop * percent / 100.0)
			GameManager.change_population(-lost)
			result["population_lost"] = lost
			result["message"] = "event.golod"
		"oblava":
			var pop: int = GameManager.get_population()
			var lost: int = int(pop * 0.2)
			GameManager.change_population(-lost)
			result["population_lost"] = lost
			result["message"] = "event.oblava"
		"skip_turns":
			var turns: int = sit.get("skip_turns", 2)
			result["skip_turns"] = turns
			result["message"] = "event.preduprezhdenie"
		"population_change":
			GameManager.change_population(amount)
			result["population_change"] = amount
		"freeze_all":
			var duration: int = amount
			result["freeze_duration"] = duration
			result["message"] = "event.freeze"
		"area_block":
			result["blocked_territory"] = context.get("territory_id", "")
			result["block_duration"] = amount
		"buff_all_attack":
			result["attack_bonus"] = amount
			result["message"] = "buff.attack"
		"buff_all_defense":
			result["defense_bonus"] = amount
			result["message"] = "buff.defense"
		"buff_movement":
			result["movement_bonus"] = amount
			result["message"] = "buff.movement"
		"buff_build_speed":
			result["build_speed_bonus"] = amount
			result["message"] = "buff.build"
		"production_bonus":
			result["production_bonus"] = amount
			GameManager.change_production(amount)
		"cancel_card":
			var target_tags: Array = sit.get("target_tags", [])
			if target_tags.is_empty():
				var target_card: String = sit.get("target_card", "")
				if target_card != "":
					_permanent_debuffs.erase(target_card)
					result["cancelled"] = target_card
			else:
				for tag in target_tags:
					clear_debuffs_by_tag(tag)
				result["cancelled_tags"] = target_tags
		"population_penalty_permanent":
			var debuff_id: String = sit.get("id", "")
			_permanent_debuffs[debuff_id] = {
				"amount": amount,
				"tags": sit.get("tags", [])
			}
			result["permanent_debuff"] = debuff_id
			result["amount"] = amount
		"lose_random_unit":
			result["units_lost"] = amount
			result["message"] = "event.lose_unit"
		"speed_bonus":
			result["movement_bonus"] = amount
		"steklotara":
			var pop: int = GameManager.get_population()
			var lost: int = int(pop * absi(amount) / 100.0)
			GameManager.change_population(-lost)
			result["population_lost"] = lost
			result["message"] = "event.steklotara"
		"coins_penalty_percent":
			var penalty: int = int(GameManager.get_resources().get("coins", 0) * absi(amount) / 100.0)
			GameManager.change_resource("coins", -penalty)
			result["coins_penalty"] = penalty
		"unlock_building":
			var building_id: String = sit.get("unlocks_building", "")
			result["unlocked_building"] = building_id
			result["message"] = "science.unlock"
		"debuff_enemy_defense":
			result["enemy_defense_penalty"] = amount
		"change_ideology_or_religion":
			result["choice"] = true
			result["message"] = "event.crown_choice"
		"bomond_bonus":
			GameManager.change_resource("bottles", 5)
			GameManager.change_resource("coins", 5)
			result["resources_gained"] = {"bottles": 5, "coins": 5}
		"bukhnut_odnogo":
			GameManager.change_respect(-10)
			GameManager.change_production(5)
			result["respect_change"] = -10
			result["production_change"] = 5
		"enemy_attack":
			result["enemy_count"] = amount
		"event_notification":
			result["message"] = sit.get("message_ru", "")
		_:
			result["success"] = false
			result["reason"] = "unknown_effect: %s" % effect
	if sit.has("side_effect"):
		_apply_side_effect(sit, result)
	return result

func _apply_side_effect(sit: Dictionary, result: Dictionary) -> void:
	var side: String = sit.get("side_effect", "")
	var side_amount: int = sit.get("side_effect_amount", 0)
	match side:
		"lose_random_unit":
			result["side_units_lost"] = side_amount
		"respect_change":
			GameManager.change_respect(side_amount)
			result["side_respect_change"] = side_amount
