extends SceneTree
func _init():
	var f = FileAccess.open("res://data/cards/units.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(f.get_as_text())
	f.close()
	for c in json.get_data():
		var name = c.get("name_ru","")
		if "мастер" in name.to_lower() or "пьяный" in name.to_lower():
			print("FOUND: ", JSON.new().stringify(c, "  "))
	quit()
