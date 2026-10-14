extends RefCounted
## The hero: five attributes, chosen cultivation path, learned techniques. No UI, no engine nodes.

const ATTRS := ["body", "power", "agility", "insight", "spirit"]
const START_VALUE := 5
const MIN_ATTR := 1
const MAX_ATTR := 99

var attributes: Dictionary = {}
var path_id: String = ""
var techniques: Array = []


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


func learn(technique_id: String) -> bool:
	if technique_id == "" or techniques.has(technique_id):
		return false
	techniques.append(technique_id)
	return true


func to_dict() -> Dictionary:
	return {"attributes": attributes.duplicate(), "path_id": path_id, "techniques": techniques.duplicate()}


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
	var techs: Variant = d.get("techniques", [])
	if techs is Array:
		for t in techs:
			if t is String:
				s.learn(t)
	return s
