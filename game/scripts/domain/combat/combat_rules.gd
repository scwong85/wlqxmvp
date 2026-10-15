extends RefCounted
## Combat arithmetic, shared by the real actions and the preview so the two can never disagree.
## Everything is integer maths with no randomness: the same board always gives the same outcome.
##
## Damage, in order (each step uses integer division and the result never drops below 1):
##   base      = attacker.power + technique.damage (+ technique.bonus_vs_broken if the target is Broken)
##   damage    = base - target.body / 2
##   Weaken    on the attacker: damage - damage / 4
##   Broken    target: damage + damage / 2
##   Cover     under the target: damage - damage / 4
##   Guard     target: damage - damage / 2
##   Collision (pushed into a wall or a unit): + 2
## Resolve damage = technique.resolve (halved, at least 1, when the target guards; 0 when already Broken).

const COLLISION_DAMAGE := 2


static func push_cell(attacker: RefCounted, target: RefCounted) -> Vector2i:
	var d: Vector2i = target.pos - attacker.pos
	var step := Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
	return target.pos + step


## Full projected result of `attacker` using `tech` on `target`. Pure: changes nothing.
## {damage, resolve_damage, hp_after, kills, breaks, mods:[String], push_to:(Vector2i or null), collision, status}
static func attack_result(battle: RefCounted, attacker: RefCounted, tech: Dictionary, target: RefCounted) -> Dictionary:
	var mods: Array = []
	var base: int = attacker.power + int(tech.get("damage", 0))
	if tech.has("bonus_vs_broken") and target.broken:
		base += int(tech.bonus_vs_broken)
		mods.append("bonus_broken")
	var dmg := maxi(1, base - target.defense())
	if attacker.has_status("weaken"):
		dmg = maxi(1, dmg - dmg / 4)
		mods.append("weaken")
	if target.broken:
		dmg = dmg + dmg / 2
		mods.append("broken")
	if battle.grid.terrain_at(target.pos) == "cover":
		dmg = maxi(1, dmg - dmg / 4)
		mods.append("cover")
	if target.guarding:
		dmg = maxi(1, dmg - dmg / 2)
		mods.append("guard")
	var resolve_damage := int(tech.get("resolve", 0))
	if target.broken:
		resolve_damage = 0
	elif target.guarding:
		resolve_damage = maxi(1, resolve_damage / 2)
	var push_to = null
	var collision := false
	if int(tech.get("push", 0)) > 0:
		var cell := push_cell(attacker, target)
		if battle.grid.in_bounds(cell) and not battle.occupied().has(cell):
			push_to = cell
		else:
			collision = true
			dmg += COLLISION_DAMAGE
			mods.append("collision")
	var hp_after: int = maxi(0, target.hp - dmg)
	var kills: bool = hp_after == 0
	var breaks: bool = (not target.broken) and (not kills) and target.resolve - resolve_damage <= 0
	var status: Variant = tech.get("status", null)
	return {"damage": dmg, "resolve_damage": resolve_damage, "hp_after": hp_after, "kills": kills, "breaks": breaks,
			"mods": mods, "push_to": push_to, "collision": collision, "status": status}


## Projected result of a support technique on an ally. Pure.
static func support_result(tech: Dictionary, target: RefCounted) -> Dictionary:
	var heal := mini(int(tech.get("heal", 0)), target.max_hp - target.hp)
	var resolve_gain := mini(int(tech.get("resolve_restore", 0)), target.max_resolve - target.resolve)
	var cleansed: Array = []
	if tech.get("cleanse", false):
		for s in target.statuses:
			cleansed.append(str(s.id))
	return {"heal": heal, "resolve_gain": resolve_gain, "cleansed": cleansed, "mp": int(tech.get("mp_bonus", 0))}


## Movement points for a unit this turn: 3 + agility / 5, minus Slow, never below 1.
static func movement_points(unit: RefCounted, content: Object) -> int:
	var mp: int = 3 + unit.agility / 5
	for s in unit.statuses:
		mp += int(content.combat_status(str(s.id)).get("mp", 0))
	return maxi(1, mp)
