extends RefCounted
## Traverses data-driven exploration routes: gating, seeded skill checks, effects, clues and flags.
## No UI. `route` is a route dictionary from content/exploration/routes.json; `content` is ContentService.

const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const SkillCheck = preload("res://scripts/domain/skill_check.gd")
const DayRules = preload("res://scripts/domain/day_rules.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")


static func node_of(route: Dictionary, node_id: String) -> Dictionary:
	for n in route.get("nodes", []):
		if str(n.id) == node_id:
			return n
	return {}


static func current_node(state: RefCounted, route: Dictionary) -> Dictionary:
	return node_of(route, state.exploration.node)


## {ok, reasons:[{key, params}]} for starting a route right now.
static func route_availability(state: RefCounted, route: Dictionary) -> Dictionary:
	var reasons: Array = []
	if state.calendar.finished:
		reasons.append({"key": "activity.blocked.finished", "params": {}})
	if state.exploration.active:
		reasons.append({"key": "explore.blocked.active", "params": {}})
	if state.exploration.completed.has(str(route.id)):
		reasons.append({"key": "explore.blocked.done", "params": {}})
	if state.calendar.week < int(route.get("min_week", 1)):
		reasons.append({"key": "activity.blocked.day_gate", "params": {}})
	reasons.append_array(_cost_reasons(state, route.get("cost", {})))
	return {"ok": reasons.is_empty(), "reasons": reasons}


static func _cost_reasons(state: RefCounted, cost: Dictionary) -> Array:
	var reasons: Array = []
	if int(cost.get("stamina", 0)) > state.player.stamina:
		reasons.append({"key": "activity.blocked.stamina", "params": {}})
	for k in cost:
		if k != "stamina" and state.resources.get_amount(str(k)) < int(cost[k]):
			reasons.append({"key": "activity.blocked.resource", "params": {}})
			break
	return reasons


static func _pay(state: RefCounted, cost: Dictionary, result: Dictionary) -> void:
	for k in cost:
		var n := int(cost[k])
		if n <= 0:
			continue
		if k == "stamina":
			state.player.stamina -= n
		else:
			state.resources.spend(str(k), n)
		result.cost.append({"id": str(k), "amount": n})


static func _blank_result(route: Dictionary) -> Dictionary:
	return {"ok": true, "route": str(route.id), "node": "", "choice": "", "grade": "none", "check": {}, "cost": [],
			"deltas": [], "clues": [], "flags": [], "battle": "", "text_key": "", "next": "", "ended": false, "time": {},
			"met": [], "departed": [], "recruit": ""}


## Begins a route: pays its cost and enters the start node. Time passes only when the route ends.
static func start(state: RefCounted, route: Dictionary, content: Object) -> Dictionary:
	var av := route_availability(state, route)
	if not av.ok:
		return {"ok": false, "reasons": av.reasons}
	var result := _blank_result(route)
	_pay(state, route.get("cost", {}), result)
	state.exploration.active = true
	state.exploration.route = str(route.id)
	state.exploration.history = []
	state.exploration.pending_battle = ""
	_enter(state, route, str(route.start), result, content)
	result.next = str(route.start)
	return result


## Gate problems for a choice or route gate: [{key, params}]. Empty = open.
static func gate_reasons(state: RefCounted, gate: Dictionary, content: Object) -> Array:
	var out: Array = []
	for attr in gate.get("attr_min", {}):
		if state.player.effective_attr(str(attr)) < int(gate.attr_min[attr]):
			out.append({"key": "explore.gate.attr", "params": {"attr": str(attr), "need": int(gate.attr_min[attr])}})
	for item in gate.get("item", {}):
		if int(state.resources.items.get(item, 0)) < int(gate.item[item]):
			out.append({"key": "explore.gate.item", "params": {"item": str(item), "need": int(gate.item[item])}})
	for npc in gate.get("bond_min", {}):
		if state.relationships.get_score(str(npc)) < int(gate.bond_min[npc]):
			out.append({"key": "explore.gate.bond", "params": {"npc": str(npc), "need": int(gate.bond_min[npc])}})
	for npc in gate.get("arc_min", {}):
		if int(state.relationships.arcs.get(str(npc), {}).get("stage", 0)) < int(gate.arc_min[npc]):
			out.append({"key": "arc.gate.stage", "params": {}})
	if gate.has("flag") and not state.relationships.has_flag(str(gate.flag)):
		out.append({"key": "explore.gate.flag", "params": {}})
	if gate.has("flag_not") and state.relationships.has_flag(str(gate.flag_not)):
		out.append({"key": "explore.gate.flag_not", "params": {}})
	if gate.has("clue_min") and state.exploration.clues.size() < int(gate.clue_min):
		out.append({"key": "explore.gate.clues", "params": {"need": int(gate.clue_min)}})
	return out


static func choice_reasons(state: RefCounted, choice: Dictionary, content: Object) -> Array:
	var reasons: Array = gate_reasons(state, choice.get("gate", {}), content)
	reasons.append_array(_cost_reasons(state, choice.get("cost", {})))
	return reasons


## One entry per choice of the current node: {id, label_key, available, reasons, chance (-1 = no check), cost}.
static func choice_states(state: RefCounted, route: Dictionary, content: Object) -> Array:
	var out: Array = []
	var node := current_node(state, route)
	for c in node.get("choices", []):
		var reasons := choice_reasons(state, c, content)
		var chance := -1
		if c.has("check"):
			chance = SkillCheck.chance(state.player.effective_attr(str(c.check.attr)), int(c.check.target))
		out.append({"id": str(c.id), "label_key": str(c.label_key), "available": reasons.is_empty(), "reasons": reasons,
				"chance": chance, "cost": c.get("cost", {})})
	return out


## Applies one effect and records what happened in `result`.
static func apply_effect(state: RefCounted, e: Dictionary, content: Object, result: Dictionary) -> void:
	var id := str(e.get("id", ""))
	match str(e.type):
		"clue":
			if state.exploration.add_clue(id):
				result.clues.append(id)
				result.deltas.append({"type": "clue", "id": id, "delta": 1})
		"flag":
			state.relationships.set_flag(id, bool(e.get("value", true)))
			result.flags.append(id)
		"battle":
			state.exploration.pending_battle = id
			result.battle = id
			result.deltas.append({"type": "battle", "id": id, "delta": 1})
		_:
			result.deltas.append_array(ActivityRules.apply_reward(state, e, int(e.get("amount", 0)), content))


static func _enter(state: RefCounted, route: Dictionary, node_id: String, result: Dictionary, content: Object) -> void:
	var node := node_of(route, node_id)
	state.exploration.node = node_id
	state.exploration.history.append(node_id)
	for e in node.get("on_enter", []):
		apply_effect(state, e, content, result)
	state.exploration.pending_recruit = ""
	if node.has("recruit"):
		var ev: Dictionary = RelationshipRules.evaluate_recruitment(state, str(node.recruit), content)
		if ev.result != "unavailable":
			state.exploration.pending_recruit = str(node.recruit)
			result.recruit = str(node.recruit)
	if str(node.get("type", "")) == "end":
		state.exploration.active = false
		state.exploration.completed.append(str(route.id))
		result.ended = true
		result.time = DayRules.end_slot(state)
		result.met = RelationshipRules.refresh(state, content)
		result.departed = RelationshipRules.check_departures(state, content)


## Takes one choice. Nothing changes unless it is available. Returns the result dictionary
## ({ok:false, reasons} on refusal).
static func choose(state: RefCounted, route: Dictionary, choice_id: String, content: Object) -> Dictionary:
	if not state.exploration.active or state.exploration.route != str(route.id):
		return {"ok": false, "reasons": [{"key": "explore.blocked.inactive", "params": {}}]}
	var node := current_node(state, route)
	var choice: Dictionary = {}
	for c in node.get("choices", []):
		if str(c.id) == choice_id:
			choice = c
	if choice.is_empty():
		return {"ok": false, "reasons": [{"key": "explore.blocked.choice", "params": {}}]}
	var reasons := choice_reasons(state, choice, content)
	if not reasons.is_empty():
		return {"ok": false, "reasons": reasons}

	var result := _blank_result(route)
	result.node = str(node.id)
	result.choice = choice_id
	_pay(state, choice.get("cost", {}), result)

	var block: Dictionary = {}
	if choice.has("check"):
		var key := "%s:%s:%s" % [route.id, node.id, choice_id]
		var c := SkillCheck.check(state.player.effective_attr(str(choice.check.attr)), int(choice.check.target),
				int(state.run_seed), key)
		c["attr"] = str(choice.check.attr)
		c["target"] = int(choice.check.target)
		result.check = c
		result.grade = "success" if c.success else "failure"
		block = choice.get("success" if c.success else "failure", {})
	for e in choice.get("effects", []):
		apply_effect(state, e, content, result)
	for e2 in block.get("effects", []):
		apply_effect(state, e2, content, result)
	result.text_key = str(block.get("text_key", ""))
	result.next = str(block.get("next", choice.get("next", "")))
	_enter(state, route, result.next, result, content)
	return result
