extends SceneTree

func _init() -> void:
	_test_scene_load("res://scenes/pre_splash.tscn", ["Bg", "Quote1"])
	_test_scene_load("res://scenes/splash_screen.tscn", ["VideoPlayer", "LoadingBar"])
	_test_scene_load("res://scenes/main_menu.tscn", [])
	_test_scene_load("res://scenes/game_map.tscn", ["MapArea", "TopBar", "HandArea"])
	print("\n  ALL SCREEN LENS TESTS PASSED\n")
	quit()

func _test_scene_load(path: String, required_names: Array) -> void:
	var res = load(path)
	if res == null:
		print("  FAIL: %s — load() returned null" % path)
		quit()
		return
	var instance = res.instantiate()
	if instance == null:
		print("  FAIL: %s — instantiate() returned null" % path)
		quit()
		return
	if instance is Control:
		instance.size = Vector2(1920, 1080)
	instance._ready()
	var child_count = instance.get_child_count()
	if child_count == 0:
		print("  FAIL: %s — 0 children after _ready(), gray screen likely" % path)
		quit()
		return
	var has_visible := false
	_for_each(instance, func(n: Node):
		if n is CanvasItem and n.visible:
			has_visible = true
	)
	if not has_visible:
		print("  FAIL: %s — no visible CanvasItem found, gray screen likely" % path)
		quit()
		return
	for cname in required_names:
		var found = _find_recursive(instance, cname)
		if found == null:
			print("  FAIL: %s — required node '%s' not found" % [path, cname])
			quit()
			return
	var label_count := 0
	_for_each(instance, func(n: Node):
		if n is Label or n is RichTextLabel:
			if n.text != "":
				label_count += 1
	)
	if required_names.size() > 0 and label_count == 0:
		print("  FAIL: %s — all labels empty, gray screen likely" % path)
		quit()
		return
	print("  OK: %s (%d children, %d labels with text)" % [path.get_file(), child_count, label_count])

func _for_each(node: Node, cb: Callable) -> void:
	cb.call(node)
	for c in node.get_children():
		_for_each(c, cb)

func _find_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for c in node.get_children():
		var r = _find_recursive(c, name)
		if r != null:
			return r
	return null
