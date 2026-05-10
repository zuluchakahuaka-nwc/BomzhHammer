extends SceneTree
func _init():
	print("=== SCENE TEST ===")
	# Test 1: map image loads
	var tex = load("res://assets/sprites/map/world_map.png")
	if tex:
		print("MAP IMAGE: OK size=%dx%d" % [tex.get_width(), tex.get_height()])
	else:
		print("MAP IMAGE: FAILED TO LOAD")
	
	# Test 2: territories loaded
	var file = FileAccess.open("res://data/maps/territories.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.get_data()
	print("TERRITORIES: %d" % data.size())
	for t in data:
		print("  %s at (%s, %s) terrain=%s owner=%s" % [t.id, t.map_x, t.map_y, t.terrain, t.initial_owner])
	
	# Test 3: card backs
	for f in ["situation_back", "unit_back"]:
		if FileAccess.file_exists("res://assets/sprites/cards/backs/%s.png" % f):
			print("BACK %s: OK" % f)
		else:
			print("BACK %s: MISSING" % f)
	
	print("=== DONE ===")
	quit()
