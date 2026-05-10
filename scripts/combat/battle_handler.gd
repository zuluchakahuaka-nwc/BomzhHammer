extends RefCounted

var _parent: Node = null
var _scene: PackedScene = null
var _screen: Control = null
var _queue: Array = []
var _results: Array = []
var _callback: Callable = Callable()

func _init(parent: Node) -> void:
	_parent = parent
	if ResourceLoader.exists("res://scenes/battle_screen.tscn"):
		_scene = load("res://scenes/battle_screen.tscn")

func queue(territory_id: String, attackers: Array, defenders: Array, player_is_attacker: bool) -> void:
	_queue.append({
		"territory_id": territory_id,
		"attackers": attackers,
		"defenders": defenders,
		"player_is_attacker": player_is_attacker
	})

func has_pending() -> bool:
	return not _queue.is_empty() or _screen != null

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
	if _screen == null:
		_screen = _scene.instantiate()
		_screen.battle_finished.connect(_on_done)
		_parent.add_child(_screen)
	_screen.setup(data.territory_id, data.attackers, data.defenders, data.player_is_attacker)
	_screen.visible = true

func _on_done(result: Dictionary) -> void:
	_screen.visible = false
	_results.append(result)
	_next()

func clear() -> void:
	_queue.clear()
	_results.clear()
	if _screen != null:
		_screen.queue_free()
		_screen = null
