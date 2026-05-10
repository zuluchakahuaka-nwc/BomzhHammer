extends RefCounted

func find_path(from_id: String, to_id: String, owner: String = "") -> Array:
	if from_id == to_id:
		return [from_id]
	var visited: Dictionary = {}
	var queue: Array = [[from_id]]
	visited[from_id] = true
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var current: String = path[-1]
		var neighbors: Array = CardDatabase.get_adjacent_territories(current)
		for neighbor in neighbors:
			if visited.has(neighbor):
				continue
			var new_path: Array = path.duplicate()
			new_path.append(neighbor)
			if neighbor == to_id:
				return new_path
			visited[neighbor] = true
			queue.append(new_path)
	return []

func calculate_movement_cost(path: Array) -> float:
	var total: float = 0.0
	for i in range(1, path.size()):
		var t: Dictionary = CardDatabase.get_territory(path[i])
		total += t.get("movement_cost", 1.0)
	return total

func get_reachable_territories(from_id: String, max_cost: float, owner: String = "") -> Array:
	var reachable: Array = []
	var visited: Dictionary = {from_id: 0.0}
	var queue: Array = [{id = from_id, cost = 0.0}]
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var neighbors: Array = CardDatabase.get_adjacent_territories(current.id)
		for neighbor in neighbors:
			var t: Dictionary = CardDatabase.get_territory(neighbor)
			var move_cost: float = t.get("movement_cost", 1.0)
			var total_cost: float = current.cost + move_cost
			if total_cost > max_cost:
				continue
			if not visited.has(neighbor) or visited[neighbor] > total_cost:
				visited[neighbor] = total_cost
				queue.append({id = neighbor, cost = total_cost})
				if not reachable.has(neighbor):
					reachable.append(neighbor)
	return reachable
