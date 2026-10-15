extends RefCounted
## Deterministic battle AI, used for enemies (and for auto-playing the player side in tests).
## Fixed priorities and fixed tie-breaks: for the same board it always makes the same decision.
## Score of an attack = kills*1000 + damage + breaks*50 + leader/protected bonuses (+status), small penalties
## for ending on a hazard or spending technique points. Healing beats attacking only for a badly hurt ally.

const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")
const CombatRules = preload("res://scripts/domain/combat/combat_rules.gd")


static func take_turn(battle: RefCounted) -> void:
	var u: RefCounted = battle.active()
	if u == null:
		return
	if u.npc:
		battle.end_turn()
		return
	for fa in free_actions(battle):
		_run_free(battle, u, fa)
	var plan := decide(battle)
	if not plan.is_empty():
		if plan.cell != u.pos:
			battle.move(u.id, plan.cell)
		if plan.kind == "advance":
			pass
		elif plan.kind == "attack":
			battle.attack(u.id, plan.tech, plan.target)
		elif plan.kind == "support":
			battle.support(u.id, plan.tech, plan.target)
		elif plan.kind == "item":
			battle.use_item(u.id, plan.tech, plan.target)
	take_follow_ups(battle)
	if battle.outcome == "" and battle.active() == u:
		battle.end_turn()


static func _run_free(battle: RefCounted, u: RefCounted, fa: Dictionary) -> void:
	if fa.kind == "attack":
		battle.attack(u.id, fa.tech, fa.target)
	else:
		battle.support(u.id, fa.tech, fa.target)


## Free once-per-battle (bond) abilities worth using right now, at the unit's current position.
## Heal when an ally is hurt, mark the strongest foe in range, boost movement when no attack is possible yet.
static func free_actions(battle: RefCounted) -> Array:
	var out: Array = []
	var u: RefCounted = battle.active()
	if u == null or u.npc:
		return out
	var foes: Array = battle.alive_units("enemy" if u.team == "player" else "player")
	var friends: Array = battle.alive_units(u.team)
	var no_attack := _best_plan(battle, u).is_empty()
	for tid in battle.technique_ids(u):
		var tech: Dictionary = battle.content.combat_tech(str(tid))
		if tech.is_empty() or not tech.get("free", false) or not battle.can_use(u, str(tid)):
			continue
		if tech.kind == "attack":
			var pick: RefCounted = null
			for f in foes:
				if CombatGrid.distance(u.pos, f.pos) <= int(tech.range) and not f.has_status("weaken") \
						and (pick == null or f.power > pick.power):
					pick = f
			if pick != null:
				out.append({"kind": "attack", "tech": str(tid), "target": pick.id})
		elif tech.has("mp_bonus"):
			if no_attack and not foes.is_empty():
				out.append({"kind": "support", "tech": str(tid), "target": u.id})
		else:
			var hurt: RefCounted = null
			for a in friends:
				if CombatGrid.distance(u.pos, a.pos) <= int(tech.range) and a.hp <= a.max_hp * 0.6 \
						and CombatRules.support_result(tech, a).heal >= 6 and (hurt == null or a.hp < hurt.hp):
					hurt = a
			if hurt != null:
				out.append({"kind": "support", "tech": str(tid), "target": hurt.id})
	return out


## The decision for the active unit: {kind: attack|support|item|advance, cell, tech, target} or {} (stay put).
## The battle screen uses this to play enemy turns step by step; take_turn uses the same decision.
static func decide(battle: RefCounted) -> Dictionary:
	var u: RefCounted = battle.active()
	if u == null or u.npc:
		return {}
	var plan := _best_plan(battle, u)
	if not plan.is_empty():
		return plan
	var cell := _advance_cell(battle, u)
	if cell != u.pos:
		return {"kind": "advance", "cell": cell}
	return {}


## Spends every pending free follow-up (in a fixed order).
static func take_follow_ups(battle: RefCounted) -> void:
	var guard := 0
	while not battle.pending_followups.is_empty() and battle.outcome == "" and guard < 20:
		guard += 1
		var f: Dictionary = battle.pending_followups[0]
		var r: Dictionary = battle.follow_up(f.unit, f.target)
		if not r.ok and not battle.pending_followups.is_empty() and battle.pending_followups[0] == f:
			battle.pending_followups.remove_at(0)


static func _cells(battle: RefCounted, u: RefCounted) -> Array:
	var reach: Dictionary = battle.move_options(u)
	var list: Array = []
	for c in reach:
		list.append({"cell": c, "cost": reach[c]})
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.cost != b.cost:
			return a.cost < b.cost
		if a.cell.y != b.cell.y:
			return a.cell.y < b.cell.y
		return a.cell.x < b.cell.x)
	return list


static func _best_plan(battle: RefCounted, u: RefCounted) -> Dictionary:
	var best := {}
	var best_score := -1.0e9
	var home: Vector2i = u.pos
	var foes: Array = battle.alive_units("enemy" if u.team == "player" else "player")
	var friends: Array = battle.alive_units(u.team)
	for entry in _cells(battle, u):
		var cell: Vector2i = entry.cell
		var terrain_bonus := 0.0
		if battle.grid.terrain_at(cell) == "hazard":
			terrain_bonus -= 10.0
		elif battle.grid.terrain_at(cell) == "cover":
			terrain_bonus += 4.0
		u.pos = cell
		for tid in battle.technique_ids(u):
			var tech: Dictionary = battle.content.combat_tech(str(tid))
			var cost := int(tech.get("cost", 0))
			if tech.is_empty() or u.tp < cost or tech.get("once", false):
				continue
			if tech.kind == "attack":
				for t in foes:
					if CombatGrid.distance(cell, t.pos) > int(tech.range):
						continue
					var r: Dictionary = CombatRules.attack_result(battle, u, tech, t)
					var score: float = (1000.0 if r.kills else 0.0) + r.damage + (50.0 if r.breaks else 0.0) \
							+ (20.0 if t.leader else 0.0) + (12.0 if t.protected else 0.0) \
							+ (5.0 if r.status != null else 0.0) - cost * 0.5 + terrain_bonus - entry.cost * 0.01
					if score > best_score:
						best_score = score
						best = {"kind": "attack", "cell": cell, "tech": str(tid), "target": t.id}
			else:
				for a in friends:
					if CombatGrid.distance(cell, a.pos) > int(tech.range):
						continue
					var sr: Dictionary = CombatRules.support_result(tech, a)
					var need: float = float(sr.heal) + float(sr.resolve_gain) * 0.5 + float(sr.cleansed.size()) * 3.0
					if need < 8.0 or float(a.hp) > float(a.max_hp) * 0.6:
						continue
					var score2: float = 200.0 + need - cost * 0.5 + terrain_bonus - entry.cost * 0.01
					if score2 > best_score:
						best_score = score2
						best = {"kind": "support", "cell": cell, "tech": str(tid), "target": a.id}
		for item in battle.content.combat_items:
			if int(battle.items.get(str(item.resource), 0)) < 1:
				continue
			for a in friends:
				if CombatGrid.distance(cell, a.pos) > int(item.range) or a.hp > a.max_hp * 0.4:
					continue
				var heal := mini(int(item.heal), a.max_hp - a.hp)
				var score3: float = 190.0 + heal + terrain_bonus - entry.cost * 0.01
				if score3 > best_score:
					best_score = score3
					best = {"kind": "item", "cell": cell, "tech": str(item.id), "target": a.id}
	u.pos = home
	return best


## No attack or heal is possible this turn: close in on the nearest foe, preferring cover.
static func _advance_cell(battle: RefCounted, u: RefCounted) -> Vector2i:
	var foes: Array = battle.alive_units("enemy" if u.team == "player" else "player")
	if foes.is_empty():
		return u.pos
	var best_cell: Vector2i = u.pos
	var best_score := 1.0e9
	for entry in _cells(battle, u):
		var d := 99
		for f in foes:
			d = mini(d, CombatGrid.distance(entry.cell, f.pos))
		var score: float = float(d) * 10.0 + entry.cost * 0.01
		if battle.grid.terrain_at(entry.cell) == "hazard":
			score += 15.0
		elif battle.grid.terrain_at(entry.cell) == "cover":
			score -= 3.0
		if score < best_score:
			best_score = score
			best_cell = entry.cell
	return best_cell
