extends RefCounted
## The epilogue composer (M26). content/story/epilogue.json lists tagged snippets in sections; for every section the
## first snippet whose requirements hold is used (companion sections once per companion, in the companion's order).
## compose() returns paragraphs: [{section, keys: [loc keys], params: {name, skill}}] in reading order.

const EndingRules = preload("res://scripts/domain/ending_rules.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")


static func _first(state: RefCounted, content: Object, section: String, ending: String, cid: String = "") -> Dictionary:
	for s in content.epilogue.get("snippets", []):
		if str(s.section) != section:
			continue
		if cid != "" and str(s.get("companion", "")) != cid:
			continue
		if EndingRules.holds(state, s.get("requires", {}), content, cid, ending):
			return s
	return {}


static func compose(state: RefCounted, content: Object, ending: String) -> Array:
	var out: Array = []
	var skill: Array = EndingRules.best_skill(state)
	var skill_name := ""
	if skill[0] != "":
		skill_name = Loc_name("technique." + str(skill[0]))
	for section in content.epilogue.get("sections", []):
		if section == "comp":
			for cid in content.epilogue.get("companions", []):
				if ArcRules.outcome(state, str(cid)) == "":
					continue
				var keys: Array = []
				var a := _first(state, content, "comp_outcome", ending, str(cid))
				var b := _first(state, content, "comp_bond", ending, str(cid))
				for s in [a, b]:
					if not s.is_empty():
						keys.append(str(s.key))
				if not keys.is_empty():
					out.append({"section": "comp", "keys": keys, "params": {"name": Loc_name("npc." + str(cid))}})
			continue
		var sn := _first(state, content, str(section), ending)
		if not sn.is_empty():
			out.append({"section": str(section), "keys": [str(sn.key)], "params": {"skill": skill_name}})
	return out


static func Loc_name(key: String) -> String:
	return Engine.get_main_loop().root.get_node("Loc").t(key)
