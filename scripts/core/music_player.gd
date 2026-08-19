extends Node

var _player: AudioStreamPlayer = null
var _tracks: Array = []
var _current_index: int = -1
var _shuffle: bool = true
var _volume_db: float = 0.0
var _hardcoded_tracks: PackedStringArray = [
	"res://music/1eb6223b-9249-49ce-8ffc-1caef5ec2419.ogg",
	"res://music/2566adc1-25f0-4be4-a3d1-ac9254737b79.ogg",
	"res://music/6b715af2-0819-4892-8fcd-eb4dd4618426.ogg",
	"res://music/78fe6d61-c665-402a-98f4-75c1ba1e61f4.ogg",
	"res://music/82ad2f78-71ef-4109-8a5c-4bb45cd4a5aa.ogg",
	"res://music/afb92adb-3d3e-4667-9164-28e092fba1e0.ogg",
	"res://music/d3522a21-212d-4787-a692-6ab7ae9c9a6c.ogg",
	"res://music/dbfac82b-ac9e-4d68-abba-20eb05e17a13.ogg",
]
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
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var ext := file_name.get_extension().to_lower()
				if ext in ["mp3", "ogg", "wav"]:
					_tracks.append("res://music/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	if _tracks.is_empty():
		_tracks = _hardcoded_tracks.duplicate()
	if _shuffle and _tracks.size() > 1:
		_tracks.shuffle()

func play() -> void:
	if _tracks.is_empty():
		return
	if _current_index < 0 or _current_index >= _tracks.size():
		_current_index = 0
	_fail_count = 0
	if is_inside_tree():
		_play_current()
	else:
		call_deferred("_play_current")

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
	if is_inside_tree():
		_player.play()

func _load_audio(path: String) -> AudioStream:
	var stream := load(path)
	if stream is AudioStream:
		return stream
	stream = SafeLoader.audio(path)
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
