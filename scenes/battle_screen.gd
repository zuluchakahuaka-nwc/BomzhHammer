extends Control

signal battle_finished(result: Dictionary)

const BattleAnimScript := preload("res://scripts/combat/battle_anim.gd")
const BattleResolverScript := preload("res://scripts/combat/battle_resolver.gd")

@onready var anim_rect: TextureRect = $AnimRect
@onready var title_label: Label = $TitleLabel
@onready var territory_label: Label = $TerritoryLabel
@onready var player_panel: VBoxContainer = $PanelsHBox/PlayerPanel
@onready var enemy_panel: VBoxContainer = $PanelsHBox/EnemyPanel
@onready var player_units: VBoxContainer = $PanelsHBox/PlayerPanel/PlayerUnits
@onready var enemy_units: VBoxContainer = $PanelsHBox/EnemyPanel/EnemyUnits
@onready var combat_log: RichTextLabel = $CombatLog
@onready var action_btn: Button = $ActionButton
@onready var back_btn: Button = $BackButton
@onready var result_label: Label = $ResultLabel

var _anim: RefCounted = null
var _resolver: RefCounted = null
var _territory_id: String = ""
var _attacker_units: Array = []
var _defender_units: Array = []
var _player_is_attacker: bool = true
var _result_data: Dictionary = {}

func _ready() -> void:
	action_btn.pressed.connect(_on_action)
	back_btn.pressed.connect(_on_back)
	_anim = BattleAnimScript.new()
	_resolver = BattleResolverScript.new()

func setup(territory_id: String, attacker_units: Array, defender_units: Array, player_is_attacker: bool = true) -> void:
	_territory_id = territory_id
	_attacker_units = attacker_units
	_defender_units = defender_units
	_player_is_attacker = player_is_attacker
	_result_data = {}

	var t: Dictionary = CardDatabase.get_territory(territory_id)
	territory_label.text = t.get("name_ru", territory_id) if not t.is_empty() else territory_id

	if player_is_attacker:
		title_label.text = Localization.t("battle.title.attack")
		action_btn.text = Localization.t("battle.btn.attack")
		$PanelsHBox/PlayerPanel/PlayerLabel.text = Localization.t("battle.player.attack")
		$PanelsHBox/EnemyPanel/EnemyLabel.text = Localization.t("battle.enemy.defense")
	else:
		title_label.text = Localization.t("battle.title.defense")
		action_btn.text = Localization.t("battle.btn.defend")
		$PanelsHBox/PlayerPanel/PlayerLabel.text = Localization.t("battle.player.defense")
		$PanelsHBox/EnemyPanel/EnemyLabel.text = Localization.t("battle.enemy.attackers")

	_populate_units()
	combat_log.clear()
	result_label.text = ""
	result_label.visible = false
	action_btn.disabled = false
	action_btn.visible = true
	back_btn.visible = false
	anim_rect.visible = false
	_anim.reset()
	if _anim.get_frame_count() > 0:
		anim_rect.texture = _anim.get_current_frame()

func _populate_units() -> void:
	for child in player_units.get_children():
		child.queue_free()
	for child in enemy_units.get_children():
		child.queue_free()
	if _player_is_attacker:
		_fill_unit_list(player_units, _attacker_units)
		_fill_unit_list(enemy_units, _defender_units)
	else:
		_fill_unit_list(player_units, _defender_units)
		_fill_unit_list(enemy_units, _attacker_units)

func _fill_unit_list(container: VBoxContainer, units: Array) -> void:
	for u in units:
		var label := Label.new()
		var u_atk: int = u.attack if u is RefCounted else u.get("attack", 0)
		var u_def: int = u.defense if u is RefCounted else u.get("defense", 0)
		var u_hp: int = u.current_hp if u is RefCounted else u.get("hp", 1)
		var u_name: String = u.get_name() if u.has_method("get_name") else str(u)
		label.text = "%s  ATK:%d DEF:%d HP:%d" % [u_name, u_atk, u_def, u_hp]
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0, 0, 0))
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
		label.add_theme_constant_override("outline_size", 4)
		container.add_child(label)

func _process(delta: float) -> void:
	if _anim == null or not _anim.is_playing():
		return
	_anim.tick(delta)
	anim_rect.texture = _anim.get_current_frame()

func _on_action() -> void:
	action_btn.disabled = true
	anim_rect.visible = true
	_anim.play()
	_resolve_battle()

func _resolve_battle() -> void:
	var territory: Dictionary = CardDatabase.get_territory(_territory_id)
	var result: Dictionary = _resolver.resolve_multi(_attacker_units, _defender_units, territory)
	_log_battle(result)
	var attacker_won: bool = result.get("player_won", false)
	_result_data = {
		"territory_id": _territory_id,
		"attacker_won": attacker_won,
		"player_is_attacker": _player_is_attacker,
		"attacker_units": _attacker_units,
		"defender_units": _defender_units
	}
	if _anim.is_finished():
		_show_result()
	else:
		_anim.animation_finished.connect(_show_result, ConnectFlags.CONNECT_ONE_SHOT)

func _show_result() -> void:
	var attacker_won: bool = _result_data.get("attacker_won", false)
	var player_won: bool = attacker_won if _player_is_attacker else not attacker_won
	if player_won:
		result_label.text = Localization.t("battle.result.win")
		result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		result_label.text = Localization.t("battle.result.loss")
		result_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	result_label.visible = true
	action_btn.visible = false
	back_btn.visible = true
	back_btn.text = Localization.t("battle.btn.continue")

func _on_back() -> void:
	battle_finished.emit(_result_data)

func _log_battle(result: Dictionary) -> void:
	combat_log.clear()
	for duel in result.get("rounds", []):
		var a_id: String = duel.get("attacker_id", "?")
		var d_id: String = duel.get("defender_id", "?")
		combat_log.append_text("[color=yellow]%s vs %s[/color]\n" % [a_id, d_id])
		for r in duel.get("rounds", []):
			combat_log.append_text("  Р%d: урон %d | контр %d (HP %d/%d)\n" % [
				r.get("round", 0), r.get("atk_damage", 0), r.get("def_damage", 0),
				r.get("attacker_hp", 0), r.get("defender_hp", 0)])
