extends Control

@onready var loading_bar: ProgressBar = $LoadingBar
@onready var background: ColorRect = $Background
@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var logo_label: Label = $LogoLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var skip_label: Label = $SkipLabel

var _videos: Array = []
var _current_video: int = 0
var _loading_done: bool = false
var _videos_done: bool = false
var _started_music: bool = false
var _transitioning: bool = false
var _can_skip: bool = false
var _first_video_shown: bool = false

func _ready() -> void:
	loading_bar.value = 0
	skip_label.visible = false
	_load_fonts()
	_scan_videos()
	if _videos.is_empty():
		_simulate_loading_only()
	else:
		_play_next_video()

func _process(_delta: float) -> void:
	if _first_video_shown and not _can_skip:
		if video_player != null and video_player.get_video_texture() != null:
			_can_skip = true
			skip_label.visible = true

func _input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER:
			_skip_to_menu()
	elif event is InputEventMouseButton and event.pressed:
		_skip_to_menu()

func _skip_to_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	_loading_done = true
	_videos_done = true
	if video_player != null and video_player.is_playing():
		video_player.stop()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _load_fonts() -> void:
	var font := load("res://assets/fonts/BlackOpsOne.ttf")
	if font and font is FontFile:
		logo_label.add_theme_font_override("font", font)
		subtitle_label.add_theme_font_override("font", font)

func _scan_videos() -> void:
	_videos.clear()
	var dir := DirAccess.open("res://video")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var ext := file_name.get_extension().to_lower()
			if ext in ["ogv", "ogg"]:
				_videos.append("res://video/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _play_next_video() -> void:
	if _current_video >= _videos.size():
		_videos_done = true
		_loading_done = true
		_try_transition()
		return
	var path: String = _videos[_current_video]
	var stream := load(path)
	if stream == null:
		_current_video += 1
		_play_next_video()
		return
	video_player.stream = stream
	video_player.play()
	if not video_player.is_connected("finished", _on_video_finished):
		video_player.finished.connect(_on_video_finished)
	if not _started_music:
		_start_music()
		_started_music = true
	if not _first_video_shown:
		_first_video_shown = true
		_can_skip = false

func _on_video_finished() -> void:
	_current_video += 1
	if _current_video < _videos.size():
		video_player.visible = false
		await get_tree().create_timer(2.0).timeout
		video_player.visible = true
	_play_next_video()

func _simulate_loading_only() -> void:
	_start_music()
	_started_music = true
	for i in range(100):
		loading_bar.value = i
		await get_tree().create_timer(0.02).timeout
	loading_bar.value = 100
	_loading_done = true
	_try_transition()

func _try_transition() -> void:
	if _loading_done and _videos_done and not _transitioning:
		_transitioning = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _start_music() -> void:
	var mp := get_node_or_null("/root/MusicPlayer")
	if mp != null and mp.has_method("play"):
		mp.play()
