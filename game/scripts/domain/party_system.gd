extends RefCounted
## One active companion at a time, chosen among those who have joined.


static func roster(state: RefCounted, content: Object) -> Array:
	return content.companion_ids().filter(func(id: String) -> bool: return state.relationships.get_status(id) == "joined")


static func active(state: RefCounted) -> String:
	return state.relationships.active


## Makes a joined companion the active one, replacing the previous (swap). False if not joined.
static func set_active(state: RefCounted, npc_id: String) -> bool:
	if state.relationships.get_status(npc_id) != "joined":
		return false
	state.relationships.active = npc_id
	return true


## Asks a joined companion to leave. Status becomes "left" (may be invited again).
static func dismiss(state: RefCounted, npc_id: String) -> bool:
	if state.relationships.get_status(npc_id) != "joined":
		return false
	state.relationships.set_status(npc_id, "left")
	if state.relationships.active == npc_id:
		state.relationships.active = ""
	return true
