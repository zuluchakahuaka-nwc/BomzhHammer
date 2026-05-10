extends RefCounted

var _frames: Array = []
var _current_index: int = 0
var _playing: bool = false
var _fps: float = 8.0
var _elapsed: float = 0.0
var _finished: bool = false

signal animation_finished()

func _init() -> void:
	_load_frames()

func _load_frames() -> void:
	var names := [
		"battle_01_standoff", "battle_02_charge_start", "battle_03_first_clash",
		"battle_04_melee", "battle_05_archers", "battle_06_cavalry",
		"battle_07_explosion", "battle_08_shield_wall", "battle_09_flank",
		"battle_10_berserker", "battle_11_magic", "battle_12_reinforcements",
		"battle_13_siege", "battle_14_duel", "battle_15_retreat",
		"battle_16_last_stand", "battle_17_breakthrough", "battle_18_rout",
		"battle_19_aftermath", "battle_20_victory"
	]
	for n in names:
		var path: String = "res://assets/sprites/battle_anim/%s.jpg" % n
		if ResourceLoader.exists(path):
			var tex: Resource = load(path)
			if tex is Texture2D:
				_frames.append(tex)

func get_frame_count() -> int:
	return _frames.size()

func get_current_frame() -> Texture2D:
	if _frames.is_empty():
		return null
	return _frames[_current_index]

func is_playing() -> bool:
	return _playing

func is_finished() -> bool:
	return _finished

func play() -> void:
	_current_index = 0
	_playing = true
	_finished = false
	_elapsed = 0.0

func tick(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	var time_per_frame: float = 1.0 / _fps
	var frames_to_advance: int = int(_elapsed / time_per_frame)
	if frames_to_advance > 0:
		_elapsed -= frames_to_advance * time_per_frame
		_current_index = mini(_current_index + frames_to_advance, _frames.size() - 1)
		if _current_index >= _frames.size() - 1:
			_playing = false
			_finished = true
			animation_finished.emit()

func reset() -> void:
	_current_index = 0
	_playing = false
	_finished = false
	_elapsed = 0.0
