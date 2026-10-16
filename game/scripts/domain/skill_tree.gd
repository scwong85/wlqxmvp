extends RefCounted
## Path skill trees: eight nodes per school, bought with skill points. A node either gives a permanent battle stat
## bonus or teaches a technique. Points come from realms and path progress; nothing is ever lost or locked out
## (only one school's tree is open to the hero, chosen at the start).
## content/cultivation/skill_tree.json: nodes [{id, path, name_key, requires:[ids], cost, realm_min,
## effect:{type:"stat", stat, amount} | {type:"technique", id}}]

const STATS := ["hp", "body", "power", "agility", "spirit", "tp", "resolve"]
const PROGRESS_PER_POINT := 8
const MAX_PROGRESS_POINTS := 8


static func nodes_of(state: RefCounted, content: Object) -> Array:
	return content.skill_nodes.filter(func(n: Dictionary) -> bool: return str(n.path) == state.player.path_id)


static func node(content: Object, id: String) -> Dictionary:
	for n in content.skill_nodes:
		if str(n.id) == id:
			return n
	return {}


static func learned(state: RefCounted, id: String) -> bool:
	return state.cultivation.nodes.has(id)


static func points_total(state: RefCounted) -> int:
	var pp: int = int(state.cultivation.path_progress.get(state.player.path_id, 0)) if state.player.path_id != "" else 0
	return int(state.cultivation.realm) * 2 + mini(pp / PROGRESS_PER_POINT, MAX_PROGRESS_POINTS)


static func points_spent(state: RefCounted, content: Object) -> int:
	var n := 0
	for id in state.cultivation.nodes:
		n += int(node(content, str(id)).get("cost", 0))
	return n


static func points_free(state: RefCounted, content: Object) -> int:
	return maxi(0, points_total(state) - points_spent(state, content))


## {ok, reasons:[{key, params}]}.
static func can_learn(state: RefCounted, id: String, content: Object) -> Dictionary:
	var n := node(content, id)
	var reasons: Array = []
	if n.is_empty() or state.player.path_id == "" or str(n.path) != state.player.path_id:
		return {"ok": false, "reasons": [{"key": "tree.none", "params": {}}]}
	if learned(state, id):
		return {"ok": false, "reasons": [{"key": "tree.learned", "params": {}}]}
	var missing: Array = []
	for r in n.requires:
		if not learned(state, str(r)):
			missing.append(str(r))
	if not missing.is_empty():
		reasons.append({"key": "tree.locked", "params": {"list": missing}})
	if int(state.cultivation.realm) < int(n.realm_min):
		reasons.append({"key": "tree.realm", "params": {"realm": int(n.realm_min)}})
	if points_free(state, content) < int(n.cost):
		reasons.append({"key": "tree.points", "params": {}})
	return {"ok": reasons.is_empty(), "reasons": reasons}


## Learns a node. Technique nodes teach the technique at once. Returns {ok, reasons} or {ok:true, node}.
static func learn(state: RefCounted, id: String, content: Object) -> Dictionary:
	var c := can_learn(state, id, content)
	if not c.ok:
		return c
	var n := node(content, id)
	state.cultivation.nodes.append(id)
	if str(n.effect.type) == "technique":
		state.player.learn(str(n.effect.id))
	return {"ok": true, "reasons": [], "node": n}


## Total stat bonuses of learned nodes: {stat: amount}.
static func stat_bonus(state: RefCounted, content: Object) -> Dictionary:
	var out := {}
	for id in state.cultivation.nodes:
		var n := node(content, str(id))
		if not n.is_empty() and str(n.effect.type) == "stat":
			out[str(n.effect.stat)] = int(out.get(str(n.effect.stat), 0)) + int(n.effect.amount)
	return out
