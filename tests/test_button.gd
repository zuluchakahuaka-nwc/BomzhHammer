extends SceneTree

var _gm: Variant = null
var _ready_done: bool = false

func _init():
	print("BUTTON TEST: _init")

func _try_init():
	for i in range(root.get_child_count()):
		var ch: Node = root.get_child(i)
		var gm: Node = ch.get_node_or_null("GameManager")
		if gm != null:
			_gm = gm
			print("Found GameManager at root child %d: %s" % [i, ch.name])
			return
		if ch.name == "GameManager":
			_gm = ch
			print("Found GameManager as root child %d" % i)
			return

func _process(_delta: float) -> bool:
	if _ready_done:
		return false
	if _gm == null:
		print("trying init... root_children=%d" % root.get_child_count())
		_try_init()
		return false
	_ready_done = true
	_run()
	return false

func _run():
	print("--- TEST START ---")
	var sc: PackedScene = load("res://scenes/main_menu.tscn")
	if !sc:
		print("FAIL scene null")
		quit()
		return
	var menu: Node = sc.instantiate()
	root.add_child(menu)
	print("Menu instantiated OK")
	
	var vbox = menu.get_node_or_null("VBoxContainer")
	if !vbox:
		print("FAIL no vbox")
		quit()
		return
	for ch in vbox.get_children():
		print("  %s" % ch.name)
	
	var btn: Button = vbox.get_node_or_null("NewGameButton")
	if !btn:
		print("FAIL no button")
		quit()
		return
	
	var conns: Array = btn.pressed.get_connections()
	print("Connections: %d" % conns.size())
	
	if conns.is_empty():
		print("FAIL: 0 connections! _ready() CRASHED")
		quit()
		return
	
	for c in conns:
		print("  %s" % str(c))
	
	print(">>> EMIT pressed <<<")
	btn.pressed.emit()
	
	print("Root children: %d" % root.get_child_count())
	for ch in root.get_children():
		print("  %s" % ch.name)
	print("GM turn=%d owners=%d" % [_gm.get_current_turn(), _gm._territory_owners.size()])
	print("--- END ---")
	quit()
