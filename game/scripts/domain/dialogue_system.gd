extends RefCounted
## Runs data-driven dialogues (content/story/dialogues.json): speaker, text, choices with gates and effects.
## The open dialogue and node live in state.story.dialogue, so closing the game mid-scene resumes it.
##
## Dialogue: {id, entry:[{if?, node}], nodes:[{id, speaker_key?, text_key, on_enter?:[effect], next?:id, choices?:[choice]}]}
## Choice:   {id, label_key, gate?, effects?:[effect], next:id ("" ends)}
## Effects:  lead, schedule, unlock_area, lock_area (see WorldRules), flag, set_path, bond (id may be "$active"), resource, attr, stamina, battle (starts that fight when the scene ends),
##           queue (dialogue id to open next).
## Gates:    attr_min, bond_min, flag, flag_not (as in exploration) plus path_none, path_set and party_any.

const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")


static func node_of(dlg: Dictionary, node_id: String) -> Dictionary:
	for n in dlg.get("nodes", []):
		if str(n.id) == node_id:
			return n
	return {}


static func is_open(state: RefCounted) -> bool:
	return not state.story.dialogue.is_empty()


static func current_node(state: RefCounted, dlg: Dictionary) -> Dictionary:
	return node_of(dlg, str(state.story.dialogue.get("node", "")))


static func gate_reasons(state: RefCounted, gate: Dictionary, content: Object) -> Array:
	var out: Array = ExplorationSystem.gate_reasons(state, gate, content)
	if gate.get("path_none", false) and state.player.path_id != "":
		out.append({"key": "dialogue.gate.path_set", "params": {}})
	if gate.get("path_set", false) and state.player.path_id == "":
		out.append({"key": "dialogue.gate.path_none", "params": {}})
	if gate.get("party_any", false) and PartySystem.active(state) == "":
		out.append({"key": "dialogue.gate.no_party", "params": {}})
	return out


## Opens a dialogue at its entry node and applies that node's on_enter effects. Returns {ok, battle, ended, queue}.
static func start(state: RefCounted, dlg: Dictionary, hook_id: String, content: Object) -> Dictionary:
	var result := _blank()
	if dlg.is_empty():
		result.ok = false
		return result
	var entry := ""
	for e in dlg.get("entry", []):
		if gate_reasons(state, e.get("if", {}), content).is_empty():
			entry = str(e.node)
			break
	if entry == "" or node_of(dlg, entry).is_empty():
		result.ok = false
		return result
	state.story.dialogue = {"id": str(dlg.id), "node": entry, "hook": hook_id}
	_enter(state, dlg, entry, result, content)
	return result


## Choices of the current node with their availability: [{id, label_key, available, reasons}].
static func choice_states(state: RefCounted, dlg: Dictionary, content: Object) -> Array:
	var out: Array = []
	var node := current_node(state, dlg)
	for c in node.get("choices", []):
		var reasons := gate_reasons(state, c.get("gate", {}), content)
		out.append({"id": str(c.id), "label_key": str(c.label_key), "available": reasons.is_empty(), "reasons": reasons})
	return out


## Linear nodes: moves on to `next` (or ends the scene).
static func advance(state: RefCounted, dlg: Dictionary, content: Object) -> Dictionary:
	var node := current_node(state, dlg)
	if node.is_empty() or node.has("choices"):
		return {"ok": false}
	var result := _blank()
	_goto(state, dlg, str(node.get("next", "")), result, content)
	return result


static func choose(state: RefCounted, dlg: Dictionary, choice_id: String, content: Object) -> Dictionary:
	var node := current_node(state, dlg)
	for c in node.get("choices", []):
		if str(c.id) != choice_id:
			continue
		if not gate_reasons(state, c.get("gate", {}), content).is_empty():
			return {"ok": false}
		var result := _blank()
		for e in c.get("effects", []):
			_apply(state, e, result, content)
		_goto(state, dlg, str(c.get("next", "")), result, content)
		return result
	return {"ok": false}


static func _blank() -> Dictionary:
	return {"ok": true, "battle": "", "queue": "", "ended": false, "deltas": [], "flags": [], "node": ""}


static func _goto(state: RefCounted, dlg: Dictionary, next_id: String, result: Dictionary, content: Object) -> void:
	if next_id == "" or node_of(dlg, next_id).is_empty():
		var hook := str(state.story.dialogue.get("hook", ""))
		if hook.begins_with("event:"):
			WorldRules.complete_event(state, content, hook.trim_prefix("event:"))
		elif hook != "":
			EventRules.mark_fired(state, hook)
		state.story.dialogue = {}
		result.ended = true
		return
	state.story.dialogue["node"] = next_id
	_enter(state, dlg, next_id, result, content)


static func _enter(state: RefCounted, dlg: Dictionary, node_id: String, result: Dictionary, content: Object) -> void:
	result.node = node_id
	for e in node_of(dlg, node_id).get("on_enter", []):
		_apply(state, e, result, content)


static func _apply(state: RefCounted, e: Dictionary, result: Dictionary, content: Object) -> void:
	var id := str(e.get("id", ""))
	if WorldRules.apply_effect(state, e, content):
		return
	match str(e.type):
		"flag":
			state.relationships.set_flag(id)
			result.flags.append(id)
		"set_path":
			if state.player.path_id == "" and not content.path(id).is_empty():
				state.player.path_id = id
		"battle":
			result.battle = id
		"queue":
			result.queue = id
		"bond":
			var npc := PartySystem.active(state) if id == "$active" else id
			if npc != "":
				result.deltas.append_array(ActivityRules.apply_reward(state, {"type": "relationship", "id": npc}, int(e.amount), content))
		"resource", "attr", "stamina":
			var reward := {"type": str(e.type), "id": id if str(e.type) != "stamina" else "stamina"}
			result.deltas.append_array(ActivityRules.apply_reward(state, reward, int(e.amount), content))
