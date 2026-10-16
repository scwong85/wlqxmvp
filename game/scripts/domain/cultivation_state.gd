extends RefCounted
## Progress along cultivation paths and how often each activity was practiced.

var path_progress: Dictionary = {}
var practice_counts: Dictionary = {}
var technique_xp: Dictionary = {}   # technique id -> experience
var realm: int = 0                  # index into content realms (0 = first)
var nodes: Array = []               # learned skill-tree node ids
var manual_choices: Dictionary = {} # manual group -> studied manual id
var equipment: Dictionary = {}      # slot -> worn piece id


func add_progress(path_id: String, n: int) -> void:
	if path_id == "":
		return
	path_progress[path_id] = maxi(0, int(path_progress.get(path_id, 0)) + n)


func record_practice(activity_id: String) -> int:
	if activity_id == "":
		return 0
	practice_counts[activity_id] = int(practice_counts.get(activity_id, 0)) + 1
	return practice_counts[activity_id]


func to_dict() -> Dictionary:
	return {"path_progress": path_progress.duplicate(), "practice_counts": practice_counts.duplicate(), "technique_xp": technique_xp.duplicate(), "realm": realm,
			"nodes": nodes.duplicate(), "manual_choices": manual_choices.duplicate(), "equipment": equipment.duplicate()}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.realm = clampi(int(d.get("realm", 0)), 0, 6)
	var nd: Variant = d.get("nodes", [])
	if nd is Array:
		for n in nd:
			if n is String and not s.nodes.has(n):
				s.nodes.append(n)
	for field in ["manual_choices", "equipment"]:
		var src2: Variant = d.get(field, {})
		if src2 is Dictionary:
			for k in src2:
				s.get(field)[str(k)] = str(src2[k])
	for field in ["path_progress", "practice_counts", "technique_xp"]:
		var src: Variant = d.get(field, {})
		if src is Dictionary:
			for k in src:
				s.get(field)[str(k)] = maxi(0, int(src[k]))
	return s
