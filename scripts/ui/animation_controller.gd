extends Node

func float_text(parent: Control, text: String, pos: Vector2, color: Color, duration: float = 1.5, font_size: int = 38) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	label.position = pos
	label.z_index = 300
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 80.0, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)

func pulse_control(control: Control, intensity: float = 1.3, duration: float = 0.4) -> void:
	var orig := control.scale
	var tween := control.create_tween()
	tween.tween_property(control, "scale", orig * intensity, duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "scale", orig, duration * 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

func shake_control(control: Control, intensity: float = 8.0, duration: float = 0.5) -> void:
	var orig := control.position
	var tween := control.create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(control, "position", orig + offset, 0.03)
		intensity *= 0.9
	tween.tween_property(control, "position", orig, 0.05)

func flash_overlay(parent: Control, color: Color, region: Rect2, duration: float = 0.6) -> void:
	var rect := ColorRect.new()
	rect.color = Color(color.r, color.g, color.b, 0.7)
	rect.position = region.position
	rect.size = region.size
	rect.z_index = 250
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	var tween := parent.create_tween()
	tween.tween_property(rect, "color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(rect.queue_free)

func color_transition(control: Control, new_color: Color, duration: float = 0.5) -> void:
	if control.has_method("add_theme_stylebox_override"):
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(3)
		style.bg_color = new_color
		var tween := control.create_tween()
		tween.tween_method(func(c: Color) -> void:
			style.bg_color = c
			control.add_theme_stylebox_override("normal", style)
		, control.get_theme_stylebox("normal").bg_color if control.has_theme_stylebox("normal") else Color.GRAY, new_color, duration)

func card_fly(parent: Control, from: Vector2, to: Vector2, card_name: String, color: Color, duration: float = 0.6) -> void:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(80, 120)
	card.size = Vector2(80, 120)
	card.position = from
	card.z_index = 280
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.bg_color = Color(0.08, 0.06, 0.04)
	style.border_color = color
	style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var lbl := Label.new()
	lbl.text = card_name.left(12)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.position = Vector2(4, 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(lbl)
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", to, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(card, "modulate:a", 0.3, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(card.queue_free)

func battle_effect(parent: Control, pos: Vector2, duration: float = 0.8) -> void:
	for i in range(6):
		var spark := ColorRect.new()
		spark.size = Vector2(randf_range(4, 12), randf_range(4, 12))
		spark.position = pos
		spark.color = Color(1.0, randf_range(0.3, 0.8), 0.0, 1.0)
		spark.z_index = 270
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(spark)
		var tween := parent.create_tween()
		var target := pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		tween.set_parallel(true)
		tween.tween_property(spark, "position", target, duration * 0.6).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.tween_property(spark, "size", Vector2(2, 2), duration * 0.5)
		tween.chain().tween_callback(spark.queue_free)

func territory_capture_effect(btn: Button, owner_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	style.bg_color = Color(1, 1, 1, 0.8)
	style.border_color = owner_color
	btn.add_theme_stylebox_override("normal", style)
	var tween := btn.create_tween()
	tween.tween_property(style, "bg_color", owner_color, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		style.bg_color = Color(owner_color.r, owner_color.g, owner_color.b, 0.75)
		btn.add_theme_stylebox_override("normal", style)
	)
	pulse_control(btn, 1.4, 0.5)

func movement_arrow(parent: Control, from: Vector2, to: Vector2, color: Color, duration: float = 1.0) -> void:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(from)
	line.width = 3.0
	line.default_color = color
	line.z_index = 200
	parent.add_child(line)
	var tween := parent.create_tween()
	tween.tween_method(func(p: Vector2) -> void:
		line.set_point_position(1, p)
	, from, to, duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, duration * 0.4).set_ease(Tween.EASE_IN)
	tween.tween_callback(line.queue_free)
