extends RefCounted
## Companion arcs (M21). An arc is a chain of world events: stage 1 (meet), 2 (trust), 3 (test, which decides the
## outcome) and 4 (a closing scene that fixes the relationship type). The events are ordinary content gated by bond
## and by `arc_min`; this module only keeps the record and answers questions about it.
## Record per companion: {stage: 0..4, outcome: "" | redeemed | alternate | lost, bond: "" | friend | sworn | romance | rival}.
## content/companions/arcs.json: [{companion, planned?, stages:[{id, event}], outcomes:[..], bonds:[..]}]; `planned` (default: the
## number of stages) is the full length, so an arc whose later scenes are not written yet still reads "1/4".

const OUTCOMES := ["redeemed", "alternate", "lost"]
const BONDS := ["friend", "sworn", "romance", "rival"]
const MAX_STAGE := 4


static func record(state: RefCounted, cid: String) -> Dictionary:
	return state.relationships.arcs.get(cid, {"stage": 0, "outcome": "", "bond": ""})


static func stage(state: RefCounted, cid: String) -> int:
	return int(record(state, cid).stage)


static func outcome(state: RefCounted, cid: String) -> String:
	return str(record(state, cid).outcome)


static func bond_type(state: RefCounted, cid: String) -> String:
	return str(record(state, cid).bond)


static func _write(state: RefCounted, cid: String, key: String, value: Variant) -> void:
	var r: Dictionary = record(state, cid).duplicate()
	r[key] = value
	state.relationships.arcs[cid] = r


## Moves the arc forward (never back).
static func set_stage(state: RefCounted, cid: String, n: int) -> void:
	if cid != "":
		_write(state, cid, "stage", clampi(maxi(stage(state, cid), n), 0, MAX_STAGE))


## The first outcome sticks, except that a later stage may replace "lost" set by a missed scene only if none was chosen.
static func set_outcome(state: RefCounted, cid: String, value: String) -> void:
	if cid != "" and OUTCOMES.has(value) and outcome(state, cid) == "":
		_write(state, cid, "outcome", value)


static func set_bond(state: RefCounted, cid: String, value: String) -> void:
	if cid != "" and BONDS.has(value) and bond_type(state, cid) == "":
		_write(state, cid, "bond", value)


static func arc_of(content: Object, cid: String) -> Dictionary:
	for a in content.arcs:
		if str(a.companion) == cid:
			return a
	return {}


## {stage, total, outcome, bond, done, event}: `event` is the id of the scene that comes next ("" if none).
static func summary(state: RefCounted, content: Object, cid: String) -> Dictionary:
	var a := arc_of(content, cid)
	var st := stage(state, cid)
	var stages: Array = a.get("stages", [])
	var total := maxi(int(a.get("planned", stages.size())), stages.size())
	var next := ""
	if st < stages.size():
		next = str(stages[st].event)
	return {"stage": st, "total": total, "outcome": outcome(state, cid), "bond": bond_type(state, cid),
			"done": st >= total and total > 0, "event": next}


## Outcome tags of every companion with an arc, for the ending composer: {cid: {outcome, bond, stage}}.
static func tags(state: RefCounted, content: Object) -> Dictionary:
	var out := {}
	for a in content.arcs:
		var cid := str(a.companion)
		out[cid] = {"outcome": outcome(state, cid), "bond": bond_type(state, cid), "stage": stage(state, cid)}
	return out
