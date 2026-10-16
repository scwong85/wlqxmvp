extends RefCounted
## Chooses the ending from what the player did. Table-driven: content/story/endings.json lists endings in priority
## order; the first whose `requires` all hold wins, and the last one has no requirements (the fallback).
## requires: flags_all / flags_none / flags_any [ids], bond_min N (best bond among all companions), path_progress_min N,
## realm_min N (cultivation realm index), kept_min N (companions whose arc did not end `lost`),
## outcome_any ["cid:outcome", ...], outcome / bond ("value", for a companion snippet; see EpilogueRules),
## skill_min N (level of the best technique), coins_min N, unmet_min N (companions with no arc outcome), ending [ids].

const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")


static func holds(state: RefCounted, req: Dictionary, content: Object = null, cid: String = "", ending: String = "") -> bool:
	for f in req.get("flags_all", []):
		if not state.relationships.has_flag(str(f)):
			return false
	for f in req.get("flags_none", []):
		if state.relationships.has_flag(str(f)):
			return false
	if req.has("flags_any"):
		var any := false
		for f in req.flags_any:
			any = any or state.relationships.has_flag(str(f))
		if not any:
			return false
	if req.has("bond_min"):
		var best := 0
		for npc in state.relationships.scores:
			best = maxi(best, state.relationships.get_score(str(npc)))
		if best < int(req.bond_min):
			return false
	if req.has("path_progress_min"):
		var progress := 0
		if state.player.path_id != "":
			progress = int(state.cultivation.path_progress.get(state.player.path_id, 0))
		if progress < int(req.path_progress_min):
			return false
	if req.has("realm_min") and state.cultivation.realm < int(req.realm_min):
		return false
	if req.has("skill_min") and best_skill(state)[1] < int(req.skill_min):
		return false
	if req.has("coins_min") and state.resources.get_amount("coins") < int(req.coins_min):
		return false
	if req.has("ending") and not (req.ending as Array).has(ending):
		return false
	if req.has("outcome") and (cid == "" or ArcRules.outcome(state, cid) != str(req.outcome)):
		return false
	if req.has("bond") and (cid == "" or ArcRules.bond_type(state, cid) != str(req.bond)):
		return false
	if content != null and (req.has("kept_min") or req.has("unmet_min") or req.has("outcome_any")):
		var kept := 0
		var unmet := 0
		var tags := ArcRules.tags(state, content)
		for c in tags:
			var o: String = str(tags[c].outcome)
			if o == "":
				unmet += 1
			elif o != "lost":
				kept += 1
		if req.has("kept_min") and kept < int(req.kept_min):
			return false
		if req.has("unmet_min") and unmet < int(req.unmet_min):
			return false
		if req.has("outcome_any"):
			var hit := false
			for pair in req.outcome_any:
				var p: PackedStringArray = str(pair).split(":")
				hit = hit or (tags.has(p[0]) and str(tags[p[0]].outcome) == p[1])
			if not hit:
				return false
	return true


## [technique id, level] of the hero's best technique ("" and 0 if none).
static func best_skill(state: RefCounted) -> Array:
	var best: Array = ["", 0]
	for t in state.player.techniques:
		var lv := TechniqueLevels.level(state, str(t))
		if lv > int(best[1]) or best[0] == "":
			best = [str(t), lv]
	return best


static func evaluate(state: RefCounted, content: Object) -> String:
	for e in content.endings:
		if holds(state, e.get("requires", {}), content):
			return str(e.id)
	return str(content.endings[-1].id) if not content.endings.is_empty() else ""
