extends RefCounted
## Availability, cost payment, skill check, reward application and time passing for one activity.
## `def` is an activity dictionary from content/activities/activities.json.
## `content` is any object exposing `path(id)`, `techniques` (ContentService or a test double).

const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")
const SkillCheck = preload("res://scripts/domain/skill_check.gd")
const TechniqueRules = preload("res://scripts/domain/technique_rules.gd")
const DayRules = preload("res://scripts/domain/day_rules.gd")


## {ok, reasons}. Reasons are translation keys, safe to show to the player.
static func availability(state: RefCounted, def: Dictionary) -> Dictionary:
	var reasons: Array = []
	if state.calendar.finished:
		reasons.append("activity.blocked.finished")
	if state.calendar.day < int(def.get("min_day", 1)):
		reasons.append("activity.blocked.day_gate")
	var cost: Dictionary = def.get("cost", {})
	if int(cost.get("stamina", 0)) > state.player.stamina:
		reasons.append("activity.blocked.stamina")
	for k in cost:
		if k != "stamina" and state.resources.get_amount(str(k)) < int(cost[k]):
			reasons.append("activity.blocked.resource")
			break
	return {"ok": reasons.is_empty(), "reasons": reasons}


## Chance of passing the activity's check right now, or -1 when it has no check.
static func check_chance(state: RefCounted, def: Dictionary) -> int:
	if not def.has("check"):
		return -1
	return SkillCheck.chance(state.player.get_attr(str(def.check.attr)), int(def.check.target))


## Runs the activity. Nothing changes unless it is available. Returns
## {ok, reasons} on refusal, or {ok:true, activity_id, grade, check, cost, deltas, unlocked, time}.
static func perform(state: RefCounted, def: Dictionary, content: Object) -> Dictionary:
	var av := availability(state, def)
	if not av.ok:
		return {"ok": false, "reasons": av.reasons}

	var result := {"ok": true, "activity_id": str(def.id), "day": state.calendar.day,
			"slot": state.calendar.slot, "grade": "success", "check": {}, "cost": [], "deltas": [],
			"unlocked": [], "time": {}}

	var cost: Dictionary = def.get("cost", {})
	for k in cost:
		var n := int(cost[k])
		if n <= 0:
			continue
		if k == "stamina":
			state.player.stamina -= n
		else:
			state.resources.spend(str(k), n)
		result.cost.append({"id": str(k), "amount": n})

	if def.has("check"):
		var key := "%s:%d:%d" % [def.id, state.calendar.day, state.calendar.slot]
		var c := SkillCheck.check(state.player.get_attr(str(def.check.attr)), int(def.check.target),
				int(state.run_seed), key)
		c["attr"] = str(def.check.attr)
		c["target"] = int(def.check.target)
		result.check = c
		result.grade = "success" if c.success else "partial"

	for r in def.get("rewards", []):
		var amount := int(r.amount)
		if result.grade == "partial" and amount > 0:
			amount = ceili(amount / 2.0)  # a failed check still pays half, rounded up
		var applied := _apply_reward(state, r, amount, content)
		if applied.size() > 0:
			result.deltas.append_array(applied)

	state.cultivation.record_practice(str(def.id))
	result.unlocked = TechniqueRules.check_unlocks(state, content)
	result.time = DayRules.end_slot(state)
	return result


## Applies one reward. Returns the list of deltas actually applied (after clamping); may add an
## extra path_progress delta when an attribute gain is on the chosen path's affinity list.
static func _apply_reward(state: RefCounted, r: Dictionary, amount: int, content: Object) -> Array:
	var out: Array = []
	var id := str(r.id)
	match str(r.type):
		"attr":
			var d: int = state.player.add_attr(id, amount)
			if d != 0:
				out.append({"type": "attr", "id": id, "delta": d})
				var path: Dictionary = content.path(state.player.path_id) if state.player.path_id != "" else {}
				if d > 0 and path.has("affinity") and path.affinity.has(id):
					state.cultivation.add_progress(state.player.path_id, d)
					out.append({"type": "path_progress", "id": state.player.path_id, "delta": d})
		"resource":
			var d2: int = state.resources.add(id, amount)
			if d2 != 0:
				out.append({"type": "resource", "id": id, "delta": d2})
		"item":
			var d3: int = state.resources.add_item(id, amount)
			if d3 != 0:
				out.append({"type": "item", "id": id, "delta": d3})
		"relationship":
			var d4: int = state.relationships.add_score(id, amount)
			if d4 != 0:
				out.append({"type": "relationship", "id": id, "delta": d4})
		"stamina":
			var before: int = state.player.stamina
			state.player.stamina = clampi(before + amount, 0, CultivationRules.max_stamina(state.player))
			if state.player.stamina != before:
				out.append({"type": "stamina", "id": "stamina", "delta": state.player.stamina - before})
		"path_progress":
			var pid: String = state.player.path_id if id == "current" else id
			if pid != "" and amount != 0:
				state.cultivation.add_progress(pid, amount)
				out.append({"type": "path_progress", "id": pid, "delta": amount})
	return out
