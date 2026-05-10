extends Node

var _player: AudioStreamPlayer = null
var _tracks: Array = []
var _current_index: int = -1
var _shuffle: bool = true
var _volume_db: float = 0.0
var _fail_count: int = 0

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = _volume_db
	add_child(_player)
	_player.finished.connect(_on_track_finished)
	_scan_tracks()

func _scan_tracks() -> void:
	_tracks.clear()
	var dir := DirAccess.open("res://music")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var ext := file_name.get_extension().to_lower()
			if ext in ["mp3", "ogg", "wav"]:
				_tracks.append("res://music/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	if _shuffle and _tracks.size() > 1:
		_tracks.shuffle()

func play() -> void:
	if _tracks.is_empty():
		return
	if _current_index < 0 or _current_index >= _tracks.size():
		_current_index = 0
	_fail_count = 0
	_play_current()

func stop() -> void:
	if _player != null:
		_player.stop()

func set_volume_db(db: float) -> void:
	_volume_db = db
	if _player != null:
		_player.volume_db = db

func get_track_count() -> int:
	return _tracks.size()

func get_current_track_name() -> String:
	if _current_index < 0 or _current_index >= _tracks.size():
		return ""
	return _tracks[_current_index].get_file().get_basename()

func _play_current() -> void:
	if _current_index < 0 or _current_index >= _tracks.size():
		return
	var path: String = _tracks[_current_index]
	var stream: AudioStream = _load_audio(path)
	if stream == null:
		_fail_count += 1
		if _fail_count >= _tracks.size():
			return
		_next()
		return
	_fail_count = 0
	_player.stream = stream
	_player.play()

func _load_audio(path: String) -> AudioStream:
	var stream := SafeLoader.audio(path)
	if stream:
		return stream
	return null

func _on_track_finished() -> void:
	_next()

func _next() -> void:
	if _tracks.is_empty():
		return
	_current_index += 1
	if _current_index >= _tracks.size():
		if _shuffle:
			_tracks.shuffle()
		_current_index = 0
	_play_current()

func rescan() -> void:
	_scan_tracks()
