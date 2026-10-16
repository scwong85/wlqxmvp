extends RefCounted
## What the player has done in the world (M16): finished events, missed events, follow-ups waiting in a window,
## cooldowns of repeatable events, leads (clues), areas opened or closed by the story, and visit counts.

var done: Dictionary = {}        # event id -> week it finished
var missed: Array = []           # fixed events whose window passed without being played
var scheduled: Dictionary = {}   # event id -> {from, to} window set by a follow-up
var cooldown: Dictionary = {}    # event id -> first week it may happen again
var leads: Array = []            # lead ids, in the order learned
var areas_open: Array = []       # areas opened by events
var areas_closed: Array = []     # areas closed by events
var visits: Dictionary = {}      # area id -> times visited
var last_area: String = ""      # the area visited last (music and the map use its region)


func has_lead(id: String) -> bool:
	return leads.has(id)


func add_lead(id: String) -> bool:
	if id == "" or leads.has(id):
		return false
	leads.append(id)
	return true


func to_dict() -> Dictionary:
	return {"done": done.duplicate(), "missed": missed.duplicate(), "scheduled": scheduled.duplicate(true),
			"cooldown": cooldown.duplicate(), "leads": leads.duplicate(), "areas_open": areas_open.duplicate(),
			"areas_closed": areas_closed.duplicate(), "visits": visits.duplicate(), "last_area": last_area}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	var dn: Variant = d.get("done")
	if dn is Dictionary:
		for k in dn:
			s.done[str(k)] = int(dn[k])
	for key in ["missed", "leads", "areas_open", "areas_closed"]:
		var arr: Variant = d.get(key)
		if arr is Array:
			for e in arr:
				if e is String and not s.get(key).has(e):
					s.get(key).append(e)
	var sc: Variant = d.get("scheduled")
	if sc is Dictionary:
		for k in sc:
			if sc[k] is Dictionary:
				s.scheduled[str(k)] = {"from": int(sc[k].get("from", 1)), "to": int(sc[k].get("to", 1))}
	s.last_area = str(d.get("last_area", ""))
	for key in ["cooldown", "visits"]:
		var m: Variant = d.get(key)
		if m is Dictionary:
			for k in m:
				s.get(key)[str(k)] = int(m[k])
	return s
