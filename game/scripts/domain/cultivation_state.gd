extends RefCounted
## Progress along cultivation paths and how often each activity was practiced.

var path_progress: Dictionary = {}
var practice_counts: Dictionary = {}
var technique_xp: Dictionary = {}   # technique id -> experience
var realm: int = 0                  # index into content realms (0 = first)


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
	return {"path_progress": path_progress.duplicate(), "practice_counts": practice_counts.duplicate(), "technique_xp": technique_xp.duplicate(), "realm": realm}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.realm = clampi(int(d.get("realm", 0)), 0, 6)
	for field in ["path_progress", "practice_counts", "technique_xp"]:
		var src: Variant = d.get(field, {})
		if src is Dictionary:
			for k in src:
				s.get(field)[str(k)] = maxi(0, int(src[k]))
	return s
