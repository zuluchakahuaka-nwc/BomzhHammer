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
	print("[SplashScreen] videos found: %d" % _videos.size())
	if _videos.is_empty():
		print("[SplashScreen] no videos, simulating loading only")
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
	var font := SafeLoader.font("res://assets/fonts/Philosopher-Bold.ttf")
	if font:
		logo_label.add_theme_font_override("font", font)
		subtitle_label.add_theme_font_override("font", font)

func _scan_videos() -> void:
	_videos.clear()
	var all_ogv: Array = []
	var dirs_to_scan: Array = ["res://video/new", "res://video"]
	for base_dir in dirs_to_scan:
		var d := DirAccess.open(base_dir)
		if d == null:
			continue
		d.list_dir_begin()
		var fn := d.get_next()
		while fn != "":
			if not d.current_is_dir():
				var ext := fn.get_extension().to_lower()
				if ext in ["ogv", "ogg"]:
					var full_path: String = base_dir + "/" + fn
					var mod_time: int = FileAccess.get_modified_time(full_path)
					all_ogv.append({"path": full_path, "time": mod_time})
			fn = d.get_next()
		d.list_dir_end()
	var seen: Dictionary = {}
	for entry in all_ogv:
		var base: String = entry["path"].get_file()
		if seen.has(base):
			continue
		seen[base] = true
		_videos.append(entry)
	_videos.sort_custom(func(a, b): return a["time"] > b["time"])
	var paths: Array = []
	for entry in _videos:
		paths.append(entry["path"])
	_videos = paths

func _play_next_video() -> void:
	if _current_video >= _videos.size():
		_videos_done = true
		_loading_done = true
		_try_transition()
		return
	var path: String = _videos[_current_video]
	print("[SplashScreen] loading video: %s" % path)
	var stream := load(path)
	if stream == null:
		print("[SplashScreen] FAILED to load video: %s" % path)
		_current_video += 1
		_play_next_video()
		return
	print("[SplashScreen] video loaded OK, playing")
	background.visible = false
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
		print("[SplashScreen] starting music, tracks: %d" % mp.get_track_count())
		mp.play()
	else:
		print("[SplashScreen] MusicPlayer not found or no play method")
