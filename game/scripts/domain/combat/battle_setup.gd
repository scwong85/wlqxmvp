extends RefCounted
## Builds a Battle from a scenario, a seed and (optionally) the hero's saved state.
## The seed only decides which candidate cell each enemy starts on; nothing in a fight is random.

const Battle = preload("res://scripts/domain/combat/battle.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")

const HERO_ID := "hero"


static func build(content: Object, scenario_id: String, seed_value: int, game_state: RefCounted = null, party_ids: Array = []) -> RefCounted:
	var sc: Dictionary = content.scenario(scenario_id)
	if sc.is_empty():
		return null
	var b := Battle.new(content)
	b.scenario_id = scenario_id
	b.seed_value = seed_value
	b.max_rounds = int(sc.max_rounds)
	b.objective = (sc.objective as Dictionary).duplicate(true)
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
		var c := _companion(content, str(cid))
		if c == null:
			continue
		c.pos = _cell(cells[slot])
		b.units.append(c)
		used[c.pos] = true
		slot += 1
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
	u.max_hp = 30 + body * 4
	u.body = body
	u.power = power
	u.agility = agility
	u.spirit = spirit
	u.tp = insight
	u.max_resolve = 6 + spirit
	u.hp = u.max_hp
	u.resolve = u.max_resolve
	return u


static func _companion(content: Object, cid: String) -> RefCounted:
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
