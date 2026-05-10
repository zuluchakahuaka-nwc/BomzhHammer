extends RefCounted

var _cards: Array = []
var _max_size: int = 7

signal hand_changed(cards: Array)

func _init(max_size: int = 7) -> void:
	_max_size = max_size

func add_card(card_data: Dictionary) -> bool:
	if _cards.size() >= _max_size:
		return false
	_cards.append(card_data)
	return true

func remove_card(index: int) -> Dictionary:
	if index < 0 or index >= _cards.size():
		return {}
	return _cards.pop_at(index)

func remove_by_id(card_id: String) -> Dictionary:
	for i in range(_cards.size()):
		if _cards[i].get("id", "") == card_id:
			return _cards.pop_at(i)
	return {}

func get_card(index: int) -> Dictionary:
	if index < 0 or index >= _cards.size():
		return {}
	return _cards[index]

func get_all() -> Array:
	return _cards

func size() -> int:
	return _cards.size()

func is_empty() -> bool:
	return _cards.is_empty()

func is_full() -> bool:
	return _cards.size() >= _max_size

func has_card(card_id: String) -> bool:
	for c in _cards:
		if c.get("id", "") == card_id:
			return true
	return false

func get_cards_by_type(type: String) -> Array:
	var result: Array = []
	for c in _cards:
		if c.get("type", "") == type:
			result.append(c)
	return result

func get_cards_by_tag(tag: String) -> Array:
	var result: Array = []
	for c in _cards:
		if c.get("tags", []).has(tag):
			result.append(c)
	return result

func clear() -> void:
	_cards.clear()

func serialize() -> Dictionary:
	return {"cards": _cards.duplicate(true), "max_size": _max_size}

func deserialize(data: Dictionary) -> void:
	_cards = data.get("cards", [])
	_max_size = data.get("max_size", 7)
