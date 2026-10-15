extends RefCounted
## The 6 x 8 battle board (6 columns, 8 rows; portrait-first, the landscape view just rotates it).
## Terrain has at most two effects: "cover" (less damage taken) and "hazard" (damage at end of turn).

const W := 6
const H := 8
const TERRAIN := ["cover", "hazard"]
const HAZARD_ENTER_COST := 2   # entering a hazard cell costs 2 movement points, every other cell 1

var terrain: Dictionary = {}   # Vector2i -> "cover" | "hazard"


static func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < W and p.y < H


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## All cells in a fixed order (row by row), used wherever the order of candidates matters.
static func all_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in H:
		for x in W:
			out.append(Vector2i(x, y))
	return out


func set_terrain(p: Vector2i, kind: String) -> bool:
	if not in_bounds(p) or not TERRAIN.has(kind):
		return false
	terrain[p] = kind
	return true


func terrain_at(p: Vector2i) -> String:
	return str(terrain.get(p, ""))


## Orthogonal neighbours in a fixed order (up, left, right, down) so searches are deterministic.
static func neighbors(p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
		var q: Vector2i = p + d
		if in_bounds(q):
			out.append(q)
	return out


func enter_cost(p: Vector2i) -> int:
	return HAZARD_ENTER_COST if terrain_at(p) == "hazard" else 1


## Cells reachable from `start` with `mp` movement points: {cell: cost}. `occupied` is a Dictionary keyed by
## Vector2i of cells that cannot be entered (the mover's own cell should not be in it). Includes `start` at cost 0.
func reachable(start: Vector2i, mp: int, occupied: Dictionary) -> Dictionary:
	var best := {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		# Take the cheapest cell; ties by row then column, so the result never depends on hash order.
		var idx := 0
		for i in frontier.size():
			var a: Vector2i = frontier[i]
			var b: Vector2i = frontier[idx]
			if best[a] < best[b] or (best[a] == best[b] and (a.y < b.y or (a.y == b.y and a.x < b.x))):
				idx = i
		var cur: Vector2i = frontier[idx]
		frontier.remove_at(idx)
		for n in neighbors(cur):
			if occupied.has(n):
				continue
			var cost: int = best[cur] + enter_cost(n)
			if cost > mp:
				continue
			if not best.has(n) or cost < best[n]:
				best[n] = cost
				if not frontier.has(n):
					frontier.append(n)
	return best


func to_dict() -> Dictionary:
	var cells: Array = []
	for p in all_cells():
		if terrain.has(p):
			cells.append([p.x, p.y, terrain[p]])
	return {"terrain": cells}
