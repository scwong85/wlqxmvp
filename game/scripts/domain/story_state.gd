extends RefCounted
const StageRules = preload("res://scripts/domain/stage_rules.gd")
## Story progress that is not a flag: the dialogue being shown, the one queued next, and the ending reached.

var dialogue: Dictionary = {}       # {id, node, hook} while a dialogue is open, else {}
var pending_dialogue: String = ""   # queued by a battle result (e.g. the aftermath scene)
var ending: String = ""             # ending id once the run is over


func to_dict() -> Dictionary:
	return {"dialogue": dialogue.duplicate(), "pending_dialogue": pending_dialogue, "ending": ending}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	var dlg: Variant = d.get("dialogue")
	if dlg is Dictionary and str(dlg.get("id", "")) != "":
		s.dialogue = {"id": str(dlg.id), "node": str(dlg.get("node", "")), "hook": str(dlg.get("hook", "")),
				"stage": StageRules.sanitize(dlg.get("stage", {})), "log": _clean_log(dlg.get("log", []))}
	s.pending_dialogue = str(d.get("pending_dialogue", ""))
	s.ending = str(d.get("ending", ""))
	return s


static func _clean_log(v: Variant) -> Array:
	var out: Array = []
	if v is Array:
		for e in v:
			if e is Dictionary:
				out.append({"speaker_key": str(e.get("speaker_key", "")), "text_key": str(e.get("text_key", "")), "choice_key": str(e.get("choice_key", ""))})
	return out.slice(maxi(0, out.size() - 60))
