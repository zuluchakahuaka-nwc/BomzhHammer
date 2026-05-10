extends SceneTree
func _init():
	var f = FileAccess.open("res://data/cards/situations.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(f.get_as_text())
	f.close()
	for c in json.get_data():
		if c.get("id", "") == "dump_west":
			print(JSON.new().stringify(c, "  "))
			break
	# also check territories
	var f2 = FileAccess.open("res://data/maps/territories.json", FileAccess.READ)
	json.parse(f2.get_as_text())
	f2.close()
	for t in json.get_data():
		if t.get("id", "") == "dump_west":
			print("TERRITORY: ", JSON.new().stringify(t, "  "))
			break
	quit()
