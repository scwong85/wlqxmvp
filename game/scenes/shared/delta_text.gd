extends RefCounted
## Turns result deltas (attribute, resource, bond, clue ...) into player-facing text.


static func name_for(type: String, id: String) -> String:
	match type:
		"attr":
			return Loc.t("attr." + id)
		"resource":
			return Loc.t("resource." + id)
		"item":
			if not Loc.has_key("item." + id) and Loc.has_key("manual." + id.trim_prefix("manual_")):
				return Loc.t("manual." + id.trim_prefix("manual_"))
			return Loc.t("item." + id)
		"buff":
			return Loc.t("buff." + id)
		"clue":
			return Loc.t("clue." + id)
		"battle":
			return Loc.t("battle." + id)
		"relationship":
			return "%s %s" % [Loc.t("npc." + id), Loc.t("cult.affinity")]
		"stamina":
			return Loc.t("cult.stamina")
		"path_progress":
			if id == "current":
				return Loc.t("cult.progress")
			return "%s %s" % [Loc.t("path." + id), Loc.t("cult.progress")]
	return id


static func delta_line(d: Dictionary) -> String:
	if d.type == "clue" or d.type == "battle":
		return name_for(d.type, d.id)
	return Loc.t("cult.delta", {"name": name_for(d.type, d.id), "amount": "%+d" % int(d.delta)})
