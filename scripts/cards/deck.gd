extends RefCounted

var _cards: Array = []

func _init() -> void:
	_cards.clear()

func build_left_deck() -> void:
	_cards.clear()
	var situations: Array = CardDatabase.get_all_situations()
	var spells: Array = CardDatabase.get_all_spells()
	var excluded := ["sit_alcoholism_card", "sit_dermocracy_card"]
	for sit_data in situations:
		if sit_data.get("id", "") in excluded:
			continue
		if sit_data.get("effect_type", "") == "change_ideology_or_religion":
			continue
		_cards.append(sit_data.duplicate(true))
	for spell_data in spells:
		if ReligionSystem.blocks_vodka_cards() and spell_data.get("tags", []).has("vodka"):
			continue
		_cards.append(spell_data.duplicate(true))
	shuffle()

func build_right_deck() -> void:
	_cards.clear()
	var units: Array = CardDatabase.get_all_units()
	var commanders: Array = CardDatabase.get_all_commanders()
	for unit_data in units:
		_cards.append(unit_data.duplicate(true))
	for cmd_data in commanders:
		_cards.append(cmd_data.duplicate(true))
	shuffle()

func _get_copies_by_rarity(rarity: String) -> int:
	return 1

func shuffle() -> void:
	_cards.shuffle()

func draw_card() -> Dictionary:
	if _cards.is_empty():
		return {}
	return _cards.pop_front()

func draw_cards(count: int) -> Array:
	var drawn: Array = []
	for i in mini(count, _cards.size()):
		drawn.append(_cards.pop_front())
	return drawn

func size() -> int:
	return _cards.size()

func is_empty() -> bool:
	return _cards.is_empty()

func add_to_bottom(card_data: Dictionary) -> void:
	_cards.append(card_data)

func serialize() -> Dictionary:
	return {"cards": _cards.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	_cards = data.get("cards", [])
