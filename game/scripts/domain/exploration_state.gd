extends RefCounted
## Progress through menu-based exploration routes. Persisted so a reload resumes mid-route.

var active: bool = false
var route: String = ""
var node: String = ""
var history: Array = []          # node ids visited in the current/last route
var clues: Array = []            # clue ids found (unique, kept across routes; used by the final crisis)
var completed: Array = []        # finished route ids
var pending_recruit: String = "" # companion whose invitation prompt should be shown on this node
var pending_battle: String = ""  # battle id triggered by a node; consumed by combat (M9)


func add_clue(id: String) -> bool:
	if id == "" or clues.has(id):
		return false
	clues.append(id)
	return true


func to_dict() -> Dictionary:
	return {"active": active, "route": route, "node": node, "history": history.duplicate(), "clues": clues.duplicate(),
			"completed": completed.duplicate(), "pending_recruit": pending_recruit, "pending_battle": pending_battle}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.active = bool(d.get("active", false))
	s.route = str(d.get("route", ""))
	s.node = str(d.get("node", ""))
	s.pending_recruit = str(d.get("pending_recruit", ""))
	s.pending_battle = str(d.get("pending_battle", ""))
	for key in ["history", "clues", "completed"]:
		var arr: Variant = d.get(key, [])
		if arr is Array:
			for v in arr:
				if v is String:
					if key == "clues":
						s.add_clue(v)
					elif key == "completed":
						if not s.completed.has(v):
							s.completed.append(v)
					else:
						s.history.append(v)
	if s.active and (s.route == "" or s.node == ""):
		s.active = false  # a half-written active route is dropped rather than trusted
	return s
