extends Control

var _elapsed: float = 0.0
var _duration: float = 30.0
var _transitioning: bool = false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 1)
	add_child(bg)

	var quote1 := RichTextLabel.new()
	quote1.set_anchors_preset(Control.PRESET_FULL_RECT)
	quote1.anchor_left = 0.08
	quote1.anchor_top = 0.08
	quote1.anchor_right = 0.92
	quote1.anchor_bottom = 0.22
	quote1.bbcode_enabled = true
	quote1.fit_content = true
	quote1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote1.add_theme_font_size_override("normal_font_size", 22)
	quote1.add_theme_color_override("default_color", Color(0.55, 0.55, 0.55, 1))
	quote1.text = Localization.t("quote.institutions")
	add_child(quote1)

	var quote2 := RichTextLabel.new()
	quote2.set_anchors_preset(Control.PRESET_FULL_RECT)
	quote2.anchor_left = 0.04
	quote2.anchor_top = 0.26
	quote2.anchor_right = 0.96
	quote2.anchor_bottom = 0.74
	quote2.bbcode_enabled = true
	quote2.fit_content = true
	quote2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote2.add_theme_font_size_override("normal_font_size", 36)
	quote2.add_theme_color_override("default_color", Color(1, 0.92, 0.15, 1))
	quote2.text = Localization.t("quote.un_habitat")
	add_child(quote2)

	var source := RichTextLabel.new()
	source.set_anchors_preset(Control.PRESET_FULL_RECT)
	source.anchor_left = 0.4
	source.anchor_top = 0.78
	source.anchor_right = 0.94
	source.anchor_bottom = 0.84
	source.bbcode_enabled = true
	source.add_theme_font_size_override("normal_font_size", 20)
	source.add_theme_color_override("default_color", Color(0.4, 0.4, 0.4, 1))
	source.text = "[color=gray]" + Localization.t("quote.source") + "[/color]"
	add_child(source)

	var skip := Label.new()
	skip.set_anchors_preset(Control.PRESET_FULL_RECT)
	skip.anchor_left = 0.6
	skip.anchor_top = 0.92
	skip.anchor_right = 0.95
	skip.anchor_bottom = 0.96
	skip.add_theme_font_size_override("font_size", 24)
	skip.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	skip.text = Localization.t("splash.skip")
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(skip)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration and not _transitioning:
		_go_next()

func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
			_go_next()
	elif event is InputEventMouseButton and event.pressed:
		_go_next()

func _go_next() -> void:
	_transitioning = true
	get_tree().change_scene_to_file("res://scenes/splash_screen.tscn")
