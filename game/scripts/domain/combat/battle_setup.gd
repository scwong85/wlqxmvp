extends RefCounted
## Builds a Battle from a scenario, a seed and (optionally) the hero's saved state.
## The seed only decides which candidate cell each enemy starts on; nothing in a fight is random.

const Battle = preload("res://scripts/domain/combat/battle.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")
const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")

const HERO_ID := "hero"
const BOND_MIN := 8
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")
const SkillTree = preload("res://scripts/domain/skill_tree.gd")
const EquipmentRules = preload("res://scripts/domain/equipment_rules.gd")


static func build(content: Object, scenario_id: String, seed_value: int, game_state: RefCounted = null, party_ids: Array = []) -> RefCounted:
	var sc: Dictionary = content.scenario(scenario_id)
	if sc.is_empty():
		return null
	var b := Battle.new(content)
	b.scenario_id = scenario_id
	b.seed_value = seed_value
	b.max_rounds = int(sc.max_rounds)
	b.objective = Battle.whole_numbers((sc.objective as Dictionary).duplicate(true))
	for t in sc.get("terrain", []):
		b.grid.set_terrain(Vector2i(int(t[0]), int(t[1])), str(t[2]))
	var used := {}
	var cells: Array = sc.player_cells
	var slot := 0
	var hero := _hero(content, game_state)
	hero.pos = _cell(cells[slot])
	b.units.append(hero)
	used[hero.pos] = true
	slot += 1
	for cid in party_ids:
		if slot >= cells.size():
			break
		var c := _companion(content, str(cid), game_state == null or game_state.relationships.get_score(str(cid)) >= BOND_MIN)
		if c == null:
			continue
		c.pos = _cell(cells[slot])
		b.units.append(c)
		used[c.pos] = true
		slot += 1
		# A strong bond gives the hero a duo technique with this companion.
		var duo: Dictionary = content.duo_for(str(cid))
		if not duo.is_empty() and game_state != null and game_state.relationships.get_score(str(cid)) >= int(duo.bond_min) and not hero.techniques.has(str(duo.tech)):
			hero.techniques.append(str(duo.tech))
	if sc.has("npc"):
		var n := _from_template(content, str(sc.npc.template), str(sc.npc.id), "player")
		n.npc = true
		n.protected = str(sc.objective.get("protect", "")) == n.id
		n.pos = _cell(sc.npc.cell)
		b.units.append(n)
		used[n.pos] = true
	var counts := {}
	for i in sc.enemies.size():
		var spec: Dictionary = sc.enemies[i]
		var tpl := str(spec.template)
		counts[tpl] = int(counts.get(tpl, 0)) + 1
		var e := _from_template(content, tpl, "%s_%d" % [tpl, counts[tpl]], "enemy")
		var pool: Array = spec.cells
		var start := ("%d|%s|%d" % [seed_value, scenario_id, i]).hash() % pool.size()
		for k in pool.size():
			var cell := _cell(pool[(start + k) % pool.size()])
			if not used.has(cell):
				e.pos = cell
				used[cell] = true
				break
		e.leader = tpl == "bandit_leader" or bool(content.combat_unit(tpl).get("leader", false))
		b.units.append(e)
	if game_state != null:
		b.items["medicine"] = game_state.resources.get_amount("medicine")
	b.start()
	return b


static func _cell(a: Variant) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


static func _hero(content: Object, gs: RefCounted) -> RefCounted:
	var u := CombatUnit.new()
	u.id = HERO_ID
	u.team = "player"
	u.name_key = "combat.hero"
	var body := 5
	var power := 5
	var agility := 5
	var insight := 5
	var spirit := 5
	if gs != null:
		body = gs.player.effective_attr("body")
		power = gs.player.effective_attr("power")
		agility = gs.player.effective_attr("agility")
		insight = gs.player.effective_attr("insight")
		spirit = gs.player.effective_attr("spirit")
		u.techniques = gs.player.techniques.duplicate()
		u.tech_levels = TechniqueLevels.levels_of(gs)
	var bonus := hero_bonus(content, gs)
	body += int(bonus.get("body", 0))
	power += int(bonus.get("power", 0))
	agility += int(bonus.get("agility", 0))
	spirit += int(bonus.get("spirit", 0))
	insight += int(bonus.get("tp", 0))
	u.max_hp = 30 + body * 4 + int(bonus.get("hp", 0))
	u.body = body
	u.power = power
	u.agility = agility
	u.spirit = spirit
	u.tp = insight
	u.max_resolve = 6 + spirit + int(bonus.get("resolve", 0))
	if gs != null:
		u.max_hp += RealmRules.hp_bonus(gs, content)
		u.tp += RealmRules.tp_bonus(gs, content)
	u.hp = u.max_hp
	u.resolve = u.max_resolve
	return u


## Skill-tree and gear bonuses of the hero: {stat: amount} (stats: hp, body, power, agility, spirit, tp, resolve).
static func hero_bonus(content: Object, gs: RefCounted) -> Dictionary:
	var out := {}
	if gs == null:
		return out
	for src in [SkillTree.stat_bonus(gs, content), EquipmentRules.bonus(gs, content)]:
		for k in src:
			out[k] = int(out.get(k, 0)) + int(src[k])
	return out


## The bond ability is only available once the bond is strong enough (BOND_MIN).
static func _companion(content: Object, cid: String, bond_ready: bool) -> RefCounted:
	var d: Dictionary = content.companion(cid)
	if d.is_empty():
		return null
	var s: Dictionary = d.stats
	var u := CombatUnit.new()
	u.id = cid
	u.team = "player"
	u.name_key = str(d.name_key)
	u.body = int(s.body)
	u.power = int(s.power)
	u.agility = int(s.agility)
	u.spirit = int(s.spirit)
	u.tp = int(s.insight)
	u.max_hp = 24 + u.body * 3
	u.hp = u.max_hp
	u.max_resolve = 6 + u.spirit
	u.resolve = u.max_resolve
	u.techniques = (d.get("battle_abilities", []) as Array).duplicate()
	if bond_ready:
		var bond := str(d.get("relationship_ability", ""))
		if bond != "" and not content.combat_tech(bond).is_empty():
			u.techniques.append(bond)
	return u


static func _from_template(content: Object, tpl: String, id: String, team: String) -> RefCounted:
	var d: Dictionary = content.combat_unit(tpl)
	var s: Dictionary = d.stats
	var u := CombatUnit.new()
	u.id = id
	u.team = team
	u.template = tpl
	u.name_key = "combat.unit." + tpl
	u.max_hp = int(s.hp)
	u.hp = u.max_hp
	u.body = int(s.body)
	u.power = int(s.power)
	u.agility = int(s.agility)
	u.spirit = int(s.spirit)
	u.tp = int(s.spirit)
	u.max_resolve = 6 + u.spirit
	u.resolve = u.max_resolve
	u.techniques = (d.get("techniques", []) as Array).duplicate()
	return u


## Rebuilds a battle from a saved snapshot (Battle.to_dict plus ctx). Null if the snapshot is unusable.
static func rebuild(content: Object, snap: Dictionary) -> RefCounted:
	if snap.is_empty() or content.scenario(str(snap.get("scenario", ""))).is_empty():
		return null
	var b := Battle.from_dict(content, snap)
	var ids := {}
	for u in b.units:
		ids[u.id] = true
		if not CombatGrid.in_bounds(u.pos):
			return null
	if b.units.is_empty() or b.order.any(func(id: String) -> bool: return not ids.has(id)):
		return null
	return b
