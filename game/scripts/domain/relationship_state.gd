extends RefCounted
## Affinity score, recruitment status and story flags per NPC.

const MIN_SCORE := -100
const MAX_SCORE := 100
const STATUSES := ["unknown", "available", "joined", "left", "unavailable"]

var scores: Dictionary = {}
var status: Dictionary = {}
var flags: Dictionary = {}
## The one companion who fights alongside the hero ("" = none). Must have status "joined".
var active: String = ""
## A second companion in the party ("" = none). Must have status "joined" and differ from `active`.
var second: String = ""


func get_score(npc_id: String) -> int:
	return int(scores.get(npc_id, 0))


func add_score(npc_id: String, delta: int) -> int:
	if npc_id == "":
		return 0
	var before := get_score(npc_id)
	scores[npc_id] = clampi(before + delta, MIN_SCORE, MAX_SCORE)
	return get_score(npc_id) - before


func get_status(npc_id: String) -> String:
	return str(status.get(npc_id, "unknown"))


func set_status(npc_id: String, value: String) -> bool:
	if npc_id == "" or not STATUSES.has(value):
		return false
	status[npc_id] = value
	return true


func set_flag(flag_id: String, value: bool = true) -> void:
	if flag_id != "":
		flags[flag_id] = value


func has_flag(flag_id: String) -> bool:
	return bool(flags.get(flag_id, false))


func to_dict() -> Dictionary:
	return {"scores": scores.duplicate(), "status": status.duplicate(), "flags": flags.duplicate(), "active": active, "second": second}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	var sc: Variant = d.get("scores", {})
	if sc is Dictionary:
		for k in sc:
			s.scores[str(k)] = clampi(int(sc[k]), MIN_SCORE, MAX_SCORE)
	var st: Variant = d.get("status", {})
	if st is Dictionary:
		for k in st:
			s.set_status(str(k), str(st[k]))
	var fl: Variant = d.get("flags", {})
	if fl is Dictionary:
		for k in fl:
			s.flags[str(k)] = bool(fl[k])
	s.active = str(d.get("active", ""))
	if s.active != "" and s.get_status(s.active) != "joined":
		s.active = ""  # a save must not name an active companion who is not in the party
	s.second = str(d.get("second", ""))
	if s.second == s.active or s.get_status(s.second) != "joined":
		s.second = ""
	if s.active == "" and s.second != "":
		s.active = s.second
		s.second = ""
	return s
