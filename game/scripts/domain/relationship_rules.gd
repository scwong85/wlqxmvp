extends RefCounted
## Affinity, meeting, recruitment and departure of companions. Pure rules: no UI, no engine nodes.
## `content` exposes companion(id), companion_ids() (ContentService or a test double).

const PlayerState = preload("res://scripts/domain/player_state.gd")


static func _ids(content: Object) -> Array:
	return content.companion_ids()


## Preferred-activity bonus: +1 bond with each met companion who likes the activity just done.
## Returns the relationship deltas applied.
static func preferred_bonus(state: RefCounted, activity_id: String, content: Object) -> Array:
	var out: Array = []
	for id in _ids(content):
		var c: Dictionary = content.companion(id)
		if not (c.preferred_activities as Array).has(activity_id):
			continue
		if not ["available", "joined"].has(state.relationships.get_status(id)):
			continue
		var d: int = state.relationships.add_score(id, 1)
		if d != 0:
			out.append({"type": "relationship", "id": id, "delta": d})
	return out


## Runs after every slot: unknown -> available once the meet day arrives. Returns newly met ids.
static func refresh(state: RefCounted, content: Object) -> Array:
	var met: Array = []
	for id in _ids(content):
		var c: Dictionary = content.companion(id)
		if state.relationships.get_status(id) == "unknown" and state.calendar.week >= int(c.meet_week):
			state.relationships.set_status(id, "available")
			met.append(id)
	return met


## {result: "ready" | "refuse" | "unavailable", reasons: [{key, params}]}.
## ready = may be invited; refuse = not yet (reasons say why); unavailable = cannot be invited at all.
static func evaluate_recruitment(state: RefCounted, npc_id: String, content: Object) -> Dictionary:
	var c: Dictionary = content.companion(npc_id)
	var status: String = state.relationships.get_status(npc_id)
	if c.is_empty() or ["joined", "unknown", "unavailable"].has(status):
		return {"result": "unavailable", "reasons": [{"key": "recruit.reason.status", "params": {}}]}
	for f in c.depart.get("flags", []):
		if state.relationships.has_flag(str(f)):
			return {"result": "unavailable", "reasons": [{"key": "recruit.reason.flag", "params": {}}]}
	var rec: Dictionary = c.recruit
	var reasons: Array = []
	if state.calendar.week < int(rec.week_min):
		reasons.append({"key": "recruit.reason.day", "params": {"need": int(rec.week_min)}})
	if state.relationships.get_score(npc_id) < int(rec.score_min):
		reasons.append({"key": "recruit.reason.score", "params": {"need": int(rec.score_min)}})
	for attr in rec.get("attr_min", {}):
		if state.player.get_attr(str(attr)) < int(rec.attr_min[attr]):
			reasons.append({"key": "recruit.reason.attr", "params": {"attr": str(attr), "need": int(rec.attr_min[attr])}})
	return {"result": "refuse" if not reasons.is_empty() else "ready", "reasons": reasons}


## Invites a companion. Joining takes the active slot if it is empty. Returns {ok, result, reasons}.
static func recruit(state: RefCounted, npc_id: String, content: Object) -> Dictionary:
	var ev := evaluate_recruitment(state, npc_id, content)
	if ev.result != "ready":
		return {"ok": false, "result": ev.result, "reasons": ev.reasons}
	state.relationships.set_status(npc_id, "joined")
	if state.relationships.active == "":
		state.relationships.active = npc_id
	return {"ok": true, "result": "joined", "reasons": []}


## Declining an offer is remembered but costs nothing; the companion can be invited again later.
static func decline(state: RefCounted, npc_id: String) -> void:
	state.relationships.set_flag("declined_" + npc_id)


## Joined companions leave when their bond drops below the limit or a story flag fires.
## Returns the ids that left; a left companion can be invited again if the flags allow.
static func check_departures(state: RefCounted, content: Object) -> Array:
	var left: Array = []
	for id in _ids(content):
		if state.relationships.get_status(id) != "joined":
			continue
		var dep: Dictionary = content.companion(id).depart
		var go := false
		if dep.has("score_below") and state.relationships.get_score(id) < int(dep.score_below):
			go = true
		for f in dep.get("flags", []):
			if state.relationships.has_flag(str(f)):
				go = true
		if go:
			state.relationships.set_status(id, "left")
			if state.relationships.active == id:
				state.relationships.active = ""
			left.append(id)
	return left
