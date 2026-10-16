extends RefCounted
## Cultivation realms: seven steps. Each breakthrough needs path progress, a total of attributes and (later realms)
## technique levels; it raises the attribute cap, battle hit points and technique points. A breakthrough costs a slot
## and some stamina, and always succeeds when its requirements are met (no game over, just a wait).
## content/cultivation/realms.json: [{id, name_key, desc_key, attr_cap, hp_bonus, tp_bonus, requires:{path_progress_min,
## attr_total_min, tech_levels_min}}]; the first realm has no requirements.

const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")
const DayRules = preload("res://scripts/domain/day_rules.gd")

const BREAKTHROUGH_STAMINA := 8


static func realms(content: Object) -> Array:
	return content.realms


static func current(state: RefCounted, content: Object) -> Dictionary:
	var rs: Array = content.realms
	return rs[clampi(int(state.cultivation.realm), 0, rs.size() - 1)]


static func attr_cap(state: RefCounted, content: Object) -> int:
	return int(current(state, content).attr_cap)


static func is_last(state: RefCounted, content: Object) -> bool:
	return int(state.cultivation.realm) >= content.realms.size() - 1


static func attr_total(state: RefCounted) -> int:
	var n := 0
	for a in state.player.ATTRS:
		n += state.player.get_attr(a)
	return n


static func tech_level_total(state: RefCounted) -> int:
	var n := 0
	for t in state.player.techniques:
		n += TechniqueLevels.level(state, str(t))
	return n


## Requirement lines for the next realm: [{key, have, need, met}] (key is a loc key suffix).
static func requirement_lines(state: RefCounted, content: Object) -> Array:
	if is_last(state, content):
		return []
	var next: Dictionary = content.realms[int(state.cultivation.realm) + 1]
	var req: Dictionary = next.get("requires", {})
	var lines: Array = []
	var pp: int = int(state.cultivation.path_progress.get(state.player.path_id, 0)) if state.player.path_id != "" else 0
	if req.has("path_progress_min"):
		lines.append({"key": "path_progress", "have": pp, "need": int(req.path_progress_min), "met": pp >= int(req.path_progress_min)})
	if req.has("attr_total_min"):
		var t := attr_total(state)
		lines.append({"key": "attr_total", "have": t, "need": int(req.attr_total_min), "met": t >= int(req.attr_total_min)})
	if req.has("tech_levels_min"):
		var tl := tech_level_total(state)
		lines.append({"key": "tech_levels", "have": tl, "need": int(req.tech_levels_min), "met": tl >= int(req.tech_levels_min)})
	if req.has("flag"):
		var done: bool = state.relationships.has_flag(str(req.flag))
		lines.append({"key": str(req.get("flag_key", "hermit")), "have": 1 if done else 0, "need": 1, "met": done})
	return lines


## {ok, reasons:[loc keys], next: realm dict or {}}.
static func can_break(state: RefCounted, content: Object) -> Dictionary:
	if is_last(state, content):
		return {"ok": false, "reasons": ["realm.blocked.last"], "next": {}}
	var reasons: Array = []
	if state.calendar.finished:
		reasons.append("activity.blocked.finished")
	if state.player.path_id == "":
		reasons.append("realm.blocked.no_path")
	if state.player.stamina < BREAKTHROUGH_STAMINA:
		reasons.append("activity.blocked.stamina")
	for l in requirement_lines(state, content):
		if not l.met:
			reasons.append("realm.blocked." + str(l.key))
	return {"ok": reasons.is_empty(), "reasons": reasons, "next": content.realms[int(state.cultivation.realm) + 1]}


## Performs the breakthrough: spends stamina and a slot, raises the realm and the attribute cap.
## Returns {ok, reasons} or {ok:true, realm, realm_id, time}.
static func break_through(state: RefCounted, content: Object) -> Dictionary:
	var c := can_break(state, content)
	if not c.ok:
		return {"ok": false, "reasons": c.reasons}
	state.player.stamina -= BREAKTHROUGH_STAMINA
	state.cultivation.realm = int(state.cultivation.realm) + 1
	state.player.attr_cap = attr_cap(state, content)
	var time: Dictionary = DayRules.end_slot(state)
	return {"ok": true, "reasons": [], "realm": int(state.cultivation.realm), "realm_id": str(c.next.id), "time": time}


## Battle bonuses of the current realm.
static func hp_bonus(state: RefCounted, content: Object) -> int:
	return int(current(state, content).get("hp_bonus", 0))


static func tp_bonus(state: RefCounted, content: Object) -> int:
	return int(current(state, content).get("tp_bonus", 0))
