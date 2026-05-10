class_name BattleOverlay
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_result(source_name: String, target_name: String, player_won: bool, p_alive: int, p_dead: int, e_alive: int, e_dead: int) -> void:
	var overlay := PanelContainer.new()
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -350
	overlay.offset_top = -180
	overlay.offset_right = 350
	overlay.offset_bottom = 180
	overlay.z_index = 300
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(16)
	if player_won:
		style.bg_color = Color(0.02, 0.12, 0.02, 0.95)
		style.border_color = Color(0.3, 1.0, 0.3)
	else:
		style.bg_color = Color(0.12, 0.02, 0.02, 0.95)
		style.border_color = Color(1.0, 0.2, 0.2)
	style.set_border_width_all(4)
	style.shadow_color = Color(1, 1, 1, 0.3)
	style.shadow_size = 15
	overlay.add_theme_stylebox_override("panel", style)
	_map.add_child(overlay)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	overlay.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 5)
	if player_won:
		title.text = "ПОБЕДА!"
		title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		title.text = "ПОРАЖЕНИЕ"
		title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	vbox.add_child(title)

	var where := Label.new()
	where.text = "%s -> %s" % [source_name, target_name]
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.add_theme_font_size_override("font_size", 24)
	where.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	where.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	where.add_theme_constant_override("outline_size", 3)
	vbox.add_child(where)

	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	vbox.add_child(sep)

	var p_label := Label.new()
	p_label.text = "ВАШИ: %d выжило, %d погибло" % [p_alive, p_dead]
	p_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_label.add_theme_font_size_override("font_size", 22)
	p_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	p_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	p_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(p_label)

	var e_label := Label.new()
	e_label.text = "ВРАГИ: %d выжило, %d погибло" % [e_alive, e_dead]
	e_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e_label.add_theme_font_size_override("font_size", 22)
	e_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	e_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	e_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(e_label)

	var tween := _map.create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN).set_delay(2.0)
	tween.tween_callback(overlay.queue_free)
