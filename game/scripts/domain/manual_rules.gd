extends RefCounted
## Manuals are items found in the world. Studying one takes stamina and a slot and teaches an outside technique;
## only one manual of each group (kind) can be studied, so the choice matters.
## content/cultivation/manuals.json: [{id, item, name_key, technique, group, realm_min}]

const DayRules = preload("res://scripts/domain/day_rules.gd")

const STUDY_STAMINA := 4


static func manual(content: Object, id: String) -> Dictionary:
	for m in content.manuals:
		if str(m.id) == id:
			return m
	return {}


static func owned(state: RefCounted, content: Object) -> Array:
	return content.manuals.filter(func(m: Dictionary) -> bool: return state.resources.get_item(str(m.item)) > 0)


static func studied(state: RefCounted, id: String) -> bool:
	return state.cultivation.manual_choices.values().has(id)


## {ok, reasons:[{key, params}]}.
static func can_study(state: RefCounted, id: String, content: Object) -> Dictionary:
	var m := manual(content, id)
	var reasons: Array = []
	if m.is_empty() or state.resources.get_item(str(m.item)) <= 0:
		return {"ok": false, "reasons": [{"key": "manual.none", "params": {}}]}
	if studied(state, id):
		return {"ok": false, "reasons": [{"key": "manual.known", "params": {}}]}
	if state.cultivation.manual_choices.has(str(m.group)):
		reasons.append({"key": "manual.group_taken", "params": {}})
	if int(state.cultivation.realm) < int(m.realm_min):
		reasons.append({"key": "manual.realm", "params": {"realm": int(m.realm_min)}})
	if state.calendar.finished:
		reasons.append({"key": "activity.blocked.finished", "params": {}})
	if state.player.stamina < STUDY_STAMINA:
		reasons.append({"key": "manual.stamina", "params": {}})
	return {"ok": reasons.is_empty(), "reasons": reasons}


static func study(state: RefCounted, id: String, content: Object) -> Dictionary:
	var c := can_study(state, id, content)
	if not c.ok:
		return c
	var m := manual(content, id)
	state.player.stamina -= STUDY_STAMINA
	state.cultivation.manual_choices[str(m.group)] = id
	state.player.learn(str(m.technique))
	var time: Dictionary = DayRules.end_slot(state)
	return {"ok": true, "reasons": [], "manual": m, "time": time}
