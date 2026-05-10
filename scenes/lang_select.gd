extends Control

var _chosen: bool = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 1)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200
	vbox.offset_top = -120
	vbox.offset_right = 200
	vbox.offset_bottom = 120
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var title := Label.new()
	title.text = "ВЫБЕРИТЕ ЯЗЫК / SELECT LANGUAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(sp)

	var btn_ru := Button.new()
	btn_ru.text = "РУССКИЙ"
	btn_ru.custom_minimum_size = Vector2(280, 70)
	btn_ru.add_theme_font_size_override("font_size", 36)
	btn_ru.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	vbox.add_child(btn_ru)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(sp2)

	var btn_en := Button.new()
	btn_en.text = "ENGLISH"
	btn_en.custom_minimum_size = Vector2(280, 70)
	btn_en.add_theme_font_size_override("font_size", 36)
	btn_en.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(btn_en)

	btn_ru.pressed.connect(func() -> void: _select("ru"))
	btn_en.pressed.connect(func() -> void: _select("en"))

func _select(lang: String) -> void:
	if _chosen:
		return
	_chosen = true
	Localization.set_language(lang)
	get_tree().change_scene_to_file("res://scenes/pre_splash.tscn")
