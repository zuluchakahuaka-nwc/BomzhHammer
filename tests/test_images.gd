extends SceneTree

func _init() -> void:
	print("=== IMAGE LOAD TEST ===")
	var paths: Array = [
		"res://assets/sprites/cards/situations/sit_oblava.jpg",
		"res://assets/sprites/cards/situations/sit_golod.jpg",
		"res://assets/sprites/cards/units/unit_novice.jpg",
		"res://assets/sprites/cards/units/unit_bomzh.jpg",
		"res://assets/sprites/cards/spells/spell_pohmele.jpg"
	]
	for p in paths:
		var exists_rr: bool = ResourceLoader.exists(p)
		var fexists: bool = FileAccess.file_exists(p)
		print("  %s: ResourceLoader=%s FileAccess=%s" % [p.split("/")[-1], str(exists_rr), str(fexists)])
		if exists_rr:
			var res = load(p)
			print("    loaded: %s type=%s" % [str(res != null), str(typeof(res))])
		elif fexists:
			print("    File exists but ResourceLoader can't find - importing issue")
			var img := Image.new()
			var err: int = img.load(p)
			if err == OK:
				print("    Direct Image.load OK: %dx%d" % [img.get_width(), img.get_height()])
				var tex := ImageTexture.create_from_image(img)
				print("    Texture created: %s" % str(tex != null))
			else:
				print("    Direct Image.load FAILED: %d" % err)
	print("=== DONE ===")
	quit()
