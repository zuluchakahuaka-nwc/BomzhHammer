extends Control

@onready var new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton
@onready var bot_arena_btn: Button = $VBoxContainer/BotArenaButton
@onready var card_review_btn: Button = $VBoxContainer/CardReviewButton
@onready var lang_btn: Button = $VBoxContainer/LanguageButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var video_player: VideoStreamPlayer = $BomzhTV/TVScreen/VideoPlayer
@onready var tv_label: Label = $BomzhTV/TVLabel

func _ready() -> void:
	ErrorParser.validate_node(self, [
		"VBoxContainer/NewGameButton",
		"VBoxContainer/ContinueButton",
		"VBoxContainer/SettingsButton",
		"VBoxContainer/QuitButton",
	])
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	if bot_arena_btn:
		bot_arena_btn.pressed.connect(_on_bot_arena)
	if card_review_btn:
		card_review_btn.pressed.connect(_on_card_review)
	if lang_btn:
		lang_btn.pressed.connect(_on_language)
	continue_btn.visible = SaveManager.has_save()
	_load_fonts()
	_setup_bomzh_tv()
	_refresh_all_text()
	Localization.language_changed.connect(func(_l): _refresh_all_text())

func _refresh_all_text() -> void:
	title_label.text = Localization.t("game.title")
	subtitle_label.text = Localization.t("game.subtitle")
	new_game_btn.text = Localization.t("btn.new_game")
	continue_btn.text = Localization.t("btn.continue")
	settings_btn.text = Localization.t("btn.settings")
	quit_btn.text = Localization.t("btn.quit")
	if bot_arena_btn:
		bot_arena_btn.text = Localization.t("btn.bot_arena")
	if card_review_btn:
		card_review_btn.text = Localization.t("btn.card_review")
	var lang_names := {"ru": "РУССКИЙ", "en": "ENGLISH"}
	var code := Localization.get_language()
	if lang_btn:
		lang_btn.text = Localization.t("btn.language") + " " + lang_names.get(code, code)

func _on_new_game() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _on_continue() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_bot_arena() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/bot_arena.tscn")

func _on_card_review() -> void:
	get_tree().change_scene_to_file("res://scenes/card_review.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_language() -> void:
	var langs := Localization.get_available_languages()
	var current := Localization.get_language()
	var next := ""
	for i in range(langs.size()):
		if langs[i] == current:
			next = langs[(i + 1) % langs.size()]
			break
	if next == "":
		next = "ru"
	Localization.set_language(next)

func _load_fonts() -> void:
	var logo_node = get_node_or_null("VBoxContainer/Logo")
	if logo_node:
		logo_node.texture = SafeLoader.texture("res://assets/sprites/splash/logos/logo_5.jpg")
	var tv_bg = get_node_or_null("BomzhTV/TVBackground")
	if tv_bg:
		tv_bg.texture = SafeLoader.texture("res://assets/sprites/splash/bomzh_tv_bg.jpg")
	var title_font := SafeLoader.font("res://assets/fonts/BlackOpsOne.ttf")
	if title_font:
		title_label.add_theme_font_override("font", title_font)
		subtitle_label.add_theme_font_override("font", title_font)
	var btn_font := SafeLoader.font("res://assets/fonts/Cinzel-Bold.ttf")
	if btn_font:
		new_game_btn.add_theme_font_override("font", btn_font)
		continue_btn.add_theme_font_override("font", btn_font)
		settings_btn.add_theme_font_override("font", btn_font)
		quit_btn.add_theme_font_override("font", btn_font)

func _setup_bomzh_tv() -> void:
	var tv_font := SafeLoader.font("res://assets/fonts/Philosopher-BoldItalic.ttf")
	if tv_font:
		tv_label.add_theme_font_override("font", tv_font)
