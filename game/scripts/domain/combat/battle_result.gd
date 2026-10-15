extends RefCounted
## Applies the result of a battle to the saved game: rewards or penalties from the scenario data,
## story flags, and the medicine that was used. Pure rules, no UI.

const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const EndingRules = preload("res://scripts/domain/ending_rules.gd")

const ACTIVE := "$active"   # reward target meaning "the companion in the party, if any"


## `outcome` is "victory", "defeat" or "" (abandoned: nothing but the medicine is settled).
## Returns {deltas: Array of delta dictionaries, flags: Array of flag ids}.
static func apply(state: RefCounted, scenario: Dictionary, outcome: String, items_left: Dictionary, content: Object) -> Dictionary:
	var result := {"deltas": [], "flags": []}
	var have: int = state.resources.get_amount("medicine")
	var left: int = int(items_left.get("medicine", have))
	if left < have:
		state.resources.spend("medicine", have - left)
	if outcome != "victory" and outcome != "defeat":
		return result
	var block: Dictionary = scenario.get("on_" + outcome, {})
	for r in block.get("rewards", []):
		var reward: Dictionary = (r as Dictionary).duplicate()
		if str(reward.get("id", "")) == ACTIVE:
			var active := PartySystem.active(state)
			if active == "":
				continue
			reward["id"] = active
		var amount := int(reward.get("amount", 0))
		result.deltas.append_array(ActivityRules.apply_reward(state, reward, amount, content))
	for f in block.get("flags", []):
		state.relationships.set_flag(str(f))
		result.flags.append(str(f))
	if str(block.get("dialogue", "")) != "":
		state.story.pending_dialogue = str(block.dialogue)
	if scenario.get("ends_run", false):
		state.story.ending = EndingRules.evaluate(state, content)
		result["ending"] = state.story.ending
	return result
