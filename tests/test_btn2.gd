extends SceneTree

func _init():
	print("INIT")

func _process(_delta: float) -> bool:
	print("TICK root=%d" % root.get_child_count())
	quit()
	return false
