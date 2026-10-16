extends RefCounted
## The event engine (M16). Areas hold fixed events (inside a time window) and random events (weighted pools).
## Pure rules: callers pass state and content; nothing here touches scenes or files.
##
## Area:  {id, region, name_key, desc_key, open_default?, requires?, seasons?:[0..3], cost?:int, wander:[{text_key, rewards?}]}
## Event: {id, area, kind:"fixed"|"random", window?:{from,to}, scheduled_only?, requires?, priority?, weight?, cooldown?,
##         once?, scene:{dialogue}, on_miss?:[effect]}
## Requires: week_min, week_max, season:[..], flags_all, flags_none, done, not_done, lead, path, party_any, plus the
##           exploration gates (attr_min, item, bond_min, flag, flag_not, clue_min).
## World effects (used by dialogues and on_miss): lead, schedule {id,min,max}, unlock_area, lock_area.

const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")

const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const WORLD_EFFECTS := ["lead", "schedule", "unlock_area", "lock_area", "arc_stage", "arc_outcome", "arc_bond"]


static func requires_reasons(state: RefCounted, req: Dictionary, content: Object) -> Array:
	var out: Array = ExplorationSystem.gate_reasons(state, req, content)
	var week: int = state.calendar.week
	if req.has("week_min") and week < int(req.week_min):
		out.append({"key": "world.gate.week", "params": {"need": int(req.week_min)}})
	if req.has("week_max") and week > int(req.week_max):
		out.append({"key": "world.gate.too_late", "params": {}})
	if req.has("season") and not _has_int(req.season, state.calendar.season()):
		out.append({"key": "world.gate.season", "params": {}})
	for f in req.get("flags_all", []):
		if not state.relationships.has_flag(str(f)):
			out.append({"key": "explore.gate.flag", "params": {}})
	for f in req.get("flags_none", []):
		if state.relationships.has_flag(str(f)):
			out.append({"key": "explore.gate.flag_not", "params": {}})
	for e in req.get("done", []):
		if not state.world.done.has(str(e)):
			out.append({"key": "world.gate.event", "params": {}})
	for e in req.get("not_done", []):
		if state.world.done.has(str(e)):
			out.append({"key": "world.gate.event_done", "params": {}})
	for l in req.get("lead", []):
		if not state.world.has_lead(str(l)):
			out.append({"key": "world.gate.lead", "params": {}})
	if req.has("path") and state.player.path_id != str(req.path):
		out.append({"key": "world.gate.path", "params": {}})
	if req.get("party_any", false) and PartySystem.active(state) == "":
		out.append({"key": "dialogue.gate.no_party", "params": {}})
	return out


## JSON numbers load as floats; compare as ints.
static func _has_int(arr: Array, v: int) -> bool:
	for x in arr:
		if int(x) == v:
			return true
	return false


# --- Areas --------------------------------------------------------------------------------------

## {state: "open"|"locked"|"closed", reasons, due: number of fixed events playable now, cost}.
static func area_status(state: RefCounted, content: Object, area_id: String) -> Dictionary:
	var a: Dictionary = content.area(area_id)
	if a.is_empty():
		return {"state": "closed", "reasons": [{"key": "world.area.unknown", "params": {}}], "due": 0, "cost": 1}
	var cost := int(a.get("cost", 1))
	if state.world.areas_closed.has(area_id):
		return {"state": "closed", "reasons": [{"key": "world.area.closed", "params": {}}], "due": 0, "cost": cost}
	var reasons: Array = []
	if not (bool(a.get("open_default", false)) or state.world.areas_open.has(area_id)):
		reasons.append({"key": "world.area.locked", "params": {}})
	if a.has("seasons") and not _has_int(a.seasons, state.calendar.season()):
		reasons.append({"key": "world.area.season", "params": {}})
	reasons.append_array(requires_reasons(state, a.get("requires", {}), content))
	if state.calendar.finished:
		reasons.append({"key": "activity.blocked.finished", "params": {}})
	if not reasons.is_empty():
		return {"state": "locked", "reasons": reasons, "due": 0, "cost": cost}
	return {"state": "open", "reasons": [], "due": fixed_due(state, content, area_id).size(), "cost": cost}


static func area_ids(content: Object) -> Array:
	return content.areas.map(func(a: Dictionary) -> String: return str(a.id))


# --- Events -------------------------------------------------------------------------------------

## The window an event can happen in right now: the follow-up window if one was scheduled, else its own.
static func window_of(state: RefCounted, ev: Dictionary) -> Dictionary:
	if state.world.scheduled.has(str(ev.id)):
		return state.world.scheduled[str(ev.id)]
	if ev.has("window"):
		return {"from": int(ev.window.from), "to": int(ev.window.to)}
	return {}


static func _playable(state: RefCounted, content: Object, ev: Dictionary) -> bool:
	if state.world.done.has(str(ev.id)) and bool(ev.get("once", ev.kind == "fixed")):
		return false
	if state.world.missed.has(str(ev.id)):
		return false
	if state.world.cooldown.get(str(ev.id), 0) > state.calendar.week:
		return false
	return requires_reasons(state, ev.get("requires", {}), content).is_empty()


## Fixed events playable in this area now, best first (higher priority, then the nearest end of window).
static func fixed_due(state: RefCounted, content: Object, area_id: String) -> Array:
	var out: Array = []
	for ev in content.events:
		if str(ev.area) != area_id or str(ev.kind) != "fixed":
			continue
		var w := window_of(state, ev)
		if w.is_empty() or state.calendar.week < int(w.from) or state.calendar.week > int(w.to):
			continue
		if _playable(state, content, ev):
			out.append(ev)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("priority", 0)) != int(b.get("priority", 0)):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
		return int(window_of(state, a).to) < int(window_of(state, b).to))
	return out


static func random_pool(state: RefCounted, content: Object, area_id: String) -> Array:
	var out: Array = []
	for ev in content.events:
		if str(ev.area) == area_id and str(ev.kind) == "random" and _playable(state, content, ev):
			out.append(ev)
	return out


## Deterministic from the run seed, so reloading a save and visiting again gives the same event.
static func rng_for(state: RefCounted, area_id: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = ("%d|%d|%d|%s|%d" % [state.run_seed, state.calendar.week, state.calendar.slot, area_id, int(state.world.visits.get(area_id, 0))]).hash()
	return r


## Chooses what happens when the player goes to an area: a due fixed event, else a weighted random one, else a wander.
## Returns {ok, reasons, event (Dictionary or {}), wander (Dictionary or {}), cost}. Does not spend time or change state.
static func pick(state: RefCounted, content: Object, area_id: String) -> Dictionary:
	var st := area_status(state, content, area_id)
	if st.state != "open":
		return {"ok": false, "reasons": st.reasons, "event": {}, "wander": {}, "cost": st.cost}
	var due := fixed_due(state, content, area_id)
	if not due.is_empty():
		return {"ok": true, "reasons": [], "event": due[0], "wander": {}, "cost": st.cost}
	var pool := random_pool(state, content, area_id)
	var rng := rng_for(state, area_id)
	var total := 0
	for ev in pool:
		total += maxi(1, int(ev.get("weight", 1)))
	# A random event does not fire every visit: the chance grows with the pool's total weight (cap 85%).
	var chance := mini(85, 25 + total * 8)
	if not pool.is_empty() and rng.randi_range(1, 100) <= chance:
		var roll := rng.randi_range(1, total)
		for ev in pool:
			roll -= maxi(1, int(ev.get("weight", 1)))
			if roll <= 0:
				return {"ok": true, "reasons": [], "event": ev, "wander": {}, "cost": st.cost}
	var a: Dictionary = content.area(area_id)
	var wanders: Array = a.get("wander", [])
	var w: Dictionary = wanders[rng.randi_range(0, wanders.size() - 1)] if not wanders.is_empty() else {}
	return {"ok": true, "reasons": [], "event": {}, "wander": w, "cost": st.cost}


## Marks the event finished: done week, cooldown for repeatable ones, follow-up window cleared, visit counted.
static func complete_event(state: RefCounted, content: Object, event_id: String) -> void:
	var ev: Dictionary = content.event(event_id)
	if ev.is_empty():
		return
	state.world.done[event_id] = state.calendar.week
	state.world.scheduled.erase(event_id)
	if int(ev.get("cooldown", 0)) > 0:
		state.world.cooldown[event_id] = state.calendar.week + int(ev.cooldown)
	var area_id := str(ev.area)
	state.world.visits[area_id] = int(state.world.visits.get(area_id, 0)) + 1


static func note_visit(state: RefCounted, area_id: String) -> void:
	state.world.visits[area_id] = int(state.world.visits.get(area_id, 0)) + 1


## Fixed events whose window has passed unplayed become missed; their on_miss effects run (story changes, never dead ends).
## Returns the ids newly missed.
static func sweep_missed(state: RefCounted, content: Object) -> Array:
	var out: Array = []
	for ev in content.events:
		var id := str(ev.id)
		if str(ev.kind) != "fixed" or state.world.done.has(id) or state.world.missed.has(id):
			continue
		var w := window_of(state, ev)
		if w.is_empty() or state.calendar.week <= int(w.to):
			continue
		state.world.missed.append(id)
		state.world.scheduled.erase(id)
		for e in ev.get("on_miss", []):
			if str(e.get("type", "")) == "flag":
				state.relationships.set_flag(str(e.id))
			else:
				apply_effect(state, e, content)
		out.append(id)
	return out


## Applies a world effect. Returns true if it was one (so callers can fall through to their own effects).
static func apply_effect(state: RefCounted, e: Dictionary, content: Object) -> bool:
	var id := str(e.get("id", ""))
	match str(e.get("type", "")):
		"lead":
			state.world.add_lead(id)
		"schedule":
			if not state.world.done.has(id) and not state.world.missed.has(id):
				var wk: int = state.calendar.week
				state.world.scheduled[id] = {"from": wk + int(e.get("min", 1)), "to": wk + int(e.get("max", e.get("min", 1)))}
		"unlock_area":
			state.world.areas_closed.erase(id)
			if not state.world.areas_open.has(id):
				state.world.areas_open.append(id)
		"lock_area":
			if not state.world.areas_closed.has(id):
				state.world.areas_closed.append(id)
		"arc_stage":
			ArcRules.set_stage(state, id, int(e.get("amount", 1)))
		"arc_outcome":
			ArcRules.set_outcome(state, id, str(e.get("value", "")))
		"arc_bond":
			ArcRules.set_bond(state, id, str(e.get("value", "")))
		_:
			return false
	return true


## Every flag some requirement reads, every flag something sets: used by the content validator.
static func flag_report(content: Object) -> Dictionary:
	var reads := {}
	var sets := {}
	var read_in := func(req: Dictionary) -> void:
		for f in req.get("flags_all", []):
			reads[str(f)] = true
		for f in req.get("flags_none", []):
			reads[str(f)] = true
		for k in ["flag", "flag_not"]:
			if req.has(k):
				reads[str(req[k])] = true
	for a in content.areas:
		read_in.call(a.get("requires", {}))
	for ev in content.events:
		read_in.call(ev.get("requires", {}))
		for e in ev.get("on_miss", []):
			if str(e.get("type", "")) == "flag":
				sets[str(e.id)] = true
	for d in content.dialogues:
		for en in d.get("entry", []):
			read_in.call(en.get("if", {}))
		for n in d.get("nodes", []):
			for e in n.get("on_enter", []):
				if str(e.get("type", "")) == "flag":
					sets[str(e.id)] = true
			for c in n.get("choices", []):
				read_in.call(c.get("gate", {}))
				for e in c.get("effects", []):
					if str(e.get("type", "")) == "flag":
						sets[str(e.id)] = true
	for sc in content.scenarios:
		for k in ["on_victory", "on_defeat"]:
			for f in sc.get(k, {}).get("flags", []):
				sets[str(f)] = true
	for r in content.routes:
		_collect_route_flags(r, reads, sets)
	for en in content.endings:
		var req: Dictionary = en.get("requires", {})
		for f in req.get("flags_all", []):
			reads[str(f)] = true
		for f in req.get("flags_none", []):
			reads[str(f)] = true
	return {"reads": reads.keys(), "sets": sets.keys(), "unset": reads.keys().filter(func(f: Variant) -> bool: return not sets.has(f))}


static func _collect_route_flags(node: Variant, reads: Dictionary, sets: Dictionary) -> void:
	if node is Dictionary:
		if node.get("type", "") == "flag" and node.has("id"):
			sets[str(node.id)] = true
		for k in node:
			if k == "flag" or k == "flag_not":
				reads[str(node[k])] = true
			if k == "flags" and node[k] is Array:
				for f in node[k]:
					sets[str(f)] = true
			_collect_route_flags(node[k], reads, sets)
	elif node is Array:
		for e in node:
			_collect_route_flags(e, reads, sets)
