extends Node
## Loads game content (activities, paths, techniques, day hooks) from JSON and validates it.
## Content is data, never code: designers can change numbers and text without touching scripts.

const PlayerState = preload("res://scripts/domain/player_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")
const CalendarState = preload("res://scripts/domain/calendar_state.gd")

const DIR := "res://content/"
const NPC_IDS := ["shen_qinghe", "lu_chenzhou", "bai_yan"]  # replaced by companion data in M7
const REWARD_TYPES := ["attr", "resource", "item", "relationship", "stamina", "path_progress", "buff"]
const COST_KEYS := ["stamina", "coins", "food", "herbs", "ore", "medicine"]

var activities: Array = []
var paths: Array = []
var techniques: Array = []
var day_hooks: Array = []
var companions: Array = []
var routes: Array = []
var combat_techniques: Array = []
var combat_statuses: Array = []
var combat_items: Array = []
var combat_units: Array = []
var scenarios: Array = []
var dialogues: Array = []
var endings: Array = []
var areas: Array = []
var events: Array = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	activities = _load_list("activities/activities.json", "activities")
	paths = _load_list("cultivation/paths.json", "paths")
	techniques = _load_list("cultivation/techniques.json", "techniques")
	day_hooks = _load_list("events/day_hooks.json", "hooks")
	companions = _load_list("companions/companions.json", "companions")
	routes = _load_list("exploration/routes.json", "routes")
	combat_techniques = _load_list("combat/combat_techniques.json", "techniques")
	combat_statuses = _load_list("combat/combat_techniques.json", "statuses")
	combat_items = _load_list("combat/combat_techniques.json", "items")
	combat_units = _load_list("combat/units.json", "units")
	scenarios = _load_list("combat/scenarios.json", "scenarios")
	dialogues = _load_list("story/dialogues.json", "dialogues")
	endings = _load_list("story/endings.json", "endings")
	areas = _load_list("world/areas.json", "areas")
	events = _load_list("world/events.json", "events")
	dialogues.append_array(_load_list("world/event_dialogues.json", "dialogues"))


func _load_list(rel: String, key: String) -> Array:
	var path := DIR + rel
	if not FileAccess.file_exists(path):
		push_error("Content: missing %s" % path)
		return []
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK or not (j.data is Dictionary):
		push_error("Content: cannot parse %s" % path)
		return []
	var arr: Variant = j.data.get(key, [])
	return arr if arr is Array else []


## Scenario for a battle id used by the story (falls back to a scenario with the same id).
func scenario_for_battle(battle_id: String) -> Dictionary:
	for sc in scenarios:
		if str(sc.get("battle_id", "")) == battle_id:
			return sc
	return scenario(battle_id)


func dialogue(id: String) -> Dictionary:
	return _find(dialogues, id)


func ending(id: String) -> Dictionary:
	return _find(endings, id)


func area(id: String) -> Dictionary:
	return _find(areas, id)


func event(id: String) -> Dictionary:
	return _find(events, id)


func combat_tech(id: String) -> Dictionary:
	return _find(combat_techniques, id)


func combat_status(id: String) -> Dictionary:
	return _find(combat_statuses, id)


func combat_item(id: String) -> Dictionary:
	return _find(combat_items, id)


func combat_unit(id: String) -> Dictionary:
	return _find(combat_units, id)


func scenario(id: String) -> Dictionary:
	return _find(scenarios, id)


func activity(id: String) -> Dictionary:
	return _find(activities, id)


func path(id: String) -> Dictionary:
	return _find(paths, id)


func route(id: String) -> Dictionary:
	return _find(routes, id)


func companion(id: String) -> Dictionary:
	return _find(companions, id)


func companion_ids() -> Array:
	return companions.map(func(c: Dictionary) -> String: return str(c.id))


func technique(id: String) -> Dictionary:
	return _find(techniques, id)


func techniques_for_path(path_id: String) -> Array:
	return techniques.filter(func(t: Dictionary) -> bool: return t.path == path_id)


func _find(list: Array, id: String) -> Dictionary:
	for e in list:
		if e.get("id", "") == id:
			return e
	return {}


## Returns human-readable problems; an empty array means the content is consistent.
## `has_key` is a Callable(key) -> bool that says whether a translation key exists.
func validate(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var seen := {}
	for a in activities:
		var id := str(a.get("id", ""))
		if id == "" or seen.has("a:" + id):
			errs.append("activity: missing or duplicate id '%s'" % id)
		seen["a:" + id] = true
		for k in ["name_key", "desc_key"]:
			if not has_key.call(str(a.get(k, ""))):
				errs.append("activity %s: translation key missing for %s" % [id, k])
		var min_week := int(a.get("min_week", 1))
		if min_week < 1 or min_week > CalendarState.WEEKS:
			errs.append("activity %s: min_week %d out of range" % [id, min_week])
		for ck in a.get("cost", {}):
			if not COST_KEYS.has(ck) or int(a.cost[ck]) < 0:
				errs.append("activity %s: bad cost '%s'" % [id, ck])
		if a.has("check"):
			if not PlayerState.ATTRS.has(str(a.check.get("attr", ""))) or int(a.check.get("target", 0)) < 1:
				errs.append("activity %s: bad check" % id)
		errs.append_array(_validate_options(id, a, has_key))
		var rewards: Array = a.get("rewards", [])
		if rewards.is_empty():
			errs.append("activity %s: no rewards" % id)
		for r in rewards:
			errs.append_array(_validate_reward(id, r, has_key))

	for p in paths:
		var pid := str(p.get("id", ""))
		for k in ["name_key", "desc_key"]:
			if not has_key.call(str(p.get(k, ""))):
				errs.append("path %s: translation key missing for %s" % [pid, k])
		for attr in p.get("affinity", []):
			if not PlayerState.ATTRS.has(str(attr)):
				errs.append("path %s: unknown affinity attribute '%s'" % [pid, attr])
	for t in techniques:
		var tid := str(t.get("id", ""))
		if path(str(t.get("path", ""))).is_empty():
			errs.append("technique %s: unknown path" % tid)
		if not has_key.call(str(t.get("name_key", ""))):
			errs.append("technique %s: translation key missing" % tid)
		var unlock: Dictionary = t.get("unlock", {})
		if int(unlock.get("path_progress_min", 0)) < 1:
			errs.append("technique %s: needs path_progress_min >= 1" % tid)
		for attr2 in unlock.get("attr_min", {}):
			if not PlayerState.ATTRS.has(str(attr2)):
				errs.append("technique %s: unknown attribute '%s'" % [tid, attr2])
	errs.append_array(_validate_companions(has_key))
	errs.append_array(_validate_routes(has_key))
	errs.append_array(_validate_combat(has_key))
	for h in day_hooks:
		var hid := str(h.get("id", ""))
		var hw := int(h.get("week", 0))
		if hw < 1 or hw > CalendarState.WEEKS:
			errs.append("hook %s: week out of range" % hid)
		if str(h.get("trigger", "")) != "week_start":
			errs.append("hook %s: unsupported trigger" % hid)
		if str(h.get("payload", {}).get("type", "")) == "":
			errs.append("hook %s: payload needs a type" % hid)
		if h.has("dialogue"):
			if dialogue(str(h.dialogue)).is_empty():
				errs.append("hook %s: unknown dialogue %s" % [hid, str(h.dialogue)])
		else:
			for k in ["title_key", "body_key"]:
				if not has_key.call(str(h.get(k, ""))):
					errs.append("hook %s: translation key missing for %s" % [hid, k])
	errs.append_array(_validate_story(has_key))
	errs.append_array(_validate_world(has_key))
	return errs


const NODE_TYPES := ["", "end"]
const EFFECT_EXTRA := ["clue", "flag", "battle"]


## Route graphs: every node reachable, every node able to reach an end, every choice target present,
## at least one always-open choice per node, and valid text keys, gates, checks and effects.
const DIALOGUE_EFFECTS := ["flag", "set_path", "bond", "resource", "attr", "stamina", "battle", "queue", "lead", "schedule", "unlock_area", "lock_area"]


## Dialogues: unique ids, every node reachable, every next/choice target present, text keys, effects, gates.
## Endings: unique ids, text keys, unique conditions, and the last one is the requirement-free fallback.
func _validate_story(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var dids := {}
	for d in dialogues:
		dids[str(d.get("id", ""))] = true
	if dids.size() != dialogues.size():
		errs.append("dialogue: duplicate or missing ids")
	for d in dialogues:
		var did := str(d.get("id", ""))
		var ids := {}
		for n in d.get("nodes", []):
			if ids.has(str(n.get("id", ""))):
				errs.append("dialogue %s: duplicate node %s" % [did, str(n.get("id", ""))])
			ids[str(n.get("id", ""))] = true
		var reach := {}
		for e in d.get("entry", []):
			if not ids.has(str(e.get("node", ""))):
				errs.append("dialogue %s: entry points to a missing node" % did)
			reach[str(e.get("node", ""))] = true
		if d.get("entry", []).is_empty() or not (d.entry[-1].get("if", {}) as Dictionary).is_empty():
			errs.append("dialogue %s: the last entry must have no condition" % did)
		var changed := true
		while changed:
			changed = false
			for n in d.get("nodes", []):
				if not reach.has(str(n.id)):
					continue
				var targets: Array = []
				if str(n.get("next", "")) != "":
					targets.append(str(n.next))
				for c in n.get("choices", []):
					if str(c.get("next", "")) != "":
						targets.append(str(c.next))
				for t in targets:
					if not reach.has(t):
						reach[t] = true
						changed = true
		for n in d.get("nodes", []):
			var label := "dialogue %s node %s" % [did, str(n.id)]
			if not reach.has(str(n.id)):
				errs.append("%s: unreachable" % label)
			if not has_key.call(str(n.get("text_key", ""))):
				errs.append("%s: text key missing" % label)
			if n.has("speaker_key") and not has_key.call(str(n.speaker_key)):
				errs.append("%s: speaker key missing" % label)
			if n.has("choices") and n.has("next"):
				errs.append("%s: has both choices and next" % label)
			if str(n.get("next", "")) != "" and not ids.has(str(n.next)):
				errs.append("%s: next points to a missing node" % label)
			var open_choice: bool = (n.get("choices", []) as Array).is_empty()
			for c in n.get("choices", []):
				if not has_key.call(str(c.get("label_key", ""))):
					errs.append("%s choice %s: label key missing" % [label, str(c.get("id", ""))])
				if str(c.get("next", "")) != "" and not ids.has(str(c.next)):
					errs.append("%s choice %s: next points to a missing node" % [label, str(c.get("id", ""))])
				if (c.get("gate", {}) as Dictionary).is_empty():
					open_choice = true
				for e in c.get("effects", []):
					errs.append_array(_validate_dialogue_effect(label, e))
			if not open_choice:
				errs.append("%s: needs a choice that is always open" % label)
			for e in n.get("on_enter", []):
				errs.append_array(_validate_dialogue_effect(label, e))
	var eids := {}
	var seen_req := {}
	for i in endings.size():
		var e: Dictionary = endings[i]
		var id := str(e.get("id", ""))
		if id == "" or eids.has(id):
			errs.append("ending: missing or duplicate id '%s'" % id)
		eids[id] = true
		for k in ["title_key", "body_key"]:
			if not has_key.call(str(e.get(k, ""))):
				errs.append("ending %s: translation key missing for %s" % [id, k])
		var req_text := JSON.stringify(e.get("requires", {}), "", true)
		if seen_req.has(req_text):
			errs.append("ending %s: same condition as %s" % [id, seen_req[req_text]])
		seen_req[req_text] = id
		if i == endings.size() - 1 and not (e.get("requires", {}) as Dictionary).is_empty():
			errs.append("ending %s: the last ending must be the fallback (no conditions)" % id)
		if i < endings.size() - 1 and (e.get("requires", {}) as Dictionary).is_empty():
			errs.append("ending %s: only the last ending may have no conditions" % id)
	if endings.size() < 3:
		errs.append("endings: at least three are required")
	for k in ["ending.faction.pavilion", "ending.faction.couriers", "ending.faction.scribes", "ending.faction.neutral"]:
		if not has_key.call(k):
			errs.append("missing translation key %s" % k)
	return errs


func _validate_dialogue_effect(label: String, e: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	var t := str(e.get("type", ""))
	var id := str(e.get("id", ""))
	if not DIALOGUE_EFFECTS.has(t):
		errs.append("%s: unknown effect '%s'" % [label, t])
	if t == "battle" and scenario_for_battle(str(e.get("id", ""))).is_empty():
		errs.append("%s: battle %s has no scenario" % [label, str(e.get("id", ""))])
	if t == "set_path" and path(str(e.get("id", ""))).is_empty():
		errs.append("%s: unknown path %s" % [label, str(e.get("id", ""))])
	if t == "queue" and dialogue(str(e.get("id", ""))).is_empty():
		errs.append("%s: queued dialogue %s is missing" % [label, str(e.get("id", ""))])
	if t == "bond" and str(e.get("id", "")) != "$active" and companion(str(e.get("id", ""))).is_empty():
		errs.append("%s: bond with unknown companion %s" % [label, str(e.get("id", ""))])
	if t == "schedule" and event(id).is_empty():
		errs.append("%s: schedules unknown event %s" % [label, id])
	if (t == "unlock_area" or t == "lock_area") and area(id).is_empty():
		errs.append("%s: %s unknown area %s" % [label, t, id])
	if t == "lead" and id == "":
		errs.append("%s: lead needs an id" % label)
	if ["bond", "resource", "attr", "stamina"].has(t) and not e.has("amount"):
		errs.append("%s: effect %s needs an amount" % [label, t])
	return errs


func _validate_combat(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var tids := {}
	for t in combat_techniques:
		var id := str(t.get("id", ""))
		if id == "" or tids.has(id):
			errs.append("combat technique: missing or duplicate id '%s'" % id)
		tids[id] = true
		if not has_key.call(str(t.get("name_key", ""))):
			errs.append("combat technique %s: name key missing" % id)
		if not ["attack", "support"].has(str(t.get("kind", ""))):
			errs.append("combat technique %s: bad kind" % id)
		if int(t.get("range", -1)) < 0 or int(t.get("cost", 1)) < 0:
			errs.append("combat technique %s: bad range/cost" % id)
		if t.has("status") and combat_status(str(t.status.get("id", ""))).is_empty():
			errs.append("combat technique %s: unknown status" % id)
	for s in combat_statuses:
		if not has_key.call("combat.status." + str(s.get("id", ""))):
			errs.append("combat status %s: name key missing" % str(s.get("id", "")))
	var uids := {}
	for u in combat_units:
		var id := str(u.get("id", ""))
		uids[id] = true
		if not has_key.call("combat.unit." + id):
			errs.append("combat unit %s: name key missing" % id)
		for k in ["hp", "body", "power", "agility", "spirit"]:
			if int(u.get("stats", {}).get(k, 0)) < 1:
				errs.append("combat unit %s: stat %s must be >= 1" % [id, k])
		for tid in u.get("techniques", []):
			if not tids.has(str(tid)):
				errs.append("combat unit %s: unknown technique %s" % [id, str(tid)])
	if uids.size() > 6:
		errs.append("combat: more than 6 unit types")
	for sc in scenarios:
		var sid := str(sc.get("id", ""))
		for k in ["", ".objective"]:
			if not has_key.call("combat.scenario." + sid + k):
				errs.append("scenario %s: text key missing" % (sid + k))
		var used := {}
		var cells: Array = []
		for c in sc.get("player_cells", []):
			cells.append(c)
		if sc.has("npc"):
			cells.append(sc.npc.get("cell", []))
			if not uids.has(str(sc.npc.get("template", ""))):
				errs.append("scenario %s: unknown npc template" % sid)
		for c in cells:
			var v := Vector2i(int(c[0]), int(c[1]))
			if v.x < 0 or v.y < 0 or v.x >= 6 or v.y >= 8 or used.has(v):
				errs.append("scenario %s: bad or overlapping cell %s" % [sid, str(v)])
			used[v] = true
		for e in sc.get("enemies", []):
			if not uids.has(str(e.get("template", ""))):
				errs.append("scenario %s: unknown enemy %s" % [sid, str(e.get("template", ""))])
			if e.get("cells", []).is_empty():
				errs.append("scenario %s: enemy without candidate cells" % sid)
			for c in e.get("cells", []):
				if int(c[0]) < 0 or int(c[1]) < 0 or int(c[0]) >= 6 or int(c[1]) >= 8:
					errs.append("scenario %s: enemy cell out of bounds" % sid)
				if used.has(Vector2i(int(c[0]), int(c[1]))):
					errs.append("scenario %s: enemy cell overlaps player cell" % sid)
		var obj: Dictionary = sc.get("objective", {})
		if obj.is_empty() or int(sc.get("max_rounds", 0)) < 1:
			errs.append("scenario %s: needs an objective and max_rounds" % sid)
		if obj.has("survive_rounds") and int(obj.survive_rounds) > int(sc.get("max_rounds", 0)):
			errs.append("scenario %s: survive_rounds exceeds max_rounds" % sid)
	return errs


func _validate_routes(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	for r in routes:
		var rid := str(r.get("id", ""))
		for f in ["id", "name_key", "desc_key", "start", "min_week", "cost", "nodes"]:
			if not r.has(f):
				errs.append("route %s: missing field '%s'" % [rid, f])
		if r.has("nodes") == false:
			continue
		for k in ["name_key", "desc_key"]:
			if not has_key.call(str(r.get(k, ""))):
				errs.append("route %s: translation key missing for %s" % [rid, k])
		var ids := {}
		for n in r.nodes:
			var nid := str(n.get("id", ""))
			if nid == "" or ids.has(nid):
				errs.append("route %s: missing or duplicate node id '%s'" % [rid, nid])
			ids[nid] = n
		if not ids.has(str(r.get("start", ""))):
			errs.append("route %s: start node '%s' does not exist" % [rid, r.get("start", "")])
		var edges := {}   # node id -> [target ids]
		for nid2 in ids:
			var n2: Dictionary = ids[nid2]
			var label := "route %s node %s" % [rid, nid2]
			if not NODE_TYPES.has(str(n2.get("type", ""))):
				errs.append("%s: unknown type" % label)
			if not has_key.call(str(n2.get("text_key", ""))):
				errs.append("%s: translation key missing for text" % label)
			for e in n2.get("on_enter", []):
				errs.append_array(_validate_effect(label, e, has_key))
			if n2.has("recruit") and companion(str(n2.recruit)).is_empty():
				errs.append("%s: recruit npc '%s' unknown" % [label, n2.recruit])
			var targets: Array = []
			var choices: Array = n2.get("choices", [])
			if str(n2.get("type", "")) == "end":
				if not choices.is_empty():
					errs.append("%s: an end node cannot have choices" % label)
			else:
				if choices.is_empty():
					errs.append("%s: no choices (dead end)" % label)
				var open_choice := false
				var cids := {}
				for c in choices:
					var cid := str(c.get("id", ""))
					if cid == "" or cids.has(cid):
						errs.append("%s: missing or duplicate choice id '%s'" % [label, cid])
					cids[cid] = true
					if not c.has("gate") and not c.has("cost"):
						open_choice = true
					errs.append_array(_validate_choice(label + " choice " + cid, c, ids, has_key, targets))
				if not choices.is_empty() and not open_choice:
					errs.append("%s: needs at least one choice with no gate and no cost" % label)
			edges[nid2] = targets
		# Reachability from start, and the ability of every reachable node to reach an end.
		var seen := {}
		var queue: Array = [str(r.get("start", ""))]
		while not queue.is_empty():
			var cur: String = queue.pop_back()
			if seen.has(cur) or not ids.has(cur):
				continue
			seen[cur] = true
			queue.append_array(edges.get(cur, []))
		for nid3 in ids:
			if not seen.has(nid3):
				errs.append("route %s: node '%s' is unreachable (orphan)" % [rid, nid3])
		var can_end := {}
		for nid4 in ids:
			if str(ids[nid4].get("type", "")) == "end":
				can_end[nid4] = true
		var changed := true
		while changed:
			changed = false
			for nid5 in ids:
				if can_end.has(nid5):
					continue
				for t in edges.get(nid5, []):
					if can_end.has(t):
						can_end[nid5] = true
						changed = true
						break
		for nid6 in ids:
			if seen.has(nid6) and not can_end.has(nid6):
				errs.append("route %s: node '%s' cannot reach an ending (dead end)" % [rid, nid6])
	return errs


func _validate_choice(label: String, c: Dictionary, ids: Dictionary, has_key: Callable, targets: Array) -> Array[String]:
	var errs: Array[String] = []
	if not has_key.call(str(c.get("label_key", ""))):
		errs.append("%s: translation key missing for label" % label)
	var gate: Dictionary = c.get("gate", {})
	for attr in gate.get("attr_min", {}):
		if not PlayerState.ATTRS.has(str(attr)):
			errs.append("%s: gate attr '%s' unknown" % [label, attr])
	for item in gate.get("item", {}):
		if not has_key.call("item." + str(item)):
			errs.append("%s: gate item '%s' has no translation" % [label, item])
	for npc in gate.get("bond_min", {}):
		if companion(str(npc)).is_empty():
			errs.append("%s: gate npc '%s' unknown" % [label, npc])
	for ck in c.get("cost", {}):
		if not COST_KEYS.has(ck):
			errs.append("%s: bad cost '%s'" % [label, ck])
	for e in c.get("effects", []):
		errs.append_array(_validate_effect(label, e, has_key))
	var next_ids: Array = []
	if c.has("next"):
		next_ids.append(str(c.next))
	if c.has("check"):
		if not PlayerState.ATTRS.has(str(c.check.get("attr", ""))) or int(c.check.get("target", 0)) < 1:
			errs.append("%s: bad check" % label)
		for blk in ["success", "failure"]:
			var b: Dictionary = c.get(blk, {})
			if not b.has("next") and not c.has("next"):
				errs.append("%s: %s has no next node" % [label, blk])
			if b.has("next"):
				next_ids.append(str(b.next))
			if b.has("text_key") and not has_key.call(str(b.text_key)):
				errs.append("%s: translation key missing for %s text" % [label, blk])
			for e2 in b.get("effects", []):
				errs.append_array(_validate_effect(label, e2, has_key))
	elif not c.has("next"):
		errs.append("%s: no next node" % label)
	for nx in next_ids:
		if not ids.has(nx):
			errs.append("%s: next node '%s' does not exist" % [label, nx])
		else:
			targets.append(nx)
	return errs


func _validate_effect(label: String, e: Dictionary, has_key: Callable) -> Array[String]:
	var t := str(e.get("type", ""))
	if EFFECT_EXTRA.has(t):
		if str(e.get("id", "")) == "":
			return ["%s: %s effect needs an id" % [label, t]]
		if t == "clue" and not has_key.call("clue." + str(e.id)):
			return ["%s: clue '%s' has no translation" % [label, e.id]]
		if t == "battle" and not has_key.call("battle." + str(e.id)):
			return ["%s: battle '%s' has no translation" % [label, e.id]]
		return []
	return _validate_reward(label, e, has_key)


const ROLES := ["support", "striker", "control"]
const COMPANION_FIELDS := ["id", "name_key", "bio_key", "portrait", "role", "stats", "preferred_activities", "meet_week",
		"recruit", "depart", "battle_abilities", "relationship_ability"]


func _validate_companions(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var seen := {}
	for c in companions:
		var cid := str(c.get("id", ""))
		for f in COMPANION_FIELDS:
			if not c.has(f):
				errs.append("companion %s: missing field '%s'" % [cid, f])
		if cid == "" or seen.has(cid):
			errs.append("companion: missing or duplicate id '%s'" % cid)
		seen[cid] = true
		if not ROLES.has(str(c.get("role", ""))):
			errs.append("companion %s: unknown role" % cid)
		if str(c.get("portrait", "")) == "":
			errs.append("companion %s: portrait reference empty" % cid)
		for k in ["name_key", "bio_key"]:
			if not has_key.call(str(c.get(k, ""))):
				errs.append("companion %s: translation key missing for %s" % [cid, k])
		if has_key.call("role." + str(c.get("role", ""))) == false:
			errs.append("companion %s: role has no translation" % cid)
		for a in PlayerState.ATTRS:
			if not c.get("stats", {}).has(a):
				errs.append("companion %s: stats missing '%s'" % [cid, a])
		for act in c.get("preferred_activities", []):
			if activity(str(act)).is_empty():
				errs.append("companion %s: unknown preferred activity '%s'" % [cid, act])
		var abilities: Array = c.get("battle_abilities", [])
		if abilities.size() != 2:
			errs.append("companion %s: needs exactly two battle abilities" % cid)
		for ab in abilities + [c.get("relationship_ability", "")]:
			for suffix in ["", ".desc"]:
				if not has_key.call("ability." + str(ab) + suffix):
					errs.append("companion %s: ability '%s' missing translation%s" % [cid, ab, suffix])
		var rec: Dictionary = c.get("recruit", {})
		if int(rec.get("score_min", 0)) < 1 or int(rec.get("week_min", 0)) < 1 or int(rec.get("week_min", 0)) > CalendarState.WEEKS:
			errs.append("companion %s: recruit needs score_min >= 1 and week_min in 1..%d" % [cid, CalendarState.WEEKS])
		for attr in rec.get("attr_min", {}):
			if not PlayerState.ATTRS.has(str(attr)):
				errs.append("companion %s: recruit attr '%s' unknown" % [cid, attr])
		var dep: Dictionary = c.get("depart", {})
		if not dep.has("score_below") and (dep.get("flags", []) as Array).is_empty():
			errs.append("companion %s: depart needs score_below or flags" % cid)
		var md := int(c.get("meet_week", 0))
		if md < 1 or md > CalendarState.WEEKS:
			errs.append("companion %s: meet_week out of range" % cid)
	return errs


func _validate_options(act_id: String, a: Dictionary, has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var opts: Variant = a.get("options", [])
	if not (opts is Array):
		return ["activity %s: options must be a list" % act_id]
	var seen := {}
	for o in opts:
		var oid := str(o.get("id", ""))
		if oid == "" or seen.has(oid):
			errs.append("activity %s: option missing or duplicate id '%s'" % [act_id, oid])
		seen[oid] = true
		for k in ["name_key", "desc_key"]:
			if not has_key.call(str(o.get(k, ""))):
				errs.append("activity %s option %s: translation key missing for %s" % [act_id, oid, k])
		for ck in o.get("cost_extra", {}):
			if not COST_KEYS.has(ck) or int(o.cost_extra[ck]) < 0:
				errs.append("activity %s option %s: bad cost_extra '%s'" % [act_id, oid, ck])
		if (o.has("target_delta") or o.has("fail_stamina")) and not a.has("check"):
			errs.append("activity %s option %s: target_delta/fail_stamina need the activity to have a check" % [act_id, oid])
		if o.has("rewards"):
			if (o.rewards as Array).is_empty():
				errs.append("activity %s option %s: empty rewards" % [act_id, oid])
			for r in o.rewards:
				errs.append_array(_validate_reward(act_id, r, has_key))
	return errs


func _validate_reward(act_id: String, r: Dictionary, has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var type := str(r.get("type", ""))
	var id := str(r.get("id", ""))
	if not REWARD_TYPES.has(type):
		errs.append("activity %s: unknown reward type '%s'" % [act_id, type])
		return errs
	if int(r.get("amount", 0)) == 0:
		errs.append("activity %s: reward '%s' has zero amount" % [act_id, id])
	match type:
		"attr":
			if not PlayerState.ATTRS.has(id):
				errs.append("activity %s: reward attribute '%s' unknown" % [act_id, id])
		"resource":
			if not ResourceState.CURRENCIES.has(id):
				errs.append("activity %s: reward resource '%s' unknown" % [act_id, id])
		"relationship":
			if not NPC_IDS.has(id):
				errs.append("activity %s: reward npc '%s' unknown" % [act_id, id])
		"item":
			if not has_key.call("item." + id):
				errs.append("activity %s: item '%s' has no translation" % [act_id, id])
		"path_progress":
			if id != "current" and path(id).is_empty():
				errs.append("activity %s: reward path '%s' unknown" % [act_id, id])
	return errs


## Areas and events: unique ids, valid regions and windows, scenes that exist, follow-ups that exist, every fixed event
## reachable (own window or scheduled by something), every flag that is read is set somewhere.
const REGIONS := ["jade_valley", "linjiang", "cangwu", "marsh", "yanmen", "penglai"]


func _validate_world(has_key: Callable) -> Array[String]:
	var errs: Array[String] = []
	var aids := {}
	for a in areas:
		var id := str(a.get("id", ""))
		if id == "" or aids.has(id):
			errs.append("area: missing or duplicate id '%s'" % id)
		aids[id] = true
		if not REGIONS.has(str(a.get("region", ""))):
			errs.append("area %s: unknown region" % id)
		for k in ["name_key", "desc_key"]:
			if not has_key.call(str(a.get(k, ""))):
				errs.append("area %s: missing key %s" % [id, k])
		for w in a.get("wander", []):
			if not has_key.call(str(w.get("text_key", ""))):
				errs.append("area %s: wander text key missing" % id)
		if (a.get("wander", []) as Array).is_empty():
			errs.append("area %s: needs at least one wander line" % id)
	var scheduled_by := {}
	for d in dialogues:
		for n in d.get("nodes", []):
			var effs: Array = n.get("on_enter", []).duplicate()
			for c in n.get("choices", []):
				effs.append_array(c.get("effects", []))
			for e in effs:
				if str(e.get("type", "")) == "schedule":
					scheduled_by[str(e.id)] = true
	var eids := {}
	for ev in events:
		var id := str(ev.get("id", ""))
		if id == "" or eids.has(id):
			errs.append("event: missing or duplicate id '%s'" % id)
		eids[id] = true
		if not aids.has(str(ev.get("area", ""))):
			errs.append("event %s: unknown area" % id)
		var kind := str(ev.get("kind", ""))
		if kind != "fixed" and kind != "random":
			errs.append("event %s: kind must be fixed or random" % id)
		if ev.has("window"):
			var f := int(ev.window.get("from", 0))
			var t := int(ev.window.get("to", 0))
			if f < 1 or t > CalendarState.WEEKS or f > t:
				errs.append("event %s: bad window %d..%d" % [id, f, t])
		if kind == "fixed" and not ev.has("window") and not scheduled_by.has(id):
			errs.append("event %s: a fixed event needs a window or something that schedules it" % id)
		if kind == "random" and ev.has("window") and int(ev.window.get("from", 0)) > int(ev.window.get("to", 0)):
			errs.append("event %s: bad window" % id)
		if not has_key.call(str(ev.get("title_key", ""))):
			errs.append("event %s: missing title_key text" % id)
		if dialogue(str(ev.get("scene", {}).get("dialogue", ""))).is_empty():
			errs.append("event %s: scene dialogue missing" % id)
		for e in ev.get("on_miss", []):
			errs.append_array(_validate_dialogue_effect("event %s on_miss" % id, e))
		for e in ev.get("requires", {}).get("done", []) + ev.get("requires", {}).get("not_done", []):
			if not events.any(func(x: Dictionary) -> bool: return str(x.id) == str(e)):
				errs.append("event %s: requires unknown event %s" % [id, str(e)])
	for lead_id in _all_leads():
		for suffix in [".name", ".desc"]:
			if not has_key.call("world.lead." + lead_id + suffix):
				errs.append("lead %s: missing text world.lead.%s%s" % [lead_id, lead_id, suffix])
	var report := preload("res://scripts/domain/world_rules.gd").flag_report(self)
	for f in report.unset:
		errs.append("flag '%s' is read but never set by anything" % str(f))
	return errs


func _all_leads() -> Array:
	var out := {}
	var scan := func(effs: Array) -> void:
		for e in effs:
			if str(e.get("type", "")) == "lead":
				out[str(e.id)] = true
	for d in dialogues:
		for n in d.get("nodes", []):
			scan.call(n.get("on_enter", []))
			for c in n.get("choices", []):
				scan.call(c.get("effects", []))
	for ev in events:
		scan.call(ev.get("on_miss", []))
		for r in ev.get("requires", {}).get("lead", []):
			out[str(r)] = true
	return out.keys()
