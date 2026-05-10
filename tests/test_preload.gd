extends SceneTree

func _init() -> void:
	print("=== PRELOAD CHECK ===")
	var scripts := [
		"res://scripts/ui/map/map_builder.gd",
		"res://scripts/ui/map/territory_manager.gd",
		"res://scripts/ui/map/card_effects_ui.gd",
		"res://scripts/ui/map/combat_ui.gd",
		"res://scripts/ui/map/choice_popups.gd",
		"res://scripts/ui/map/research_ui.gd",
		"res://scripts/ui/map/help_ui.gd",
		"res://scripts/ui/map/overlay_ui.gd",
		"res://scripts/ui/map/card_detail_ui.gd",
	]
	for path in scripts:
		var res = load(path)
		if res:
			print("OK: %s" % path)
		else:
			print("FAIL: %s" % path)
	print("=== DONE ===")
	quit()
