extends Node

signal quest_step_completed(quest_id: String, step: int)
signal quest_completed(quest_id: String, reward: Dictionary)

var _QUESTS: Dictionary = {
	"quest_borba_za_tron": {
		"id": "quest_borba_za_tron",
		"name_ru": "Борьба за трон",
		"description_ru": "Корона из Бургер Кинга → Закулисные интриги → Игры Престолов",
		"steps": [
			{
				"step": 1,
				"description_ru": "Найди корону из Бургер Кинга",
				"type": "own_territories",
				"count": 7,
				"reward": {"respect": 5}
			},
			{
				"step": 2,
				"description_ru": "Закулисные интриги — накопи уважение",
				"type": "reach_respect",
				"count": 10,
				"reward": {"resource": {"coins": 10, "bottles": 5}}
			},
			{
				"step": 3,
				"description_ru": "Игры Престолов — захвати 3 свалки",
				"type": "own_terrain_count",
				"terrain": "dump",
				"count": 3,
				"reward": {"title": "Легендарный титул", "achievement": "ach_kuzmich"}
			}
		],
		"final_reward": {"respect": 10, "achievement": "ach_legendarny_bomzh"}
	},
	"quest_samogon_reactor": {
		"id": "quest_samogon_reactor",
		"name_ru": "Самогонный реактор",
		"description_ru": "Исследовать → Построить → Запустить",
		"steps": [
			{
				"step": 1,
				"description_ru": "Исследовать технологию",
				"type": "own_territories",
				"count": 4,
				"reward": {"resource": {"cardboard": 5}}
			},
			{
				"step": 2,
				"description_ru": "Собрать ресурсы для строительства",
				"type": "reach_resource",
				"resource": "cardboard",
				"count": 8,
				"reward": {"resource": {"bottles": 3}}
			},
			{
				"step": 3,
				"description_ru": "Построить самогонный реактор",
				"type": "build_building",
				"building_id": "samogon_reactor",
				"reward": {"happiness": 50}
			}
		],
		"final_reward": {"happiness": 50, "achievement": "ach_religion_mnogobomzhie"}
	},
	"quest_zhivotnovodstvo": {
		"id": "quest_zhivotnovodstvo",
		"name_ru": "Животноводство",
		"description_ru": "Собаки — лучшие друзья бомжей",
		"steps": [
			{
				"step": 1,
				"description_ru": "Заведи первую стаю собак",
				"type": "deploy_unit",
				"unit_tag": "beast",
				"count": 1,
				"reward": {"resource": {"bottles": 3}}
			},
			{
				"step": 2,
				"description_ru": "Накопи 5 отрядов",
				"type": "own_territories",
				"count": 5,
				"reward": {"respect": 3}
			}
		],
		"final_reward": {"achievement": "ach_zhivotnovodstvo"}
	}
}

var _player_quest_progress: Dictionary = {}
var _enemy_quest_progress: Dictionary = {}

func _ready() -> void:
	pass

func get_quest_data(quest_id: String) -> Dictionary:
	return _QUESTS.get(quest_id, {})

func get_all_quest_ids() -> Array:
	return _QUESTS.keys()

func get_current_step(quest_id: String, owner: String) -> int:
	var progress: Dictionary = _get_progress(owner)
	return progress.get(quest_id, {}).get("current_step", 0)

func is_quest_completed(quest_id: String, owner: String) -> bool:
	var progress: Dictionary = _get_progress(owner)
	return progress.get(quest_id, {}).get("completed", false)

func is_quest_active(quest_id: String, owner: String) -> bool:
	var progress: Dictionary = _get_progress(owner)
	return progress.has(quest_id) and not progress[quest_id].get("completed", false)

func start_quest(quest_id: String, owner: String) -> void:
	var progress: Dictionary = _get_progress(owner)
	if progress.has(quest_id):
		return
	progress[quest_id] = {"current_step": 0, "completed": false}
	Logger.info("QuestSystem", "Quest %s started for %s" % [quest_id, owner])

func check_all_quests(owner: String) -> Array:
	var completed_steps: Array = []
	var quest_ids: Array = _QUESTS.keys()
	for q_id in quest_ids:
		if not is_quest_active(q_id, owner):
			if not is_quest_completed(q_id, owner):
				start_quest(q_id, owner)
			continue
		var step: int = get_current_step(q_id, owner)
		var quest: Dictionary = _QUESTS[q_id]
		var steps: Array = quest.get("steps", [])
		if step >= steps.size():
			continue
		var step_data: Dictionary = steps[step]
		if _check_step_condition(step_data, owner):
			_complete_step(q_id, step, owner, step_data)
			completed_steps.append({"quest": q_id, "step": step})
	return completed_steps

func _check_step_condition(step_data: Dictionary, owner: String) -> bool:
	var type: String = step_data.get("type", "")
	var count: int = step_data.get("count", 1)
	var is_player: bool = (owner == "player")
	
	match type:
		"own_territories":
			var t_count: int = GameManager.get_player_territory_count() if is_player else GameManager.get_enemy_territory_count()
			return t_count >= count
		"reach_respect":
			var respect: int = GameManager.get_respect() if is_player else GameManager.get_enemy_respect()
			return respect >= count
		"own_terrain_count":
			var terrain: String = step_data.get("terrain", "")
			var owned: int = 0
			for t_id in GameManager._territory_owners:
				if GameManager._territory_owners[t_id] == owner:
					var t: Dictionary = CardDatabase.get_territory(t_id)
					if t.get("terrain", "") == terrain:
						owned += 1
			return owned >= count
		"reach_resource":
			var resource: String = step_data.get("resource", "bottles")
			var res: Dictionary = GameManager.get_resources() if is_player else GameManager.get_enemy_resources()
			return res.get(resource, 0) >= count
		"build_building":
			if BuildingSystem == null:
				return false
			var building_id: String = step_data.get("building_id", "")
			var buildings: Dictionary = BuildingSystem.get_all_buildings(owner)
			for t_id in buildings:
				if buildings[t_id].has(building_id):
					return true
			return false
		"deploy_unit":
			return true
		_:
			return false
	return false

func _complete_step(quest_id: String, step: int, owner: String, step_data: Dictionary) -> void:
	var progress: Dictionary = _get_progress(owner)
	progress[quest_id]["current_step"] = step + 1
	
	var reward: Dictionary = step_data.get("reward", {})
	_apply_reward(reward, owner)
	
	quest_step_completed.emit(quest_id, step)
	Logger.info("QuestSystem", "Quest %s step %d completed for %s" % [quest_id, step, owner])
	
	var quest: Dictionary = _QUESTS[quest_id]
	var steps: Array = quest.get("steps", [])
	if step + 1 >= steps.size():
		_complete_quest(quest_id, owner)

func _complete_quest(quest_id: String, owner: String) -> void:
	var progress: Dictionary = _get_progress(owner)
	progress[quest_id]["completed"] = true
	
	var quest: Dictionary = _QUESTS[quest_id]
	var final_reward: Dictionary = quest.get("final_reward", {})
	_apply_reward(final_reward, owner)
	
	quest_completed.emit(quest_id, final_reward)
	Logger.info("QuestSystem", "Quest %s COMPLETED for %s! Reward: %s" % [quest_id, owner, str(final_reward)])

func _apply_reward(reward: Dictionary, owner: String) -> void:
	var is_player: bool = (owner == "player")
	if reward.has("respect"):
		if is_player:
			GameManager.change_respect(reward["respect"])
		else:
			GameManager.change_enemy_respect(reward["respect"])
	if reward.has("resource"):
		var resources: Dictionary = reward["resource"]
		for res in resources:
			if is_player:
				GameManager.change_resource(res, resources[res])
			else:
				GameManager.change_enemy_resource(res, resources[res])
	if reward.has("happiness"):
		if HappinessSystem != null:
			HappinessSystem.change_happiness(reward["happiness"], owner)
	if reward.has("achievement"):
		var ach_id: String = reward["achievement"]
		if is_player and AchievementSystem != null:
			AchievementSystem.unlock(ach_id)

func _get_progress(owner: String) -> Dictionary:
	return _player_quest_progress if owner == "player" else _enemy_quest_progress

func get_active_quests(owner: String) -> Array:
	var progress: Dictionary = _get_progress(owner)
	var active: Array = []
	for q_id in progress:
		if not progress[q_id].get("completed", false):
			active.append(q_id)
	return active

func get_completed_quests(owner: String) -> Array:
	var progress: Dictionary = _get_progress(owner)
	var completed: Array = []
	for q_id in progress:
		if progress[q_id].get("completed", false):
			completed.append(q_id)
	return completed

func clear() -> void:
	_player_quest_progress.clear()
	_enemy_quest_progress.clear()

func serialize() -> Dictionary:
	return {
		"player_quests": _player_quest_progress.duplicate(true),
		"enemy_quests": _enemy_quest_progress.duplicate(true)
	}

func deserialize(data: Dictionary) -> void:
	_player_quest_progress = data.get("player_quests", {})
	_enemy_quest_progress = data.get("enemy_quests", {})
