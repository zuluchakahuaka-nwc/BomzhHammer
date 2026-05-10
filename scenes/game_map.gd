extends Control

@onready var map_area: Control = $MapArea
@onready var turn_label: Label = $TopBar/HBox/TurnLabel
@onready var phase_label: Label = $TopBar/HBox/PhaseLabel
@onready var ideology_label: Label = $TopBar/HBox/IdeologyLabel
@onready var religion_label: Label = $TopBar/HBox/ReligionLabel
@onready var bottles_label: Label = $ResourceBar/BottlesLabel
@onready var aluminum_label: Label = $ResourceBar/AluminumLabel
@onready var coins_label: Label = $ResourceBar/CoinsLabel
@onready var vodka_label: Label = $ResourceBar/VodkaLabel
@onready var cardboard_label: Label = $ResourceBar/CardboardLabel
@onready var respect_label: Label = $ResourceBar/RespectLabel
@onready var pop_label: Label = $ResourceBar/PopLabel
@onready var end_turn_btn: Button = $EndTurnButton
@onready var unit_side: Control = $HandArea/UnitSide
@onready var sit_side: Control = $HandArea/SitSide
@onready var effects_panel: VBoxContainer = $EffectsPanel
@onready var effects_grid: GridContainer = $EffectsPanel/EffectsGrid
@onready var effects_toggle: Button = $EffectsPanel/ToggleBtn
var _active_effects: Array = []
var _unit_scroll_offset: float = 0.0
var _sit_scroll_offset: float = 0.0
var _unit_total_w: float = 0.0
var _sit_total_w: float = 0.0
var _card_w: float = 180.0
var _card_gap: float = 8.0
@onready var territory_panel: PanelContainer = $TerritoryInfoPanel
@onready var t_name: Label = $TerritoryInfoPanel/TVBox/TName
@onready var t_owner: Label = $TerritoryInfoPanel/TVBox/TOwner
@onready var t_terrain: Label = $TerritoryInfoPanel/TVBox/TTerrain
@onready var t_units: Label = $TerritoryInfoPanel/TVBox/TUnitsLabel
@onready var t_close: Button = $TerritoryInfoPanel/TVBox/TClose
@onready var t_buyout: Button = $TerritoryInfoPanel/TVBox/TBuyout
@onready var t_image: TextureRect = $TerritoryInfoPanel/TVBox/TImage
@onready var card_detail_popup: Control = $CardDetailPopup
@onready var card_detail_preview: Control = $CardDetailPopup/DetailPreview
@onready var card_play_btn: Button = $CardDetailPopup/PlayButton
@onready var card_close_btn: Button = $CardDetailPopup/CloseBtn
@onready var draw_popup: Control = $DrawPopup
@onready var draw_popup_card: Control = $DrawPopup/CardPreview
@onready var settings_btn: Button = $TopBar/HBox/SettingsButton
@onready var menu_btn: Button = $TopBar/HBox/MenuButton
@onready var help_btn: Button = $TopBar/HBox/HelpButton
@onready var terr_overlay: Control = $TerritoryOverlay
@onready var terr_overlay_img: TextureRect = $TerritoryOverlay/ImgWrap/TImage
@onready var terr_overlay_name: Label = $TerritoryOverlay/TInfo/TName
@onready var terr_overlay_details: Label = $TerritoryOverlay/TInfo/TDetails
@onready var terr_overlay_units: HBoxContainer = $TerritoryOverlay/TInfo/UnitsScroll/UnitsHBox
@onready var terr_overlay_close: Button = $TerritoryOverlay/TInfo/TClose
@onready var research_popup: Control = $ResearchPopup
@onready var research_title: Label = $ResearchPopup/Title
@onready var research_current_label: Label = $ResearchPopup/CurrentLabel
@onready var research_grid: GridContainer = $ResearchPopup/InventionsScroll/InventionsGrid
@onready var research_close_btn: Button = $ResearchPopup/CloseBtn

const CardWidgetScript := preload("res://scripts/ui/card_widget.gd")
const DeckScript := preload("res://scripts/cards/deck.gd")
const HandScript := preload("res://scripts/cards/hand.gd")
const CardInstanceScript := preload("res://scripts/cards/card_instance.gd")
const BattleResolverScript := preload("res://scripts/combat/battle_resolver.gd")
const CardEffectScript := preload("res://scripts/cards/card_effect.gd")
const PathFinderScript := preload("res://scripts/map/path_finder.gd")
const BattleHandlerScript := preload("res://scripts/combat/battle_handler.gd")
const MapBuilderScript := preload("res://scripts/ui/map/map_builder.gd")
const TerritoryManagerScript := preload("res://scripts/ui/map/territory_manager.gd")
const CardEffectsUIScript := preload("res://scripts/ui/map/card_effects_ui.gd")
const CombatUIScript := preload("res://scripts/ui/map/combat_ui.gd")
const ChoicePopupsScript := preload("res://scripts/ui/map/choice_popups.gd")
const ResearchUIScript := preload("res://scripts/ui/map/research_ui.gd")
const HelpUIScript := preload("res://scripts/ui/map/help_ui.gd")
const OverlayUIScript := preload("res://scripts/ui/map/overlay_ui.gd")
const CardDetailUIScript := preload("res://scripts/ui/map/card_detail_ui.gd")
const BattleOverlayScript := preload("res://scripts/ui/map/battle_overlay.gd")
const ResultPopupScript := preload("res://scripts/ui/map/result_popup.gd")

var _territory_buttons: Dictionary = {}
var _selected_territory: String = ""
var _left_deck: RefCounted = null
var _right_deck: RefCounted = null
var _hand: RefCounted = null
var _player_deployed: Dictionary = {}
var _turn_log: Array = []
var _ai_executed: bool = false
var _detail_card_data: Dictionary = {}
var _placing: bool = false
var _placing_data: Dictionary = {}
var _ghost: Control = null
var _territory_markers: Dictionary = {}
var _bot_active: bool = false
var _bot_timer: float = 0.0
var _bot_phase_done: bool = false
var _bot_deployed_this_phase: bool = false
var _bot_max_turns: int = 6

var _effects_collapsed: bool = false
var _npc_garrisons: Dictionary = {}
var _all_unit_data: Array = []
var _moving: bool = false
var _moving_from: String = ""
var _moving_units: Array = []
var _battle_handler: RefCounted = null
var _combat_phase_active: bool = false
var _card_effect: RefCounted = null

var _map_builder: RefCounted = null
var _territory_mgr: RefCounted = null
var _card_effects_ui: RefCounted = null
var _combat_ui: RefCounted = null
var _choice_popups: RefCounted = null
var _research_ui: RefCounted = null
var _help_ui: RefCounted = null
var _overlay_ui: RefCounted = null
var _card_detail_ui: RefCounted = null
var _battle_overlay: RefCounted = null
var _result_popup: RefCounted = null

func _ready() -> void:
	_bot_active = "--bot" in OS.get_cmdline_args()
	_card_effect = CardEffectScript.new()
	_battle_handler = BattleHandlerScript.new(self)
	_map_builder = MapBuilderScript.new(self)
	_territory_mgr = TerritoryManagerScript.new(self)
	_card_effects_ui = CardEffectsUIScript.new(self, _card_effect)
	_combat_ui = CombatUIScript.new(self)
	_choice_popups = ChoicePopupsScript.new(self)
	_research_ui = ResearchUIScript.new(self)
	_help_ui = HelpUIScript.new(self)
	_overlay_ui = OverlayUIScript.new(self)
	_card_detail_ui = CardDetailUIScript.new(self)
	_battle_overlay = BattleOverlayScript.new(self)
	_result_popup = ResultPopupScript.new(self)

	end_turn_btn.pressed.connect(_on_end_phase)
	t_close.pressed.connect(_close_territory_panel)
	t_buyout.pressed.connect(_on_buyout_territory)
	settings_btn.pressed.connect(_on_settings)
	menu_btn.pressed.connect(_on_menu)
	help_btn.pressed.connect(_on_help)
	draw_popup.gui_input.connect(_on_draw_popup_dismiss)
	card_detail_popup.get_node("Bg").gui_input.connect(_on_card_detail_input)
	card_play_btn.pressed.connect(_on_card_play_pressed)
	card_close_btn.pressed.connect(_on_card_detail_close)
	terr_overlay_close.pressed.connect(_close_territory_overlay)
	terr_overlay.get_node("Bg").gui_input.connect(_on_overlay_bg_click)
	research_close_btn.pressed.connect(_on_research_close)
	ResearchSystem.research_choice_needed.connect(_on_research_choice_needed)
	ResearchSystem.research_completed.connect(_on_research_completed)
	ResearchSystem.periodic_triggered.connect(_on_periodic_triggered)
	effects_toggle.pressed.connect(_toggle_effects)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.turn_changed.connect(_on_turn_changed)
	ResourceManager.resource_changed.connect(_on_resource_changed)
	_update_all_ui()
	call_deferred("_build_map")
	call_deferred("_setup_decks")
	call_deferred("_generate_npc_garrisons")
	call_deferred("_register_deployed")
	call_deferred("_show_intro_if_needed")

func _show_intro_if_needed() -> void:
	if not GameManager.was_intro_shown():
		_show_intro()

func _show_intro() -> void:
	_card_detail_ui.show_intro()

func _setup_decks() -> void:
	_left_deck = DeckScript.new()
	_right_deck = DeckScript.new()
	_hand = HandScript.new(7)
	_left_deck.build_left_deck()
	_right_deck.build_right_deck()
	_auto_draw_initial()

func _auto_draw_initial() -> void:
	for i in range(3):
		_draw_from_deck(_left_deck)
	for i in range(2):
		_draw_from_deck(_right_deck)
	_auto_deploy_initial_units()
	_auto_play_situations()
	Logger.info("GameMap", "Initial draw: %d cards in hand" % _hand.size())

func _auto_deploy_initial_units() -> void:
	var units: Array = _hand.get_cards_by_type("unit")
	var commanders: Array = _hand.get_cards_by_type("commander")
	var to_deploy: Array = []
	for u in units:
		to_deploy.append(u)
	for c in commanders:
		to_deploy.append(c)
	for card_data in to_deploy:
		var instance: RefCounted = CardInstanceScript.new(card_data)
		if not _player_deployed.has("dump_west"):
			_player_deployed["dump_west"] = []
		_player_deployed["dump_west"].append(instance)
		instance.territory_id = "dump_west"
		_hand.remove_by_id(card_data.get("id", ""))
	_territory_mgr.update_territory_marker("dump_west")
	_territory_mgr.update_territory_button_style("dump_west", "player")
	GameManager.set_territory_owner("dump_west", "player")
	_lm("Initial units deployed to dump_west: %d" % to_deploy.size())
	_refresh_hand_display()

func _register_deployed() -> void:
	GameManager.register_player_deployed(_player_deployed)
	_sync_map_controller()

func _sync_map_controller() -> void:
	var mc: Node = get_node_or_null("/root/MapController")
	if mc == null:
		return
	for t_id in _player_deployed:
		var t: RefCounted = mc.get_territory(t_id)
		if t != null:
			t.units.clear()
			for u in _player_deployed[t_id]:
				if u.is_alive():
					t.add_unit(u)
			t.owner = GameManager.get_territory_owner(t_id)

func _auto_play_situations() -> void:
	var situations: Array = _hand.get_cards_by_type("situation")
	var spells: Array = _hand.get_cards_by_type("spell")
	var to_play: Array = []
	for s in situations:
		to_play.append(s)
	for s in spells:
		to_play.append(s)
	for card_data in to_play:
		var cost: Dictionary = card_data.get("cost", {})
		if not cost.is_empty() and not GameManager.can_afford(cost):
			continue
		if not cost.is_empty():
			GameManager.spend(cost)
		_show_auto_card_popup(card_data)
		_card_effects_ui.apply_card_effect(card_data)
		_hand.remove_by_id(card_data.get("id", ""))
		_add_active_effect(card_data)
	_refresh_hand_display()
	_update_resources()

func _show_auto_card_popup(card_data: Dictionary) -> void:
	_card_detail_ui.show_auto_card_popup(card_data)

func _load_card_portrait(card_data: Dictionary) -> Texture2D:
	return _card_detail_ui.load_card_portrait(card_data)

func _add_active_effect(card_data: Dictionary) -> void:
	_card_detail_ui.add_active_effect(card_data)

func _on_effect_card_click(data: Dictionary) -> void:
	Logger.info("GameMap", "Effect card clicked: %s" % Localization.get_card_name(data))
	if _effects_collapsed:
		_effects_collapsed = false
		effects_grid.visible = true
		effects_toggle.text = "▼"
	_show_card_detail(data)
	card_play_btn.visible = false

func _on_effect_card_right_click(data: Dictionary) -> void:
	_on_effect_card_click(data)

func _clear_effects_panel() -> void:
	_active_effects.clear()
	if not effects_grid:
		return
	_clear_children(effects_grid)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		if not child.is_in_group("scroll_arrow"):
			node.remove_child(child)
			child.free()

func _refresh_hand_display() -> void:
	_clear_children(unit_side)
	_clear_children(sit_side)
	var deployed_cards: Array = []
	if _selected_territory != "" and _player_deployed.has(_selected_territory):
		var alive: Array = []
		for u in _player_deployed[_selected_territory]:
			if u.is_alive():
				deployed_cards.append(u.to_dict())
				alive.append(u)
		_player_deployed[_selected_territory] = alive
	var hand_unit_cards: Array = []
	var sit_cards: Array = []
	var all_cards: Array = _hand.get_all()
	for card_data in all_cards:
		if card_data.get("type", "") in ["unit", "commander"]:
			hand_unit_cards.append(card_data)
		else:
			sit_cards.append(card_data)
	var all_unit_cards: Array = deployed_cards + hand_unit_cards
	_place_hand_cards(unit_side, all_unit_cards)
	_place_hand_cards(sit_side, sit_cards)
	if deployed_cards.size() > 0:
		_lm("Territory %s: %d deployed + %d in hand" % [_selected_territory, deployed_cards.size(), hand_unit_cards.size()])

func _place_hand_cards(container: Control, cards: Array) -> void:
	if cards.is_empty():
		return
	var card_w: float = _card_w
	var card_h: float = 270.0
	var container_w: float = container.size.x
	if container_w < 10:
		container_w = container.custom_minimum_size.x
		if container_w < 10:
			container_w = 400.0
	var spacing: float = _card_w + _card_gap
	var total_w: float = card_w + maxf(cards.size() - 1, 0.0) * spacing
	var is_unit: bool = (container == unit_side)
	if is_unit:
		_unit_total_w = total_w
	else:
		_sit_total_w = total_w
	var max_offset: float = maxf(total_w - container_w, 0.0)
	var scroll_off: float = 0.0
	if is_unit:
		_unit_scroll_offset = minf(_unit_scroll_offset, max_offset)
		scroll_off = _unit_scroll_offset
	else:
		_sit_scroll_offset = minf(_sit_scroll_offset, max_offset)
		scroll_off = _sit_scroll_offset
	for i in range(cards.size()):
		var card_data: Dictionary = cards[i]
		var widget := Control.new()
		widget.set_script(load("res://scripts/ui/card_widget.gd"))
		widget.name = "Card_" + str(i)
		widget.custom_minimum_size = Vector2(card_w, card_h)
		widget.size = Vector2(card_w, card_h)
		widget.position = Vector2(i * spacing - scroll_off, 30.0)
		widget.z_index = i
		container.add_child(widget)
		widget.setup(card_data)
		widget.card_clicked.connect(_on_card_left_click)
		widget.card_right_clicked.connect(_on_card_right_click)
	if total_w > container_w:
		_add_scroll_arrows(container, is_unit, container_w)

func _add_scroll_arrows(container: Control, is_unit: bool, container_w: float) -> void:
	var arrow_size: float = 28.0
	var left_btn := Button.new()
	left_btn.text = "<"
	left_btn.name = "ScrollLeft"
	left_btn.add_to_group("scroll_arrow")
	left_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	left_btn.position = Vector2(2, 30)
	left_btn.size = Vector2(arrow_size, arrow_size)
	left_btn.z_index = 100
	left_btn.pressed.connect(_on_scroll_cards.bind(is_unit, -(_card_w + _card_gap)))
	container.add_child(left_btn)
	var right_btn := Button.new()
	right_btn.text = ">"
	right_btn.name = "ScrollRight"
	right_btn.add_to_group("scroll_arrow")
	right_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right_btn.position = Vector2(container_w - arrow_size - 2, 30)
	right_btn.size = Vector2(arrow_size, arrow_size)
	right_btn.z_index = 100
	right_btn.pressed.connect(_on_scroll_cards.bind(is_unit, _card_w + _card_gap))
	container.add_child(right_btn)

func _on_scroll_cards(is_unit: bool, delta: float) -> void:
	if is_unit:
		_unit_scroll_offset = clampf(_unit_scroll_offset + delta, 0.0, maxf(_unit_total_w - unit_side.size.x, 0.0))
	else:
		_sit_scroll_offset = clampf(_sit_scroll_offset + delta, 0.0, maxf(_sit_total_w - sit_side.size.x, 0.0))
	_refresh_hand_display()

func _draw_from_deck(deck: RefCounted) -> void:
	if deck == null or deck.is_empty():
		Logger.info("GameMap", "Deck is empty")
		return
	if _hand.is_full():
		Logger.info("GameMap", "Hand is full (7 cards)")
		return
	var card: Dictionary = deck.draw_card()
	if card.is_empty():
		return
	_hand.add_card(card)
	_refresh_hand_display()
	Logger.info("GameMap", "Drew card: %s" % Localization.get_card_name(card))

var _city_map_tex: Texture2D = null

func _process(_delta: float) -> void:
	if _placing and _ghost != null:
		_ghost.global_position = get_global_mouse_position() - _ghost.size * 0.25
	queue_redraw()
	if _bot_active:
		_bot_timer -= _delta
		if _bot_timer <= 0:
			_bot_tick()

func _draw() -> void:
	if _city_map_tex == null:
		_city_map_tex = _reload_city_map()
	if _city_map_tex == null:
		if Engine.get_frames_drawn() % 300 == 0:
			Logger.error("GameMap", "_draw: city_map_tex is NULL, cannot draw map")
		return
	var tex_size: Vector2 = _city_map_tex.get_size()
	var area_pos: Vector2 = map_area.position
	var area_size: Vector2 = map_area.size
	if area_size.x < 1 or area_size.y < 1:
		return
	var scale_x: float = area_size.x / tex_size.x
	var scale_y: float = area_size.y / tex_size.y
	var s: float = maxf(scale_x, scale_y)
	var draw_size: Vector2 = tex_size * s
	var offset: Vector2 = area_pos + (area_size - draw_size) * 0.5
	draw_texture_rect(_city_map_tex, Rect2(offset, draw_size), false)

func _reload_city_map() -> Texture2D:
	var paths: Array = [
		"res://assets/sprites/map/city_map.jpg",
		"res://assets/sprites/map/city_map_backup.jpg",
	]
	for p in paths:
		var img := Image.new()
		if img.load(p) == OK:
			var tex := ImageTexture.create_from_image(img)
			if tex != null:
				Logger.info("GameMap", "City map reloaded from %s" % p)
				var city_bg: TextureRect = map_area.get_node_or_null("CityBg")
				if city_bg:
					city_bg.texture = tex
				return tex
	return null

func _on_card_left_click(data: Dictionary) -> void:
	if data.get("type", "") in ["unit", "commander"]:
		_enter_placing_mode(data)
	else:
		_play_non_unit_card(data)

func _on_card_right_click(data: Dictionary) -> void:
	_show_card_detail(data)
	card_play_btn.visible = false

func _on_draw_popup_dismiss(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		draw_popup.visible = false

func _enter_placing_mode(data: Dictionary) -> void:
	_placing = true
	_placing_data = data
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	_ghost = Control.new()
	_ghost.name = "GhostCard"
	_ghost.set_anchors_preset(Control.PRESET_CENTER)
	_ghost.custom_minimum_size = Vector2(140, 210)
	_ghost.size = Vector2(140, 210)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var script := load("res://scripts/ui/card_widget.gd")
	_ghost.set_script(script)
	_ghost.z_index = 200
	_ghost.modulate = Color(1, 1, 1, 0.7)
	add_child(_ghost)
	_ghost.setup(data)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lm("Placing mode: click a territory to deploy %s" % Localization.get_card_name(data))

func _cancel_placing() -> void:
	_placing = false
	_placing_data = {}
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if _placing:
				_cancel_placing()
			elif _moving:
				_moving = false
				_moving_from = ""
				_moving_units = []
				_territory_mgr.clear_move_highlights()
				_lm("Move cancelled")
			return
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_end_phase()
			return
	if _placing:
		if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
			_cancel_placing()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var drop_pos: Vector2 = get_global_mouse_position()
			var dropped: bool = false
			for t_id in _territory_buttons:
				var btn: Button = _territory_buttons[t_id]
				var btn_rect: Rect2 = Rect2(btn.global_position, btn.size)
				if btn_rect.has_point(drop_pos):
					_deploy_to_territory(t_id)
					dropped = true
					break
			if not dropped:
				_cancel_placing()
			accept_event()

func _deploy_to_territory(target: String) -> void:
	var data: Dictionary = _placing_data
	_cancel_placing()
	var is_from_hand: bool = _hand.has_card(data.get("id", ""))
	var cost: Dictionary = data.get("cost", {})
	if is_from_hand:
		if not GameManager.can_afford(cost):
			_lm("Cannot afford: %s" % Localization.get_card_name(data))
			return
		GameManager.spend(cost)
	var source_tid: String = ""
	var source_instance: RefCounted = null
	if not is_from_hand and _selected_territory != "":
		if _player_deployed.has(_selected_territory):
			for u in _player_deployed[_selected_territory]:
				if u.is_alive() and u.card_data.get("id", "") == data.get("id", ""):
					source_instance = u
					source_tid = _selected_territory
					break
	var instance: RefCounted
	if source_instance != null:
		instance = source_instance
		_player_deployed[source_tid].erase(instance)
		if _player_deployed[source_tid].is_empty():
			_player_deployed.erase(source_tid)
		_territory_mgr.update_territory_marker(source_tid)
	else:
		instance = CardInstanceScript.new(data)
		_hand.remove_by_id(data.get("id", ""))
	if not _player_deployed.has(target):
		_player_deployed[target] = []
	_player_deployed[target].append(instance)
	instance.territory_id = target
	_remove_card_widget_by_id(data.get("id", ""))
	_update_resources()
	_territory_mgr.update_territory_marker(target)
	_refresh_hand_display()
	_show_deploy_feedback(target, Localization.get_card_name(data))
	if _npc_garrisons.has(target) and _count_alive(_npc_garrisons[target]) > 0:
		_resolve_npc_battle(target)
	else:
		_territory_mgr.update_territory_button_style(target, "player")
		GameManager.set_territory_owner(target, "player")
		_lm("Deployed %s to %s (captured)" % [Localization.get_card_name(data), target])
	GameManager.register_player_deployed(_player_deployed)

func _count_alive(units: Array) -> int:
	var c: int = 0
	for u in units:
		if u.is_alive():
			c += 1
	return c

func _show_deploy_feedback(t_id: String, card_name: String) -> void:
	_card_detail_ui.show_deploy_feedback(t_id, card_name)

func _resolve_npc_battle(t_id: String) -> void:
	var p_units: Array = _get_alive(_player_deployed.get(t_id, []))
	var e_units: Array = _get_alive(_npc_garrisons.get(t_id, []))
	if p_units.is_empty() or e_units.is_empty():
		return
	_battle_handler.queue(t_id, p_units, e_units, true)
	_battle_handler.start(_on_npc_battle_done)

func _get_alive(units: Array) -> Array:
	var alive: Array = []
	for u in units:
		if u.is_alive():
			alive.append(u)
	return alive

func _on_npc_battle_done(results: Array) -> void:
	for result in results:
		_apply_battle_result(result)

func _apply_battle_result(result: Dictionary) -> void:
	var t_id: String = result.get("territory_id", "")
	var attacker_won: bool = result.get("attacker_won", false)
	var player_is_attacker: bool = result.get("player_is_attacker", true)
	var player_won: bool = attacker_won if player_is_attacker else not attacker_won

	if player_won:
		GameManager.set_territory_owner(t_id, "player")
		_npc_garrisons.erase(t_id)
		_territory_mgr.update_npc_marker(t_id)
		var alive: Array = _get_alive(_player_deployed.get(t_id, []))
		if alive.is_empty():
			_player_deployed.erase(t_id)
		else:
			_player_deployed[t_id] = alive
		_territory_mgr.update_territory_button_style(t_id, "player")
		var t_name_str: String = Localization.get_territory_name(CardDatabase.get_territory(t_id))
		_result_popup.show_victory(t_name_str)
		_lm("COMBAT WIN at %s!" % t_id)
		_check_victory()
	else:
		GameManager.set_territory_owner(t_id, "enemy")
		_player_deployed.erase(t_id)
		var alive: Array = _get_alive(_npc_garrisons.get(t_id, []))
		if alive.is_empty():
			_npc_garrisons.erase(t_id)
		else:
			_npc_garrisons[t_id] = alive
		_territory_mgr.update_npc_marker(t_id)
		var t_name_str: String = Localization.get_territory_name(CardDatabase.get_territory(t_id))
		_result_popup.show_defeat(t_name_str)
		_lm("COMBAT LOSS at %s!" % t_id)
	_territory_mgr.update_territory_marker(t_id)
	GameManager.register_player_deployed(_player_deployed)

func _check_victory() -> void:
	var total: int = CardDatabase._territories.size()
	var owned: int = GameManager.get_player_territory_count()
	if owned < total:
		return
	_lm("VICTORY! All %d territories captured!" % total)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -300
	vbox.offset_top = -200
	vbox.offset_right = 300
	vbox.offset_bottom = 200
	vbox.z_index = 501
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	var t1 := Label.new()
	t1.text = "ПОБЕДА!"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 64)
	t1.add_theme_color_override("font_color", Color(1, 0.84, 0))
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t1.add_theme_constant_override("outline_size", 5)
	vbox.add_child(t1)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)
	var t2 := Label.new()
	t2.text = "Все %d территорий захвачены!\nКартонная империя победила!" % total
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 30)
	t2.add_theme_color_override("font_color", Color(1, 1, 1))
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	t2.add_theme_constant_override("outline_size", 3)
	vbox.add_child(t2)
	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(sp2)
	var btn := Button.new()
	btn.text = "В ГЛАВНОЕ МЕНЮ"
	btn.custom_minimum_size = Vector2(250, 60)
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(func():
		SaveManager.save_game()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(btn)

func _play_non_unit_card(data: Dictionary) -> void:
	var cost: Dictionary = data.get("cost", {})
	if not cost.is_empty() and not GameManager.can_afford(cost):
		_lm("Cannot afford: %s" % Localization.get_card_name(data))
		return
	if not cost.is_empty():
		GameManager.spend(cost)
	_card_effects_ui.apply_card_effect(data)
	_hand.remove_by_id(data.get("id", ""))
	_remove_card_widget_by_id(data.get("id", ""))
	_update_resources()
	Logger.info("GameMap", "Played card: %s" % Localization.get_card_name(data))


func _lm(msg: String) -> void:
	Logger.info("GameMap", msg)
	var f := FileAccess.open("user://live.log", FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_string("[%s] %s\n" % [Time.get_time_string_from_system(), msg])
		f.close()

func _remove_card_widget_by_id(card_id: String) -> void:
	for container in [unit_side, sit_side]:
		for child in container.get_children():
			if child.has_method("get_card_data") and child.get_card_data().get("id", "") == card_id:
				child.queue_free()
				return
	_refresh_hand_display()

func _toggle_effects() -> void:
	_effects_collapsed = not _effects_collapsed
	effects_grid.visible = not _effects_collapsed
	effects_toggle.text = "▼" if not _effects_collapsed else "▶"

func _show_card_detail(card_data: Dictionary) -> void:
	_card_detail_ui.show_card_detail(card_data)

func _on_card_detail_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		card_detail_popup.visible = false
		card_play_btn.visible = false
		card_detail_preview.scale = Vector2.ZERO

func _on_card_play_pressed() -> void:
	var data: Dictionary = _detail_card_data
	card_detail_popup.visible = false
	card_play_btn.visible = false
	_detail_card_data = {}
	if data.is_empty():
		return
	if data.get("type", "") in ["unit", "commander"]:
		_enter_placing_mode(data)
	else:
		_play_non_unit_card(data)

func _on_card_detail_close() -> void:
	card_detail_popup.visible = false
	card_play_btn.visible = false
	card_detail_preview.scale = Vector2.ZERO
	_detail_card_data = {}

func _play_card(data: Dictionary) -> void:
	var card_id: String = data.get("id", "")
	var cost: Dictionary = data.get("cost", {})
	if not GameManager.can_afford(cost):
		Logger.info("GameMap", "Cannot afford card: %s" % Localization.get_card_name(data))
		return
	GameManager.spend(cost)
	_card_effects_ui.apply_card_effect(data)
	_hand.remove_by_id(card_id)
	_remove_card_widget_by_id(card_id)
	_update_resources()
	Logger.info("GameMap", "Played card: %s" % Localization.get_card_name(data))

func _build_map() -> void:
	_map_builder.build_map()

func _on_territory_gui_input(event: InputEvent, t_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_territory_mgr.attack_territory(t_id)

func _on_territory_clicked(t_id: String) -> void:
	if _placing:
		_deploy_to_territory(t_id)
		return
	if _moving:
		_territory_mgr.finish_move(t_id)
		return
	_select_territory(t_id)

func _select_territory(t_id: String) -> void:
	_territory_mgr.select_territory(t_id)

func _show_territory_info(t_id: String) -> void:
	_selected_territory = t_id
	var data: Dictionary = CardDatabase.get_territory(t_id)
	if data.is_empty():
		return
	t_name.text = Localization.get_territory_name(data)
	var owner: String = GameManager.get_territory_owner(t_id)
	t_owner.text = Localization.t("owner.label") + (Localization.t("owner.you") if owner == "player" else Localization.t("owner.enemy") if owner == "enemy" else Localization.t("owner.neutral"))
	var tn := {"dump":Localization.t("terrain.dump"),"station":Localization.t("terrain.station"),"square_three_stations":Localization.t("terrain.square_three_stations"),
		"den":Localization.t("terrain.den"),"supermarket_dumpster":Localization.t("terrain.supermarket_dumpster"),"pharmacy_dumpster":Localization.t("terrain.pharmacy_dumpster"),
		"dacha":Localization.t("terrain.dacha"),"obrygalovka":Localization.t("terrain.obrygalovka"),"kutuzka":Localization.t("terrain.kutuzka"),"open_street":Localization.t("terrain.open_street")}
	t_terrain.text = Localization.t("terrain.type_label") + tn.get(data.get("terrain",""), data.get("terrain",""))
	var garrison_text: String = ""
	if _npc_garrisons.has(t_id):
		var gc: int = _count_alive(_npc_garrisons[t_id])
		if gc > 0:
			garrison_text = " | Гарнизон NPC: x%d" % gc
	if _player_deployed.has(t_id):
		var pc: int = _count_alive(_player_deployed[t_id])
		if pc > 0:
			garrison_text += " | Ваши: x%d" % pc
	if owner == "neutral" and GameManager.can_buyout_territory(t_id) and garrison_text == "":
		var cost: Dictionary = GameManager.get_buyout_cost(t_id)
		t_units.text = Localization.t("buyout.label") % cost.get("coins", 0) + garrison_text
		t_buyout.visible = true
		t_buyout.text = Localization.t("buyout.button") % cost.get("coins", 0)
	else:
		t_units.text = Localization.t("territory.resources") % [data.get("resource_bottles",0), data.get("resource_coins",0), data.get("resource_rolltons",0)] + garrison_text
		t_buyout.visible = false
	var img_path: String = "res://assets/sprites/map/territories/%s.jpg" % t_id
	var tex := SafeLoader.texture(img_path)
	if tex:
		t_image.texture = tex
		t_image.visible = true
	else:
		t_image.visible = false
	territory_panel.visible = true

func _close_territory_panel() -> void:
	territory_panel.visible = false
	_selected_territory = ""

func _on_buyout_territory() -> void:
	if _selected_territory == "":
		return
	if GameManager.buyout_territory(_selected_territory):
		t_buyout.visible = false
		t_owner.text = Localization.t("owner.label") + Localization.t("owner.you")
		_update_resources()
		_territory_mgr.update_territory_button_style(_selected_territory, "player")
		Logger.info("GameMap", "Territory bought out: %s" % _selected_territory)

func _update_all_ui() -> void:
	turn_label.text = Localization.t("turn.label") % GameManager.get_current_turn()
	var pn: PackedStringArray = [Localization.t("phase.resources"),Localization.t("phase.draw"),Localization.t("phase.movement"),Localization.t("phase.combat"),Localization.t("phase.events"),Localization.t("phase.end")]
	phase_label.text = pn[GameManager.get_current_phase()]
	if GameManager.is_ideology_chosen():
		ideology_label.text = "Строй: " + (Localization.t("ideology.alcoholism") if GameManager.get_ideology() == "alcoholism" else Localization.t("ideology.dermocracy"))
	else:
		ideology_label.text = "Строй: —"
	if GameManager.is_religion_chosen():
		var rname: String = GameManager.get_religion()
		religion_label.text = "Верование: " + ("Многобомжие" if rname == "mnogobomzhie" else "Трезвость")
	else:
		religion_label.text = "Верование: —"
	_update_resources()

func _update_resources() -> void:
	var r := GameManager.get_resources()
	bottles_label.text = "%s: %d" % [Localization.t("resource.bottles"), r.get("bottles", 0)]
	aluminum_label.text = "%s: %d" % [Localization.t("resource.aluminum"), r.get("aluminum", 0)]
	coins_label.text = "%s: %d" % [Localization.t("resource.coins"), r.get("coins", 0)]
	vodka_label.text = "%s: %d" % [Localization.t("resource.vodka"), r.get("rolltons", 0)]
	cardboard_label.text = "%s: %d" % [Localization.t("resource.cardboard"), r.get("cardboard", 0)]
	respect_label.text = "%s: %d" % [Localization.t("respect.label"), GameManager.get_respect()]
	pop_label.text = "%s: %d" % [Localization.t("population.label"), GameManager.get_population()]

func _on_phase_changed(phase: int) -> void:
	var pn: PackedStringArray = [Localization.t("phase.resources"),Localization.t("phase.draw"),Localization.t("phase.movement"),Localization.t("phase.combat"),Localization.t("phase.events"),Localization.t("phase.end")]
	phase_label.text = pn[phase]
	if phase == 0:
		ResourceManager.apply_income()
		_update_resources()

func _on_turn_changed(turn_number: int) -> void:
	turn_label.text = Localization.t("turn.label") % turn_number

func _on_resource_changed(_resource: String, _new_value: int) -> void:
	_update_resources()

func _on_end_phase() -> void:
	if _result_popup != null and _result_popup.is_showing():
		_result_popup.dismiss()
	var phase: int = GameManager.get_current_phase()
	match phase:
		0:
			_spawn_territory_units()
			_update_resources()
			Logger.info("GameMap", "Phase 0: Income applied, territory units spawned")
		1:
			_auto_draw_turn()
			Logger.info("GameMap", "Phase 1: Cards drawn (%d in hand)" % _hand.size())
		2:
			Logger.info("GameMap", "Phase 2: Movement done, advancing to combat")
		3:
			_combat_phase_active = true
			_combat_ui.execute_player_combat()
			return
		4:
			Logger.info("GameMap", "Phase 4: Events")
		5:
			_combat_ui.end_player_turn_units()
			_check_religion_ideology()
			return
	GameManager.advance_phase.call_deferred()

func _check_religion_ideology() -> void:
	if not GameManager.is_religion_chosen() and GameManager.get_player_territory_count() >= 3:
		_show_religion_choice()
		return
	if not GameManager.is_ideology_chosen() and GameManager.get_player_territory_count() >= 5:
		_show_ideology_choice()
		return
	GameManager.advance_phase.call_deferred()

func _spawn_territory_units() -> void:
	var spawned: int = 0
	if not _player_deployed.has("dump_west") and GameManager.get_territory_owner("dump_west") == "player":
		_player_deployed["dump_west"] = []
		var all_unit_data: Array = CardDatabase._units.values()
		if not all_unit_data.is_empty():
			for _j in range(2):
				var template: Dictionary = all_unit_data[randi() % all_unit_data.size()]
				var instance: RefCounted = CardInstanceScript.new(template)
				instance.territory_id = "dump_west"
				_player_deployed["dump_west"].append(instance)
				spawned += 1
	if spawned > 0:
		_lm("Spawned %d units from territories" % spawned)

func _auto_draw_turn() -> void:
	if _left_deck == null:
		_setup_decks()
		return
	if _left_deck.is_empty():
		_left_deck.build_left_deck()
	if _right_deck.is_empty():
		_right_deck.build_right_deck()
	for i in range(2):
		_draw_from_deck(_left_deck)
	for i in range(2):
		_draw_from_deck(_right_deck)

func _show_religion_choice() -> void:
	_choice_popups.show_religion_choice()

func _show_ideology_choice() -> void:
	_choice_popups.show_ideology_choice()

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_menu() -> void:
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_help() -> void:
	_help_ui.show_help()

func _show_territory_overlay(t_id: String) -> void:
	_overlay_ui.show_territory_overlay(t_id)

func _close_territory_overlay() -> void:
	terr_overlay.visible = false

func _on_overlay_bg_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_territory_overlay()

func _start_move_mode(from_id: String) -> void:
	_territory_mgr.start_move_mode(from_id)

func _generate_npc_garrisons() -> void:
	_territory_mgr.generate_npc_garrisons()

func _on_research_choice_needed(_turn: int) -> void:
	_research_ui.show_research_popup()

func _on_research_completed(inv_id: String) -> void:
	_lm("Research completed: %s" % inv_id)
	var inv: Dictionary = ResearchSystem.get_current()
	if inv.is_empty():
		for c in ResearchSystem.get_completed():
			if c.get("id", "") == inv_id:
				inv = c
				break
	_research_ui.show_research_result_popup(inv)

func _on_research_close() -> void:
	research_popup.visible = false

func _on_periodic_triggered(inv_id: String) -> void:
	var inv: Dictionary = {}
	for c in ResearchSystem.get_completed():
		if c.get("id", "") == inv_id:
			inv = c
			break
	_research_ui.show_periodic_popup(inv)

func _bot_tick() -> void:
	if _result_popup != null and _result_popup.is_showing():
		_result_popup.dismiss()
		_bot_timer = 0.3
		return
	var intro: Node = _find_child_recursive(self, "IntroOverlay")
	if intro:
		intro.queue_free()
		_bot_timer = 0.5
		return
	var phase: int = GameManager.get_current_phase()
	var turn: int = GameManager.get_current_turn()
	if turn > _bot_max_turns:
		Logger.info("BOT", "Done! %d turns played" % _bot_max_turns)
		_bot_active = false
		return
	if phase != _bot_last_phase:
		_bot_phase_done = false
		_bot_deployed_this_phase = false
		_bot_last_phase = phase
		Logger.info("BOT", "Turn %d Phase %d" % [turn, phase])
	match phase:
		0, 1, 4:
			_bot_press_end_phase()
			_bot_timer = 0.3
		2:
			if not _bot_deployed_this_phase:
				_bot_deploy_card()
				_bot_deployed_this_phase = true
				_bot_timer = 0.5
			else:
				_bot_press_end_phase()
				_bot_timer = 0.3
		3:
			_bot_phase_done = true
			_bot_press_end_phase()
			_bot_timer = 0.5
		5:
			_bot_press_end_phase()
			_bot_timer = 0.5
		_:
			_bot_press_end_phase()
			_bot_timer = 0.3

var _bot_last_phase: int = -1

func _bot_press_end_phase() -> void:
	end_turn_btn.pressed.emit()

func _bot_deploy_card() -> void:
	var cards: Array = _hand.get_all()
	var unit_card: Dictionary = {}
	for c in cards:
		if c.get("type", "") in ["unit", "commander"]:
			unit_card = c
			break
	if unit_card.is_empty():
		Logger.info("BOT", "No unit cards in hand")
		return
	var cost: Dictionary = unit_card.get("cost", {})
	if not GameManager.can_afford(cost):
		Logger.info("BOT", "Cannot afford %s" % Localization.get_card_name(unit_card))
		return
	GameManager.spend(cost)
	var target: String = ""
	var adjacent_to_owned: Array = []
	for t_id in _territory_buttons:
		var owner: String = GameManager.get_territory_owner(t_id)
		if owner == "player":
			var adj: Array = CardDatabase.get_adjacent_territories(t_id)
			for a in adj:
				var a_owner: String = GameManager.get_territory_owner(a)
				if a_owner != "player" and not adjacent_to_owned.has(a):
					adjacent_to_owned.append(a)
	for t_id in adjacent_to_owned:
		target = t_id
		break
	if target == "":
		for t_id in _territory_buttons:
			if GameManager.get_territory_owner(t_id) != "player":
				target = t_id
				break
	if target == "":
		target = "dump_west"
	Logger.info("BOT", "Deploy %s -> %s" % [Localization.get_card_name(unit_card), target])
	_enter_placing_mode(unit_card)
	if _placing:
		_deploy_to_territory(target)

func _find_child_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found: Node = _find_child_recursive(child, target_name)
		if found:
			return found
	return null
