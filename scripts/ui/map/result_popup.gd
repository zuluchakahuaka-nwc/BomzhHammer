class_name ResultPopup
extends RefCounted

var _map: Control = null
var _victory_tex: Texture2D = null
var _defeat_tex: Texture2D = null
var _active: Control = null

func _init(map: Control) -> void:
	_map = map
	_victory_tex = SafeLoader.texture("res://assets/sprites/ui/victory_capture.jpg")
	_defeat_tex = SafeLoader.texture("res://assets/sprites/ui/defeat_capture.jpg")

func show_victory(territory_name: String) -> void:
	_show(territory_name, true)

func show_defeat(territory_name: String) -> void:
	_show(territory_name, false)

func is_showing() -> bool:
	return _active != null and is_instance_valid(_active)

func dismiss() -> void:
	if _active != null and is_instance_valid(_active):
		_active.queue_free()
	_active = null

func _show(territory_name: String, is_victory: bool) -> void:
	if _active != null and is_instance_valid(_active):
		_active.queue_free()
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 400
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	_map.add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var tex: Texture2D = _victory_tex if is_victory else _defeat_tex
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		img.custom_minimum_size = Vector2(400, 600)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(img)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 6)
	if is_victory:
		title.text = Localization.t("battle.result.win")
		title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		title.text = Localization.t("battle.result.loss")
		title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	vbox.add_child(title)

	var where := Label.new()
	where.text = territory_name
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.add_theme_font_size_override("font_size", 30)
	where.add_theme_color_override("font_color", Color(1, 1, 1))
	where.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	where.add_theme_constant_override("outline_size", 4)
	vbox.add_child(where)

	var hint := Label.new()
	hint.text = Localization.t("popup.click_to_close") if Localization.t("popup.click_to_close") != "popup.click_to_close" else "нажмите чтобы продолжить"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override("outline_size", 2)
	vbox.add_child(hint)

	var cb := func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		if _active == overlay:
			_active = null
	bg.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed):
			cb.call()
	)
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventKey and ev.pressed):
			cb.call()
	)

	overlay.modulate = Color(1, 1, 1, 0)
	var tw := _map.create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.5)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.5)
	tw.tween_callback(cb)
	_active = overlay
