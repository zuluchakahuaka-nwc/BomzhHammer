extends SceneTree
func _init():
	var img = Image.new()
	var err = img.load("res://assets/sprites/splash/intro_bg.jpg")
	print("err: %d" % err)
	if err == OK:
		print("size: %d x %d" % [img.get_width(), img.get_height()])
		img.save_png("user://debug_intro_check.png")
		print("Saved debug PNG to user://")
	else:
		print("FAILED TO LOAD")
	quit()
