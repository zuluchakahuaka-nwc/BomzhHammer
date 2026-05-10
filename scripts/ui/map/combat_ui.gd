class_name CombatUI
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func execute_player_combat() -> void:
	var enemy_deployed: Dictionary = AIController.get_deployed()
	var contested: Array = []
	for t_id in _map._player_deployed:
		if enemy_deployed.has(t_id):
			contested.append(t_id)
	if contested.is_empty():
		start_enemy_turn()
		return
	for t_id in contested:
		var p_units: Array = _get_alive(_map._player_deployed.get(t_id, []))
		var e_units: Array = _get_alive(enemy_deployed.get(t_id, []))
		if p_units.is_empty() or e_units.is_empty():
			continue
		var owner: String = GameManager.get_territory_owner(t_id)
		var player_is_attacker: bool = (owner != "player")
		var attackers: Array = p_units if player_is_attacker else e_units
		var defenders: Array = e_units if player_is_attacker else p_units
		_map._battle_handler.queue(t_id, attackers, defenders, player_is_attacker)
	_map._battle_handler.start(_on_player_combat_done)

func _on_player_combat_done(results: Array) -> void:
	for result in results:
		_map._apply_battle_result(result)
	start_enemy_turn()

func start_enemy_turn() -> void:
	if AIController._left_deck == null:
		AIController.init_decks()
	GameManager.register_enemy_deployed(AIController.get_deployed())
	AIController.execute_pre_combat()
	var contested: Array = AIController.get_enemy_contested()
	if contested.is_empty():
		AIController.execute_post_combat()
		finish_combat_phase()
		return
	for t_id in contested:
		var p_units: Array = _get_alive(_map._player_deployed.get(t_id, []))
		var e_units: Array = _get_alive(AIController.get_deployed().get(t_id, []))
		if p_units.is_empty() or e_units.is_empty():
			continue
		var owner: String = GameManager.get_territory_owner(t_id)
		var player_is_attacker: bool = (owner == "enemy")
		var attackers: Array = e_units if not player_is_attacker else p_units
		var defenders: Array = p_units if not player_is_attacker else e_units
		_map._battle_handler.queue(t_id, attackers, defenders, player_is_attacker)
	_map._battle_handler.start(_on_enemy_combat_done)

func _on_enemy_combat_done(results: Array) -> void:
	for result in results:
		_map._apply_battle_result(result)
	AIController.execute_post_combat()
	finish_combat_phase()

func finish_combat_phase() -> void:
	_map._combat_phase_active = false
	for t_id in _map._player_deployed:
		if _get_alive(_map._player_deployed[t_id]).size() > 0:
			GameManager.set_territory_owner(t_id, "player")
	_map._update_all_ui()
	if not GameManager.is_religion_chosen() and GameManager.get_player_territory_count() >= 3:
		_map._show_religion_choice()
		return
	if not GameManager.is_ideology_chosen() and GameManager.get_player_territory_count() >= 5:
		_map._show_ideology_choice()
		return
	GameManager.advance_phase()

func end_player_turn_units() -> void:
	for t_id in _map._player_deployed:
		for unit in _map._player_deployed[t_id]:
			unit.tick_buffs()
			if unit.is_alive():
				unit.heal(1)
	if ResearchSystem != null:
		ResearchSystem.tick()
		var turn: int = GameManager.get_current_turn()
		ResearchSystem.check_research_turn(turn)

func _get_alive(units: Array) -> Array:
	var alive: Array = []
	for u in units:
		if u.is_alive():
			alive.append(u)
	return alive
