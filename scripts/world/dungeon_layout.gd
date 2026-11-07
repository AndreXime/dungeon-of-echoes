extends RefCounted
class_name DungeonLayout

## Grafo de salas da run (grid + kind + portas). Separado do builder físico.


static func build(rng: RandomNumberGenerator, floor_index: int) -> Array[Dictionary]:
	var boss_floor := floor_index % 3 == 0
	var main_count := rng.randi_range(5, 7)
	var occupied: Dictionary = {}
	var order: Array[Vector2i] = []
	var kinds: Dictionary = {}
	var doors: Dictionary = {}

	var pos := Vector2i(0, 0)
	occupied[pos] = true
	order.append(pos)
	kinds[pos] = "hall"
	doors[pos] = {"n": false, "s": false, "e": false, "w": false}

	var dirs := [
		Vector2i(0, -1),
		Vector2i(0, -1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
	]

	while order.size() < main_count:
		var placed := false
		var shuffled := dirs.duplicate()
		for i in shuffled.size():
			var j := rng.randi_range(i, shuffled.size() - 1)
			var tmp: Vector2i = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = tmp
		for d in shuffled:
			var nxt: Vector2i = pos + d
			if occupied.has(nxt):
				continue
			link_doors(doors, pos, nxt, d)
			occupied[nxt] = true
			order.append(nxt)
			pos = nxt
			placed = true
			break
		if not placed:
			break

	for i in order.size():
		var p: Vector2i = order[i]
		if i == 0:
			kinds[p] = "hall"
		elif i == order.size() - 1:
			kinds[p] = "boss" if boss_floor else "end"
		else:
			var roll := rng.randf()
			if roll < 0.22:
				kinds[p] = "bridge"
			elif roll < 0.4:
				kinds[p] = "hazard"
			elif roll < 0.55:
				kinds[p] = "cross"
			else:
				kinds[p] = "hall"

	var branch_budget := 1 + int(rng.randf() > 0.45)
	var mid_candidates: Array[Vector2i] = []
	for i in range(1, maxi(order.size() - 1, 1)):
		mid_candidates.append(order[i])
	for _b in branch_budget:
		if mid_candidates.is_empty():
			break
		var from: Vector2i = mid_candidates[rng.randi_range(0, mid_candidates.size() - 1)]
		var side_dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
		for i in side_dirs.size():
			var j := rng.randi_range(i, side_dirs.size() - 1)
			var tmp2: Vector2i = side_dirs[i]
			side_dirs[i] = side_dirs[j]
			side_dirs[j] = tmp2
		for d in side_dirs:
			var nxt2: Vector2i = from + d
			if occupied.has(nxt2):
				continue
			link_doors(doors, from, nxt2, d)
			occupied[nxt2] = true
			order.append(nxt2)
			kinds[nxt2] = "treasure" if rng.randf() > 0.35 else "cross"
			break

	var result: Array[Dictionary] = []
	for p2 in order:
		result.append({
			"grid": p2,
			"kind": kinds[p2],
			"doors": doors[p2],
		})
	return result


static func link_doors(doors: Dictionary, a: Vector2i, b: Vector2i, delta: Vector2i) -> void:
	if not doors.has(a):
		doors[a] = {"n": false, "s": false, "e": false, "w": false}
	if not doors.has(b):
		doors[b] = {"n": false, "s": false, "e": false, "w": false}
	if delta == Vector2i(0, -1):
		doors[a]["n"] = true
		doors[b]["s"] = true
	elif delta == Vector2i(0, 1):
		doors[a]["s"] = true
		doors[b]["n"] = true
	elif delta == Vector2i(1, 0):
		doors[a]["e"] = true
		doors[b]["w"] = true
	elif delta == Vector2i(-1, 0):
		doors[a]["w"] = true
		doors[b]["e"] = true
