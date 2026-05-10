extends RefCounted

enum Priority { DEFEND, EXPAND, ATTACK, GROW }

func evaluate_priority() -> Dictionary:
	var player_count: int = GameManager.get_player_territory_count()
	var enemy_count: int = GameManager.get_enemy_territory_count()
	var resources: Dictionary = GameManager.get_enemy_resources()
	var priorities: Dictionary = {
		Priority.DEFEND: 0.0,
		Priority.EXPAND: 0.0,
		Priority.ATTACK: 0.0,
		Priority.GROW: 0.0
	}
	if player_count > enemy_count:
		priorities[Priority.ATTACK] += 2.0
	else:
		priorities[Priority.DEFEND] += 2.0
	if resources.get("bottles", 0) < 3:
		priorities[Priority.GROW] += 3.0
	if resources.get("rolltons", 0) < 2:
		priorities[Priority.GROW] += 1.0
	var neutral_count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == "neutral":
			neutral_count += 1
	if neutral_count > 0:
		priorities[Priority.EXPAND] += float(neutral_count) * 0.5
	var top_priority: Priority = Priority.DEFEND
	var top_value: float = -1.0
	for p in priorities:
		if priorities[p] > top_value:
			top_value = priorities[p]
			top_priority = p as Priority
	return {"priority": top_priority, "values": priorities}
