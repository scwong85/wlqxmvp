extends RefCounted
const LookRules = preload("res://scripts/domain/look_rules.gd")
## The hero: five attributes, chosen cultivation path, learned techniques. No UI, no engine nodes.

const ATTRS := ["body", "power", "agility", "insight", "spirit"]
const START_VALUE := 5
const MIN_ATTR := 1
const MAX_ATTR := 99

var attributes: Dictionary = {}
var path_id: String = ""
var techniques: Array = []
## Current stamina. -1 means "full"; GameState resolves it against the derived maximum.
var stamina: int = -1
## Temporary bonuses, e.g. from cooking: [{id, attr, amount, slots}]. `slots` = activity slots still affected.
var buffs: Array = []
## Chosen at the start of a run (empty name = the default name).
var hero_name: String = ""
var look: Dictionary = {"gender": "m", "hair": 0, "hair_color": 0, "outfit": 0, "skin": 0}


func _init() -> void:
	for a in ATTRS:
		attributes[a] = START_VALUE


func get_attr(id: String) -> int:
	return int(attributes.get(id, 0))


## Returns the change actually applied (after clamping). Unknown attributes are ignored.
func add_attr(id: String, delta: int) -> int:
	if not ATTRS.has(id):
		return 0
	var before := get_attr(id)
	attributes[id] = clampi(before + delta, MIN_ATTR, MAX_ATTR)
	return get_attr(id) - before


## Attribute value including active buffs. Used for skill checks; stored attributes stay permanent.
func effective_attr(id: String) -> int:
	var v := get_attr(id)
	for b in buffs:
		if str(b.get("attr", "")) == id:
			v += int(b.get("amount", 0))
	return v


## Adds a buff that affects the next `slots` activity slots. Same id replaces the old one (no stacking).
func add_buff(id: String, attr: String, amount: int, slots: int) -> void:
	if id == "" or not ATTRS.has(attr) or slots < 1:
		return
	for i in range(buffs.size() - 1, -1, -1):
		if str(buffs[i].id) == id:
			buffs.remove_at(i)
	buffs.append({"id": id, "attr": attr, "amount": amount, "slots": slots})


## Called once per elapsed slot. Returns the ids of buffs that just ran out.
func tick_buffs() -> Array:
	var expired: Array = []
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i]["slots"] = int(buffs[i].slots) - 1
		if int(buffs[i].slots) <= 0:
			expired.append(str(buffs[i].id))
			buffs.remove_at(i)
	expired.reverse()
	return expired


func learn(technique_id: String) -> bool:
	if technique_id == "" or techniques.has(technique_id):
		return false
	techniques.append(technique_id)
	return true


func to_dict() -> Dictionary:
	return {"attributes": attributes.duplicate(), "path_id": path_id, "techniques": techniques.duplicate(),
			"stamina": stamina, "buffs": buffs.duplicate(true), "hero_name": hero_name, "look": look.duplicate()}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	var attrs: Variant = d.get("attributes", {})
	if attrs is Dictionary:
		for a in ATTRS:
			if attrs.has(a):
				s.attributes[a] = clampi(int(attrs[a]), MIN_ATTR, MAX_ATTR)
	s.path_id = str(d.get("path_id", ""))
	s.hero_name = LookRules.clean_name(str(d.get("hero_name", "")))
	s.look = LookRules.sanitize(d.get("look", {}))
	s.stamina = int(d.get("stamina", -1))
	var bf: Variant = d.get("buffs", [])
	if bf is Array:
		for b in bf:
			if b is Dictionary:
				s.add_buff(str(b.get("id", "")), str(b.get("attr", "")), int(b.get("amount", 0)), int(b.get("slots", 0)))
	var techs: Variant = d.get("techniques", [])
	if techs is Array:
		for t in techs:
			if t is String:
				s.learn(t)
	return s
