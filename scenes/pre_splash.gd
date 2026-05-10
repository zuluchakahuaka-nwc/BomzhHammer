extends Control

@onready var quote1: RichTextLabel = $Quote1
@onready var quote2: RichTextLabel = $Quote2
@onready var source_label: RichTextLabel = $SourceLabel
@onready var skip_label: Label = $SkipLabel

var _elapsed: float = 0.0
var _duration: float = 15.0
var _transitioning: bool = false

func _ready() -> void:
	quote1.bbcode_text = Localization.t("quote.institutions")
	quote2.bbcode_text = Localization.t("quote.un_habitat")
	source_label.bbcode_text = "[color=gray]" + Localization.t("quote.source") + "[/color]"
	skip_label.text = Localization.t("splash.skip")

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
