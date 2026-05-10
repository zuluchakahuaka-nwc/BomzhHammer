extends RefCounted

func match_units(attackers: Array, defenders: Array) -> Dictionary:
	var pairs: Array = []
	var extra_attackers: Array = []
	var extra_defenders: Array = []
	var count: int = mini(attackers.size(), defenders.size())
	for i in count:
		pairs.append({"attacker": attackers[i], "defender": defenders[i]})
	for i in range(count, attackers.size()):
		extra_attackers.append(attackers[i])
	for i in range(count, defenders.size()):
		extra_defenders.append(defenders[i])
	return {
		"pairs": pairs,
		"extra_attackers": extra_attackers,
		"extra_defenders": extra_defenders
	}

func sort_by_strength(units: Array, ascending: bool = false) -> Array:
	var sorted: Array = units.duplicate()
	if ascending:
		sorted.sort_custom(func(a, b): return a.attack + a.defense < b.attack + b.defense)
	else:
		sorted.sort_custom(func(a, b): return a.attack + a.defense > b.attack + b.defense)
	return sorted
