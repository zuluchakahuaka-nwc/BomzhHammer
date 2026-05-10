extends RefCounted

const BattleResolverScript := preload("res://scripts/combat/battle_resolver.gd")

var _parent: Node = null
var _queue: Array = []
var _results: Array = []
var _callback: Callable = Callable()

func _init(parent: Node) -> void:
	_parent = parent

func queue(territory_id: String, attackers: Array, defenders: Array, player_is_attacker: bool) -> void:
	_queue.append({
		"territory_id": territory_id,
		"attackers": attackers,
		"defenders": defenders,
		"player_is_attacker": player_is_attacker
	})

func has_pending() -> bool:
	return not _queue.is_empty()

func start(callback: Callable) -> void:
	_callback = callback
	_results.clear()
	_next()

func _next() -> void:
	if _queue.is_empty():
		var cb: Callable = _callback
		var res: Array = _results.duplicate()
		_results.clear()
		cb.call(res)
		return
	var data: Dictionary = _queue.pop_front()
	var resolver := BattleResolverScript.new()
	var territory: Dictionary = CardDatabase.get_territory(data.territory_id)
	var result: Dictionary = resolver.resolve_multi(data.attackers, data.defenders, territory)
	result["territory_id"] = data.territory_id
	result["player_is_attacker"] = data.player_is_attacker
	_results.append(result)
	_next.call_deferred()

func clear() -> void:
	_queue.clear()
	_results.clear()
