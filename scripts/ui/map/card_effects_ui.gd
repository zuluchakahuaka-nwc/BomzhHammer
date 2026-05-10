class_name CardEffectsUI
extends RefCounted

var _map: Control = null
var _card_effect: RefCounted = null

func _init(map: Control, card_effect: RefCounted) -> void:
	_map = map
	_card_effect = card_effect

func apply_card_effect(data: Dictionary) -> void:
	var card_type: String = data.get("type", "")
	var card_id: String = data.get("id", "")
	var result: Dictionary
	if card_type == "spell":
		result = _card_effect.resolve_spell(card_id)
	elif card_type == "situation":
		result = _card_effect.resolve_situation(card_id)
	else:
		apply_generic_effect(data)
		return
	if not result.get("success", false):
		apply_generic_effect(data)
		return
	var attack_bonus: int = result.get("attack_bonus", 0)
	var defense_bonus: int = result.get("defense_bonus", 0)
	var attack_penalty: int = result.get("attack_penalty", 0)
	var defense_penalty: int = result.get("defense_penalty", 0)
	if attack_bonus != 0 or defense_bonus != 0:
		for t_id in _map._player_deployed:
			for unit in _map._player_deployed[t_id]:
				if attack_bonus != 0:
					unit.add_buff({"attack": attack_bonus}, 2)
				if defense_bonus != 0:
					unit.add_buff({"defense": defense_bonus}, 2)
		_map._lm("Buff applied: ATK+%d DEF+%d to all units" % [attack_bonus, defense_bonus])
	if attack_penalty != 0 or defense_penalty != 0:
		_map._lm("Debuff applied: ATK-%d DEF-%d" % [attack_penalty, defense_penalty])
	var heal_amount: int = result.get("heal_amount", 0)
	if heal_amount != 0:
		for t_id in _map._player_deployed:
			for unit in _map._player_deployed[t_id]:
				unit.heal(heal_amount)
		_map._lm("Healed all units: +%d HP" % heal_amount)
	var cards_drawn: int = result.get("cards_drawn", 0)
	if cards_drawn != 0:
		for i in range(absi(cards_drawn)):
			if cards_drawn > 0:
				_map._draw_from_deck(_map._left_deck)
			else:
				var all_cards: Array = _map._hand.get_all()
				if not all_cards.is_empty():
					_map._hand.remove_by_id(all_cards[0].get("id", ""))
		_map._refresh_hand_display()
	if result.has("movement_bonus"):
		var mv: int = result["movement_bonus"]
		for t_id in _map._player_deployed:
			for unit in _map._player_deployed[t_id]:
				unit.movement += mv
		_map._lm("Movement bonus: +%d" % mv)
	if result.has("build_speed_bonus"):
		GameManager.change_production(result["build_speed_bonus"])
	if result.has("production_bonus"):
		GameManager.change_production(result["production_bonus"])
	if result.has("freeze_duration"):
		_map._lm("Enemy units frozen for %d turns" % result["freeze_duration"])
	if result.has("coma"):
		_map._lm("Alcohol coma! %d turns" % result.get("duration", 1))
	var msg: String = result.get("message", "")
	if msg != "":
		_map._lm("Effect: %s" % msg)

func apply_generic_effect(data: Dictionary) -> void:
	var effect_type: String = data.get("effect_type", "")
	var amount: int = data.get("amount", 0)
	var resource: String = data.get("resource", "")
	var resources: Dictionary = data.get("resources", {})
	match effect_type:
		"resource_gain":
			if resource != "" and amount != 0:
				GameManager.change_resource(resource, amount)
		"resource_gain_multi":
			for res in resources:
				GameManager.change_resource(res, resources[res])
		"buff_all_attack", "buff_attack":
			for t_id in _map._player_deployed:
				for unit in _map._player_deployed[t_id]:
					unit.add_buff({"attack": amount}, 2)
			_map._lm("Buff applied: +%d attack" % amount)
		"buff_all_defense", "buff_defense":
			for t_id in _map._player_deployed:
				for unit in _map._player_deployed[t_id]:
					unit.add_buff({"defense": amount}, 2)
			_map._lm("Buff applied: +%d defense" % amount)
		"speed_bonus":
			for t_id in _map._player_deployed:
				for unit in _map._player_deployed[t_id]:
					unit.movement += amount
			_map._lm("Speed bonus: +%d" % amount)
		"population_change":
			GameManager.change_population(amount)
		"respect_change":
			GameManager.change_respect(amount)
		"buff_build_speed":
			GameManager.change_production(amount)
			_map._lm("Build speed +%d" % amount)
		"coins_penalty_percent":
			var penalty: int = int(GameManager.get_resources().get("coins", 0) * absi(amount) / 100.0)
			GameManager.change_resource("coins", -penalty)
			_map._lm("Coins penalty: -%d" % penalty)
		"bomond_bonus":
			GameManager.change_resource("bottles", 5)
			GameManager.change_resource("coins", 5)
		"bukhnut_odnogo":
			GameManager.change_respect(-10)
			GameManager.change_production(5)
		_:
			_map._lm("Effect %s applied (generic)" % effect_type)
