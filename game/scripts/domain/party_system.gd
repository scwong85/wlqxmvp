extends RefCounted
## The party: up to two joined companions fight beside the hero. `active` is the first of them, `second` the other.

const MAX_COMPANIONS := 2


static func roster(state: RefCounted, content: Object) -> Array:
	return content.companion_ids().filter(func(id: String) -> bool: return state.relationships.get_status(id) == "joined")


## The first companion in the party ("" = none).
static func active(state: RefCounted) -> String:
	return state.relationships.active


## Everyone in the party, in order (zero, one or two ids).
static func party(state: RefCounted) -> Array:
	var out: Array = []
	for id in [state.relationships.active, state.relationships.second]:
		if str(id) != "":
			out.append(str(id))
	return out


static func in_party(state: RefCounted, npc_id: String) -> bool:
	return npc_id != "" and party(state).has(npc_id)


## Puts a joined companion in the party: the first free place, or the second place when both are taken
## (that companion steps out). False if not joined.
static func set_active(state: RefCounted, npc_id: String) -> bool:
	if state.relationships.get_status(npc_id) != "joined":
		return false
	if in_party(state, npc_id):
		return true
	if state.relationships.active == "":
		state.relationships.active = npc_id
	else:
		state.relationships.second = npc_id
	return true


## Takes a companion out of the party (they stay joined). The other one becomes the first.
static func leave(state: RefCounted, npc_id: String) -> bool:
	if not in_party(state, npc_id):
		return false
	if state.relationships.active == npc_id:
		state.relationships.active = state.relationships.second
		state.relationships.second = ""
	else:
		state.relationships.second = ""
	return true


## Asks a joined companion to leave. Status becomes "left" (may be invited again).
static func dismiss(state: RefCounted, npc_id: String) -> bool:
	if state.relationships.get_status(npc_id) != "joined":
		return false
	state.relationships.set_status(npc_id, "left")
	leave(state, npc_id)
	return true
