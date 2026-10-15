extends RefCounted
## Turns battle data into player-facing text (all through translation keys).

const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")


static func unit_name(battle: RefCounted, u: RefCounted) -> String:
	var base: String = Loc.t(u.name_key)
	if u.template == "":
		return base
	var same := 0
	var index := 0
	for x in battle.units:
		if x.template == u.template:
			same += 1
			if x == u:
				index = same
	return base if same <= 1 else "%s%d" % [base, index]


static func name_of(battle: RefCounted, id: String) -> String:
	var u: RefCounted = battle.unit(id)
	return unit_name(battle, u) if u != null else id


static func tech_name(battle: RefCounted, id: String) -> String:
	var t: Dictionary = battle.content.combat_tech(id)
	return Loc.t(str(t.get("name_key", "combat.tech." + id)))


static func status_name(id: String) -> String:
	return Loc.t("combat.status." + id)


static func mods_text(mods: Array) -> String:
	if mods.is_empty():
		return ""
	return Loc.t("combat.ui.mods_wrap", {"list": Loc.t("ui.list_sep").join(mods.map(func(m: String) -> String: return Loc.t("combat.mod." + m)))})


## One line for a log event, or "" for events that are not shown (turn markers, offers).
static func log_line(battle: RefCounted, e: Dictionary) -> String:
	var t := str(e.type)
	var unit := name_of(battle, str(e.get("unit", "")))
	var target := name_of(battle, str(e.get("target", "")))
	match t:
		"battle_start":
			return Loc.t("combat.log.battle_start", {"name": Loc.t("combat.scenario." + battle.scenario_id)})
		"round_start":
			return Loc.t("combat.log.round_start", {"n": int(e.round)})
		"move":
			return Loc.t("combat.log.move", {"unit": unit})
		"attack":
			return Loc.t("combat.log.attack", {"unit": unit, "tech": tech_name(battle, str(e.tech)), "target": target,
					"dmg": int(e.damage), "res": int(e.resolve_damage), "mods": mods_text(e.mods)})
		"follow_up":
			return Loc.t("combat.log.follow_up", {"unit": unit, "target": target, "dmg": int(e.damage), "mods": mods_text(e.mods)})
		"push", "collision", "break", "kill", "guard", "recover":
			return Loc.t("combat.log." + t, {"unit": unit})
		"support":
			return Loc.t("combat.log.support", {"unit": unit, "tech": tech_name(battle, str(e.tech)), "target": target,
					"heal": int(e.heal), "res": int(e.resolve)})
		"boost":
			return Loc.t("combat.log.boost", {"unit": unit, "tech": tech_name(battle, str(e.tech)), "mp": int(e.mp)})
		"item":
			return Loc.t("combat.log.item", {"unit": unit, "target": target, "heal": int(e.heal)})
		"status":
			return Loc.t("combat.log.status", {"unit": unit, "status": status_name(str(e.status)), "turns": int(e.turns)})
		"status_end":
			return Loc.t("combat.log.status_end", {"unit": unit, "status": status_name(str(e.status))})
		"damage":
			return Loc.t("combat.log.damage_" + str(e.source), {"unit": unit, "amount": int(e.amount)})
		"outcome":
			return Loc.t("combat.log.outcome", {"result": Loc.t("combat.ui.result." + str(e.result)) + " - " + Loc.t("combat.outcome." + str(e.reason))})
	return ""


## Short status description for the info panel.
static func unit_line(battle: RefCounted, u: RefCounted) -> String:
	var line: String = Loc.t("combat.ui.unit_line", {"name": unit_name(battle, u), "hp": u.hp, "max": u.max_hp,
			"res": u.resolve, "maxres": u.max_resolve, "tp": u.tp})
	var tags: Array = []
	if u.broken:
		tags.append(Loc.t("combat.ui.broken"))
	if u.guarding:
		tags.append(Loc.t("combat.ui.guarding"))
	for s in u.statuses:
		tags.append("%s%d" % [status_name(str(s.id)), int(s.turns)])
	if not tags.is_empty():
		line += "\n" + Loc.t("combat.ui.status_line", {"list": Loc.t("ui.list_sep").join(tags)})
	return line
