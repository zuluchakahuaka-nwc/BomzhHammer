extends RefCounted

func check_events(territory_id: String, context: Dictionary) -> Array:
	var triggered: Array = []
	var territory: Dictionary = CardDatabase.get_territory(territory_id)
	if territory.is_empty():
		return triggered
	var owner: String = GameManager.get_territory_owner(territory_id)
	if territory.get("is_capital", false):
		triggered.append({"type": "capital_contested", "territory": territory_id})
	if territory.get("terrain", "") == "obrygalovka":
		triggered.append({"type": "terrain_debuff", "effect": "attack_penalty", "amount": -1})
	if IdeologySystem.has_risk_alco_coma():
		var roll: int = randi_range(1, 20)
		if roll <= 2:
			triggered.append({"type": "alco_coma", "duration": 1})
	var events: Array = CardDatabase.get_all_situations()
	for evt in events:
		var req_tag: String = evt.get("requires_territory_tag", "")
		if req_tag != "" and not territory.get("tags", []).has(req_tag):
			continue
		if evt.get("auto_trigger", false):
			var chance: int = evt.get("trigger_chance", 10)
			var roll2: int = randi_range(1, 100)
			if roll2 <= chance:
				triggered.append({"type": "auto_event", "event_id": evt.get("id", "")})
	return triggered

func apply_event(event: Dictionary) -> Dictionary:
	match event.get("type", ""):
		"capital_contested":
			return {"message": "event.capital_contested", "respect_change": -3}
		"terrain_debuff":
			return {"message": "event.terrain_debuff", "attack_penalty": event.get("amount", -1)}
		"alco_coma":
			return {"message": "event.alco_coma", "freeze": true, "duration": event.get("duration", 1)}
		"auto_event":
			return {"message": "event.auto_event", "event_id": event.get("event_id", "")}
		_:
			return {}
