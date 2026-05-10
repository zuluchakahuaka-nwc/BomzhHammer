class_name BattleResolver
extends RefCounted

var _terrain_defense: Dictionary = {
	"dump": 3,
	"station": 2,
	"supermarket_dumpster": 1,
	"den": 4,
	"pharmacy_dumpster": 1,
	"square_three_stations": 3,
	"dacha": 1,
	"obrygalovka": 0,
	"kutuzka": 5,
	"open_street": 0,
	"cardboard_fortress": 4,
	"garbage_mountain": 3,
	"swamp_waste": 1
}

var _terrain_attack: Dictionary = {
	"dump": -1,
	"station": -1,
	"supermarket_dumpster": 0,
	"den": -2,
	"pharmacy_dumpster": 0,
	"square_three_stations": -1,
	"dacha": 0,
	"obrygalovka": 1,
	"kutuzka": -3,
	"open_street": 0,
	"cardboard_fortress": -2,
	"garbage_mountain": -2,
	"swamp_waste": -2
}

signal battle_result(result: Dictionary)

func _calc_naglost(unit: CardInstance, round_num: int) -> int:
	if unit.naglost <= 0:
		return 0
	if round_num % 2 != 0:
		return 0
	if randi_range(0, 1) == 1:
		return unit.naglost
	return 0

func resolve(attacker: CardInstance, defender: CardInstance, territory_data: Dictionary) -> Dictionary:
	var terrain: String = territory_data.get("terrain", "open_street")
	var result: Dictionary = {
		"attacker_id": attacker.id,
		"defender_id": defender.id,
		"rounds": [],
		"attacker_won": false,
		"attacker_destroyed": false,
		"defender_destroyed": false
	}
	var attacker_atk: int = attacker.get_effective_attack()
	var defender_def: int = defender.get_effective_defense()
	attacker_atk += _terrain_attack.get(terrain, 0)
	defender_def += _terrain_defense.get(terrain, 0)
	defender_def += ReligionSystem.get_territory_defense_bonus()
	var round_num: int = 0
	while attacker.is_alive() and defender.is_alive() and round_num < 10:
		round_num += 1
		var attacker_roll: int = randi_range(1, 6)
		var defender_roll: int = randi_range(1, 6)
		var naglost_bonus: int = _calc_naglost(attacker, round_num)
		var atk_damage: int = maxi(attacker_atk + attacker_roll + naglost_bonus - defender_def, 0)
		var def_damage: int = maxi(defender.get_effective_attack() + defender_roll - attacker.get_effective_defense(), 0) if defender.is_alive() else 0
		defender.take_damage(atk_damage)
		if defender.is_alive():
			attacker.take_damage(def_damage)
		result["rounds"].append({
			"round": round_num,
			"atk_roll": attacker_roll,
			"def_roll": defender_roll,
			"naglost_bonus": naglost_bonus,
			"atk_damage": atk_damage,
			"def_damage": def_damage,
			"attacker_hp": attacker.current_hp,
			"defender_hp": defender.current_hp
		})
	if not defender.is_alive():
		result["defender_destroyed"] = true
		result["attacker_won"] = true
	if not attacker.is_alive():
		result["attacker_destroyed"] = true
	battle_result.emit(result)
	return result

func resolve_multi(attackers: Array, defenders: Array, territory_data: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"attackers": [],
		"defenders": [],
		"player_won": false,
		"rounds": []
	}
	var atk_idx: int = 0
	var def_idx: int = 0
	while atk_idx < attackers.size() and def_idx < defenders.size():
		var a: CardInstance = attackers[atk_idx]
		var d: CardInstance = defenders[def_idx]
		var duel: Dictionary = resolve(a, d, territory_data)
		result["rounds"].append(duel)
		if not a.is_alive():
			atk_idx += 1
		if not d.is_alive():
			def_idx += 1
	if def_idx >= defenders.size() and atk_idx < attackers.size():
		result["player_won"] = true
	var surviving_attackers: Array = []
	for a in attackers:
		if a.is_alive():
			surviving_attackers.append(a.serialize())
	var surviving_defenders: Array = []
	for d in defenders:
		if d.is_alive():
			surviving_defenders.append(d.serialize())
	result["surviving_attackers"] = surviving_attackers
	result["surviving_defenders"] = surviving_defenders
	return result
