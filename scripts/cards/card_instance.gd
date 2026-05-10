class_name CardInstance
extends RefCounted

var id: String = ""
var card_data: Dictionary = {}
var current_hp: int = 0
var max_hp: int = 0
var attack: int = 0
var defense: int = 0
var cost: Dictionary = {}
var card_type: String = ""
var rarity: String = ""
var tags: Array = []
var territory_id: String = ""
var is_exhausted: bool = false
var rank: String = ""
var naglost: int = 0
var movement: int = 1
var temporary_buffs: Array = []

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	card_data = data
	id = data.get("id", "")
	attack = data.get("attack", 0)
	defense = data.get("defense", 0)
	max_hp = data.get("hp", 1)
	current_hp = max_hp
	card_type = data.get("type", "unit")
	rarity = data.get("rarity", "common")
	tags = data.get("tags", [])
	rank = data.get("rank", "")
	naglost = data.get("naglost", 0)
	movement = data.get("movement", 1)
	var cost_data = data.get("cost", {})
	if cost_data is Dictionary:
		cost = cost_data
	elif cost_data is int:
		cost = {"bottles": cost_data}

func get_name() -> String:
	return Localization.get_card_name(card_data)

func to_dict() -> Dictionary:
	var d: Dictionary = card_data.duplicate()
	d["current_hp"] = current_hp
	d["max_hp"] = max_hp
	d["effective_attack"] = get_effective_attack()
	d["effective_defense"] = get_effective_defense()
	d["is_deployed"] = territory_id != ""
	d["is_exhausted"] = is_exhausted
	return d

func get_description() -> String:
	return Localization.get_card_description(card_data)

func take_damage(amount: int) -> int:
	var actual: int = maxi(amount, 0)
	current_hp -= actual
	return actual

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)

func is_alive() -> bool:
	return current_hp > 0

func get_effective_attack() -> int:
	var val: int = attack
	var vodka_bonus: int = IdeologySystem.get_combat_vodka_bonus()
	if vodka_bonus > 0 and tags.has("drinker"):
		val += vodka_bonus
	val += ReligionSystem.get_unit_attack_bonus()
	for buff in temporary_buffs:
		if buff.has("attack"):
			val += buff["attack"]
	return val

func get_effective_defense() -> int:
	var val: int = defense
	for buff in temporary_buffs:
		if buff.has("defense"):
			val += buff["defense"]
	return val

func add_buff(buff: Dictionary, duration: int = 1) -> void:
	buff["duration"] = duration
	temporary_buffs.append(buff)

func tick_buffs() -> void:
	var to_remove: Array = []
	for i in range(temporary_buffs.size()):
		temporary_buffs[i]["duration"] -= 1
		if temporary_buffs[i]["duration"] <= 0:
			to_remove.append(i)
	for i in range(to_remove.size() - 1, -1, -1):
		temporary_buffs.remove_at(to_remove[i])

func serialize() -> Dictionary:
	return {
		"id": id,
		"current_hp": current_hp,
		"territory_id": territory_id,
		"is_exhausted": is_exhausted,
		"temporary_buffs": temporary_buffs.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	current_hp = data.get("current_hp", max_hp)
	territory_id = data.get("territory_id", "")
	is_exhausted = data.get("is_exhausted", false)
	temporary_buffs = data.get("temporary_buffs", [])
