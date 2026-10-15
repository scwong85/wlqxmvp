extends RefCounted
## Chooses the ending from what the player did. Table-driven: content/story/endings.json lists endings in priority
## order; the first whose `requires` all hold wins, and the last one has no requirements (the fallback).
## requires: flags_all [ids], flags_none [ids], bond_min N (best bond among all companions), path_progress_min N.


static func holds(state: RefCounted, req: Dictionary) -> bool:
	for f in req.get("flags_all", []):
		if not state.relationships.has_flag(str(f)):
			return false
	for f in req.get("flags_none", []):
		if state.relationships.has_flag(str(f)):
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
	return true


static func evaluate(state: RefCounted, content: Object) -> String:
	for e in content.endings:
		if holds(state, e.get("requires", {})):
			return str(e.id)
	return str(content.endings[-1].id) if not content.endings.is_empty() else ""
