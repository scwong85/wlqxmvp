extends Node
## Loads game content (activities, paths, techniques, day hooks) from JSON and validates it.
## Content is data, never code: designers can change numbers and text without touching scripts.

const PlayerState = preload("res://scripts/domain/player_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")
const CalendarState = preload("res://scripts/domain/calendar_state.gd")

const DIR := "res://content/"
const NPC_IDS := ["shen_qinghe", "lu_chenzhou", "bai_yan"]  # replaced by companion data in M7
const REWARD_TYPES := ["attr", "resource", "item", "relationship", "stamina", "path_progress"]
const COST_KEYS := ["stamina", "coins", "food", "herbs", "ore", "medicine"]

var activities: Array = []
var paths: Array = []
var techniques: Array = []
var day_hooks: Array = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	activities = _load_list("activities/activities.json", "activities")
	paths = _load_list("cultivation/paths.json", "paths")
	techniques = _load_list("cultivation/techniques.json", "techniques")
	day_hooks = _load_list("events/day_hooks.json", "hooks")


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


func activity(id: String) -> Dictionary:
	return _find(activities, id)


func path(id: String) -> Dictionary:
	return _find(paths, id)


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
		var min_day := int(a.get("min_day", 1))
		if min_day < 1 or min_day > CalendarState.DAYS:
			errs.append("activity %s: min_day %d out of range" % [id, min_day])
		for ck in a.get("cost", {}):
			if not COST_KEYS.has(ck) or int(a.cost[ck]) < 0:
				errs.append("activity %s: bad cost '%s'" % [id, ck])
		if a.has("check"):
			if not PlayerState.ATTRS.has(str(a.check.get("attr", ""))) or int(a.check.get("target", 0)) < 1:
				errs.append("activity %s: bad check" % id)
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
	for h in day_hooks:
		var hid := str(h.get("id", ""))
		var day := int(h.get("day", 0))
		if day < 1 or day > CalendarState.DAYS:
			errs.append("hook %s: day out of range" % hid)
		if str(h.get("trigger", "")) != "day_start":
			errs.append("hook %s: unsupported trigger" % hid)
		if str(h.get("payload", {}).get("type", "")) == "":
			errs.append("hook %s: payload needs a type" % hid)
		for k in ["title_key", "body_key"]:
			if not has_key.call(str(h.get(k, ""))):
				errs.append("hook %s: translation key missing for %s" % [hid, k])
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
