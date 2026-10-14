extends RefCounted
## Technique unlock conditions. A technique belongs to one path and can only be learned by that path.
## unlock: {"path_progress_min": int, "attr_min": {attr_id: int}}


static func meets(state: RefCounted, technique: Dictionary) -> bool:
	var path_id: String = state.player.path_id
	if path_id == "" or str(technique.get("path", "")) != path_id:
		return false
	var unlock: Dictionary = technique.get("unlock", {})
	if int(state.cultivation.path_progress.get(path_id, 0)) < int(unlock.get("path_progress_min", 0)):
		return false
	var attr_min: Dictionary = unlock.get("attr_min", {})
	for attr in attr_min:
		if state.player.get_attr(str(attr)) < int(attr_min[attr]):
			return false
	return true


## Learns every technique whose conditions are now met. Returns the ids newly learned.
static func check_unlocks(state: RefCounted, content: Object) -> Array:
	var learned: Array = []
	for t in content.techniques:
		if state.player.techniques.has(t.id):
			continue
		if meets(state, t) and state.player.learn(t.id):
			learned.append(t.id)
	return learned
