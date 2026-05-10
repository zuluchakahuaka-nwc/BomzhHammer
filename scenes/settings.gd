extends Control

@onready var back_btn: Button = $MarginContainer/VBox/ButtonRow/BackButton
@onready var volume_slider: HSlider = $MarginContainer/VBox/AudioSection/VolumeRow/VolumeSlider
@onready var volume_value: Label = $MarginContainer/VBox/AudioSection/VolumeRow/VolumeValue

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	volume_slider.value_changed.connect(_on_volume_changed)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d%%" % int(value)
