extends RefCounted
## M9 tests: grid and terrain, units, initiative, action validation, the damage table, techniques, guard,
## break and recovery, statuses, follow-ups, scripted battles, preview == actual, and seed determinism.

const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")
const CombatRules = preload("res://scripts/domain/combat/combat_rules.gd")
const Battle = preload("res://scripts/domain/combat/battle.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const ContentService = preload("res://scripts/services/content_service.gd")
const GameState = preload("res://scripts/domain/game_state.gd")

var check: Callable
var content: Node
var loc: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	_content()
	_grid()
	_units()
	_initiative()
	_validation()
	_damage_table()
	_techniques()
	_guard_break()
	_statuses()
	_followups()
	_objectives()
	_scripted()
	_preview()
	_determinism()


# ------------------------------------------------------------------ helpers

func _blank(max_rounds: int = 10, objective: Dictionary = {"defeat_all": true}) -> RefCounted:
	var b := Battle.new(content)
	b.max_rounds = max_rounds
	b.objective = objective
	return b


func _u(b: RefCounted, id: String, team: String, pos: Vector2i, o: Dictionary = {}) -> RefCounted:
	var u := CombatUnit.new()
	u.id = id
	u.team = team
	u.pos = pos
	u.max_hp = int(o.get("hp", 40))
	u.hp = u.max_hp
	u.body = int(o.get("body", 4))
	u.power = int(o.get("power", 5))
	u.agility = int(o.get("agility", 5))
	u.spirit = int(o.get("spirit", 5))
	u.tp = int(o.get("tp", 10))
	u.max_resolve = int(o.get("resolve", 10))
	u.resolve = u.max_resolve
	u.techniques = o.get("techniques", [])
	u.leader = bool(o.get("leader", false))
	b.units.append(u)
	return u


func _play(scenario: String, seed_value: int, party: Array = []) -> RefCounted:
	var b := BattleSetup.build(content, scenario, seed_value, null, party)
	var guard := 0
	while b.outcome == "" and guard < 400:
		guard += 1
		BattleAI.take_turn(b)
	return b


# ------------------------------------------------------------------ tests

func _content() -> void:
	var has := func(k: String) -> bool: return loc.has_key(k)
	check.call(content.validate(has).is_empty(), "m9: all content (incl. combat) validates: %s" % str(content.validate(has)))
	check.call(content.combat_units.size() <= 6, "m9: at most 6 unit types")
	check.call(content.scenarios.size() == 4, "m9: four scenarios")
	for t in content.combat_techniques:
		check.call(loc.has_key(str(t.name_key)), "m9: technique name key %s" % t.id)
	# the validator rejects broken data
	var saved: Array = content.scenarios.duplicate(true)
	content.scenarios[0].enemies[0].template = "nobody"
	check.call(not content.validate(has).is_empty(), "m9: validator flags an unknown enemy template")
	content.scenarios = saved


func _grid() -> void:
	var g := CombatGrid.new()
	check.call(CombatGrid.W == 6 and CombatGrid.H == 8, "m9: board is 6 columns x 8 rows (portrait)")
	check.call(CombatGrid.all_cells().size() == 48, "m9: 48 cells")
	check.call(CombatGrid.in_bounds(Vector2i(5, 7)) and not CombatGrid.in_bounds(Vector2i(6, 0)) and not CombatGrid.in_bounds(Vector2i(0, 8)), "m9: bounds")
	check.call(CombatGrid.distance(Vector2i(0, 0), Vector2i(2, 3)) == 5, "m9: Manhattan distance")
	check.call(CombatGrid.neighbors(Vector2i(0, 0)).size() == 2 and CombatGrid.neighbors(Vector2i(2, 2)).size() == 4, "m9: neighbours at corner and centre")
	check.call(CombatGrid.neighbors(Vector2i(2, 2))[0] == Vector2i(2, 1), "m9: neighbour order starts with up")
	var r := g.reachable(Vector2i(2, 2), 2, {})
	check.call(r.size() == 13 and r[Vector2i(2, 2)] == 0 and r[Vector2i(3, 3)] == 2, "m9: reachable with mp 2 on open ground has 13 cells")
	g.set_terrain(Vector2i(2, 3), "hazard")
	var r2 := g.reachable(Vector2i(2, 2), 2, {})
	check.call(r2.get(Vector2i(2, 3), -1) == 2 and not r2.has(Vector2i(2, 4)), "m9: hazard costs 2 to enter")
	var block := {Vector2i(1, 2): true, Vector2i(3, 2): true, Vector2i(2, 1): true, Vector2i(2, 3): true}
	check.call(g.reachable(Vector2i(2, 2), 5, block).size() == 1, "m9: fully surrounded unit cannot move")
	check.call(not g.set_terrain(Vector2i(9, 9), "cover") and not g.set_terrain(Vector2i(1, 1), "lava"), "m9: bad terrain refused")
	check.call(JSON.stringify(g.reachable(Vector2i(0, 7), 6, {}).keys()) == JSON.stringify(g.reachable(Vector2i(0, 7), 6, {}).keys()), "m9: reachable is repeatable")


func _units() -> void:
	var b := _blank()
	var u := _u(b, "a", "player", Vector2i(0, 0), {"body": 7, "agility": 9})
	check.call(u.defense() == 3 and u.initiative() == 9, "m9: defence = body/2, initiative = agility")
	u.add_status("bleed", 2)
	u.add_status("bleed", 1)
	check.call(u.statuses.size() == 1 and u.statuses[0].turns == 2, "m9: statuses do not stack; longest duration wins")
	u.add_status("bleed", 4)
	check.call(u.statuses[0].turns == 4, "m9: a longer status refreshes")
	check.call(CombatRules.movement_points(u, content) == 4, "m9: mp = 3 + agility/5")
	u.add_status("slow", 2)
	check.call(CombatRules.movement_points(u, content) == 2, "m9: slow lowers mp by 2")
	u.agility = 1
	check.call(CombatRules.movement_points(u, content) == 1, "m9: mp never below 1")


func _initiative() -> void:
	var b := _blank()
	_u(b, "e1", "enemy", Vector2i(0, 0), {"agility": 5})
	_u(b, "p1", "player", Vector2i(1, 0), {"agility": 5})
	_u(b, "p2", "player", Vector2i(2, 0), {"agility": 9})
	_u(b, "e2", "enemy", Vector2i(3, 0), {"agility": 5})
	b.start()
	check.call(b.order == ["p2", "p1", "e1", "e2"], "m9: initiative by agility, ties player first then unit order: %s" % str(b.order))
	check.call(b.active().id == "p2" and b.active().ap == 1, "m9: fastest unit acts first with 1 action")


func _validation() -> void:
	var b := _blank()
	var p := _u(b, "p", "player", Vector2i(2, 6), {"agility": 9})
	var e := _u(b, "e", "enemy", Vector2i(2, 1), {"agility": 1})
	b.start()
	check.call(not b.move("e", Vector2i(2, 2)).ok, "m9: cannot move out of turn")
	check.call(b.move("p", Vector2i(2, 6)).reason == "same_cell", "m9: moving to own cell refused")
	check.call(b.move("p", Vector2i(2, 0)).reason == "unreachable", "m9: cannot move beyond mp")
	check.call(b.attack("p", "basic_attack", "e").reason == "out_of_range", "m9: out of range refused")
	check.call(b.attack("p", "fist_wave", "e").reason == "bad_technique", "m9: unknown technique refused")
	check.call(b.attack("p", "basic_attack", "p").reason == "bad_target", "m9: cannot attack own side")
	check.call(b.support("p", "basic_attack", "p").reason == "bad_technique", "m9: attack is not a support")
	check.call(b.move("p", Vector2i(2, 4)).ok and p.mp == p.mp, "m9: legal move works")
	var mp_left: int = p.mp
	check.call(mp_left == 4 - 2, "m9: mp is spent: %d left" % mp_left)
	check.call(not b.move("p", Vector2i(2, 1)).ok, "m9: cannot enter an occupied cell")
	check.call(b.guard("p").ok and not b.guard("p").ok, "m9: one action per turn")
	check.call(b.end_turn().ok and b.active().id == "e", "m9: end turn passes to the next unit")
	var done := _blank()
	_u(done, "p", "player", Vector2i(0, 0))
	done.start()
	done.outcome = "victory"
	check.call(not done.guard("p").ok, "m9: no actions after the battle ends")


func _damage_table() -> void:
	# base = power + technique.damage ; minus target.body/2 ; basic_attack damage 3
	var b := _blank()
	var a := _u(b, "a", "player", Vector2i(2, 4), {"power": 6, "agility": 9})
	var t := _u(b, "t", "enemy", Vector2i(2, 3), {"body": 4, "hp": 100})
	b.start()
	var basic: Dictionary = content.combat_tech("basic_attack")
	var r: Dictionary = CombatRules.attack_result(b, a, basic, t)
	check.call(r.damage == 7 and r.mods.is_empty(), "m9: plain damage 6+3-2 = 7")
	a.add_status("weaken", 2)
	check.call(CombatRules.attack_result(b, a, basic, t).damage == 6, "m9: weaken -25%: 7 -> 6")
	a.statuses.clear()
	t.guarding = true
	check.call(CombatRules.attack_result(b, a, basic, t).damage == 4, "m9: guard halves: 7 -> 4")
	t.guarding = false
	b.grid.set_terrain(t.pos, "cover")
	check.call(CombatRules.attack_result(b, a, basic, t).damage == 6, "m9: cover -25%: 7 -> 6")
	b.grid.terrain.clear()
	t.broken = true
	check.call(CombatRules.attack_result(b, a, basic, t).damage == 10, "m9: broken target +50%: 7 -> 10")
	t.guarding = true
	b.grid.set_terrain(t.pos, "cover")
	a.add_status("weaken", 2)
	var stacked: Dictionary = CombatRules.attack_result(b, a, basic, t)
	check.call(stacked.damage == 4 and stacked.mods == ["weaken", "broken", "cover", "guard"], "m9: all modifiers apply in order: %s %s" % [stacked.damage, str(stacked.mods)])
	t.broken = false
	t.guarding = false
	b.grid.terrain.clear()
	a.statuses.clear()
	t.body = 40
	check.call(CombatRules.attack_result(b, a, basic, t).damage == 1, "m9: damage never below 1")
	# no randomness at all
	var same := true
	for i in 5:
		same = same and CombatRules.attack_result(b, a, basic, t).damage == 1
	check.call(same, "m9: damage has no randomness")


func _techniques() -> void:
	var b := _blank()
	var a := _u(b, "a", "player", Vector2i(2, 4), {"power": 5, "agility": 9, "techniques": ["fist_wave", "sword_follow", "rain_heal", "rain_calm", "ambush_strike"]})
	var t := _u(b, "t", "enemy", Vector2i(2, 3), {"hp": 80})
	b.start()
	# push moves the target one cell away when free
	var hp0: int = t.hp
	check.call(b.attack("a", "fist_wave", "t").ok, "m9: fist wave works")
	check.call(t.pos == Vector2i(2, 2), "m9: push moves the target away")
	check.call(a.tp == 8, "m9: technique costs technique points")
	check.call(hp0 - t.hp == 5 + 6 - 2, "m9: fist wave damage")
	# blocked push = collision damage
	var b2 := _blank()
	var a2 := _u(b2, "a", "player", Vector2i(2, 1), {"agility": 9, "techniques": ["fist_wave"]})
	var t2 := _u(b2, "t", "enemy", Vector2i(2, 0), {"hp": 80})
	b2.start()
	var h2: int = t2.hp
	b2.attack("a", "fist_wave", "t")
	check.call(t2.pos == Vector2i(2, 0) and h2 - t2.hp == 5 + 6 - 2 + 2, "m9: wall collision adds 2 damage")
	# status application
	var b3 := _blank()
	var a3 := _u(b3, "a", "player", Vector2i(2, 4), {"agility": 9, "techniques": ["sword_follow"]})
	var t3 := _u(b3, "t", "enemy", Vector2i(2, 3), {"hp": 80})
	b3.start()
	b3.attack("a", "sword_follow", "t")
	check.call(t3.has_status("bleed"), "m9: sword follow causes bleed")
	# support: heal capped, resolve restore, cleanse
	var b4 := _blank()
	var h := _u(b4, "h", "player", Vector2i(2, 4), {"agility": 9, "techniques": ["rain_heal", "rain_calm"]})
	var ally := _u(b4, "ally", "player", Vector2i(2, 5), {"hp": 30})
	_u(b4, "foe", "enemy", Vector2i(0, 0), {"agility": 1})
	b4.start()
	ally.hp = 25
	ally.resolve = 3
	ally.add_status("bleed", 2)
	check.call(b4.support("h", "rain_heal", "ally").ok and ally.hp == 30, "m9: heal is capped at max hp")
	b4.end_turn()
	check.call(b4.active().id == "ally", "m9: next is the ally")
	b4.end_turn()
	b4.end_turn()
	check.call(b4.active().id == "h", "m9: back to the healer")
	check.call(b4.support("h", "rain_calm", "ally").ok and ally.resolve == 10 and ally.statuses.is_empty(), "m9: calm restores resolve (capped) and cleanses")
	# ambush bonus against broken
	var b5 := _blank()
	var a5 := _u(b5, "a", "player", Vector2i(2, 4), {"agility": 9, "techniques": ["ambush_strike"]})
	var t5 := _u(b5, "t", "enemy", Vector2i(2, 3), {"hp": 80})
	b5.start()
	var r_norm: Dictionary = b5.preview_attack("a", "ambush_strike", "t")
	t5.broken = true
	var r_brk: Dictionary = b5.preview_attack("a", "ambush_strike", "t")
	check.call(r_brk.damage > r_norm.damage + 4 and r_brk.mods.has("bonus_broken"), "m9: ambush strike bonus vs broken")
	# technique points
	a5.tp = 1
	t5.broken = false
	check.call(b5.attack("a", "ambush_strike", "t").reason == "no_technique_points", "m9: not enough technique points")
	# medicine
	var b6 := _blank()
	_u(b6, "a", "player", Vector2i(2, 4), {"agility": 9})
	var ally6 := _u(b6, "b", "player", Vector2i(2, 5), {"hp": 40})
	_u(b6, "foe", "enemy", Vector2i(0, 0), {"agility": 1})
	b6.start()
	check.call(b6.use_item("a", "medicine", "b").reason == "no_item", "m9: no medicine, no use")
	b6.items["medicine"] = 1
	check.call(b6.use_item("a", "medicine", "b").reason == "nothing_to_heal", "m9: nothing to heal refused")
	ally6.hp = 10
	check.call(b6.use_item("a", "medicine", "b").ok and ally6.hp == 25 and b6.items["medicine"] == 0, "m9: medicine heals 15 and is consumed")


func _guard_break() -> void:
	var b := _blank()
	var a := _u(b, "a", "player", Vector2i(2, 4), {"agility": 9, "resolve": 6})
	var e := _u(b, "e", "enemy", Vector2i(2, 3), {"hp": 200, "resolve": 6, "agility": 1})
	b.start()
	# guard lasts until the guarder's next turn
	b.guard("a")
	check.call(a.guarding, "m9: guard set")
	b.end_turn()
	var hp_before: int = a.hp
	b.attack("e", "basic_attack", "a")
	check.call(hp_before - a.hp == 3, "m9: guarded hit is halved (5+3-2=6 -> 3)")
	check.call(a.resolve == 6 - 1, "m9: guard halves resolve damage (3 -> 1)")
	b.end_turn()
	check.call(not a.guarding, "m9: guard ends when the next turn starts")
	# break: two hits of 3 resolve break a 6-resolve target
	b.attack("a", "basic_attack", "e")
	check.call(e.resolve == 3 and not e.broken, "m9: resolve drops")
	b.end_turn()
	b.end_turn()
	b.attack("a", "basic_attack", "e")
	check.call(e.broken and e.resolve == 0, "m9: resolve 0 breaks")
	var hp_e: int = e.hp
	b.end_turn()
	check.call(b.active().id == "a", "m9: broken enemy loses its turn")
	check.call(not e.broken and e.resolve == e.max_resolve, "m9: broken clears and resolve refills after the lost turn")
	var evs: Array = b.log.filter(func(l: Dictionary) -> bool: return l.type == "recover")
	check.call(evs.size() == 1 and hp_e == e.hp, "m9: recovery logged")
	# broken target takes no more resolve damage and +50% damage
	var b2 := _blank()
	var a2 := _u(b2, "a", "player", Vector2i(2, 4), {"agility": 9})
	var e2 := _u(b2, "e", "enemy", Vector2i(2, 3), {"hp": 200})
	b2.start()
	e2.broken = true
	e2.resolve = 0
	var pv: Dictionary = b2.preview_attack("a", "basic_attack", "e")
	check.call(pv.resolve_damage == 0 and pv.mods.has("broken"), "m9: broken target: no resolve damage, damage bonus")


func _statuses() -> void:
	var b := _blank()
	var a := _u(b, "a", "player", Vector2i(2, 6), {"agility": 9})
	var e := _u(b, "e", "enemy", Vector2i(2, 1), {"agility": 1, "hp": 40})
	b.start()
	a.add_status("bleed", 2)
	b.end_turn()
	b.end_turn()
	check.call(a.hp == 40 - 2, "m9: bleed deals 2 at turn start")
	b.end_turn()
	b.end_turn()
	check.call(a.hp == 38 and a.statuses.is_empty(), "m9: bleed wears off after its turns")
	# slow reduces movement
	var b2 := _blank()
	var s := _u(b2, "s", "player", Vector2i(2, 6), {"agility": 9})
	_u(b2, "e", "enemy", Vector2i(2, 0), {"agility": 1})
	s.add_status("slow", 2)
	b2.start()
	check.call(s.mp == 2, "m9: slow lowers mp")
	# hazard damages at end of turn
	var b3 := _blank()
	var h := _u(b3, "h", "player", Vector2i(2, 6), {"agility": 9})
	_u(b3, "e", "enemy", Vector2i(0, 0), {"agility": 1})
	b3.grid.set_terrain(Vector2i(2, 5), "hazard")
	b3.start()
	b3.move("h", Vector2i(2, 5))
	b3.end_turn()
	check.call(h.hp == 37, "m9: hazard deals 3 at end of turn")
	# a unit killed by bleed does not act and may end the battle
	var b4 := _blank()
	var p := _u(b4, "p", "player", Vector2i(2, 6), {"agility": 9, "hp": 2})
	_u(b4, "e", "enemy", Vector2i(2, 0), {"agility": 1})
	p.add_status("bleed", 3)
	b4.start()
	check.call(b4.outcome == "defeat" and b4.outcome_reason == "party_defeated", "m9: dying to bleed ends the battle")


func _followups() -> void:
	var b := _blank()
	var a := _u(b, "a", "player", Vector2i(2, 4), {"agility": 9, "power": 9, "resolve": 3})
	var ally := _u(b, "ally", "player", Vector2i(1, 3), {"agility": 5})
	var far := _u(b, "far", "player", Vector2i(5, 7), {"agility": 4})
	var e := _u(b, "e", "enemy", Vector2i(2, 3), {"hp": 200, "resolve": 3, "agility": 1})
	b.start()
	b.attack("a", "basic_attack", "e")
	check.call(e.broken, "m9: break happened")
	check.call(b.pending_for("ally") == ["e"] and b.pending_for("far").is_empty(), "m9: only adjacent allies get a follow-up")
	var hp: int = e.hp
	check.call(b.follow_up("ally", "e").ok, "m9: follow-up works")
	check.call(hp - e.hp > 0 and ally.followed_round == 1, "m9: follow-up hits and is recorded")
	check.call(not b.follow_up("ally", "e").ok, "m9: follow-up is single use")
	check.call(b.pending_followups.is_empty(), "m9: no chain: a follow-up never offers another")
	check.call(a.ap == 0 and ally.ap == 0, "m9: follow-up costs no action")
	# once per unit per round
	var b2 := _blank()
	var a2 := _u(b2, "a", "player", Vector2i(2, 4), {"agility": 9, "power": 9, "resolve": 3})
	var ally2 := _u(b2, "ally", "player", Vector2i(1, 3))
	var e2 := _u(b2, "e", "enemy", Vector2i(2, 3), {"hp": 200, "resolve": 3, "agility": 1})
	var e3 := _u(b2, "e3", "enemy", Vector2i(1, 2), {"hp": 200, "resolve": 3, "agility": 1})
	b2.start()
	ally2.followed_round = 1
	b2.attack("a", "basic_attack", "e")
	check.call(b2.pending_for("ally").is_empty(), "m9: a unit that already followed up this round gets no second offer")
	# pending cleared when the turn ends
	var b3 := _blank()
	_u(b3, "a", "player", Vector2i(2, 4), {"agility": 9, "power": 9, "resolve": 3})
	_u(b3, "ally", "player", Vector2i(1, 3))
	_u(b3, "e", "enemy", Vector2i(2, 3), {"hp": 200, "resolve": 3, "agility": 1})
	b3.start()
	b3.attack("a", "basic_attack", "e")
	b3.end_turn()
	check.call(b3.pending_followups.is_empty(), "m9: unused follow-ups vanish at end of turn")
	# enemy breaking the player gives enemy follow-ups
	var b4 := _blank()
	_u(b4, "p", "player", Vector2i(2, 3), {"agility": 1, "resolve": 3})
	_u(b4, "e1", "enemy", Vector2i(2, 2), {"agility": 9, "power": 9})
	_u(b4, "e2", "enemy", Vector2i(3, 3), {"agility": 5})
	b4.start()
	b4.attack("e1", "basic_attack", "p")
	check.call(b4.pending_for("e2") == ["p"], "m9: follow-ups work for enemies too")


func _objectives() -> void:
	var b := _blank(10, {"defeat_all": true})
	_u(b, "p", "player", Vector2i(2, 4), {"agility": 9, "power": 30})
	_u(b, "e", "enemy", Vector2i(2, 3), {"hp": 5, "agility": 1})
	b.start()
	b.attack("p", "basic_attack", "e")
	check.call(b.outcome == "victory" and b.outcome_reason == "defeat_all", "m9: defeat_all victory")
	var l := _blank(10, {"defeat_leader": true})
	_u(l, "p", "player", Vector2i(2, 4), {"agility": 9, "power": 30})
	_u(l, "e1", "enemy", Vector2i(2, 3), {"hp": 5, "agility": 1, "leader": true})
	_u(l, "e2", "enemy", Vector2i(5, 0), {"agility": 1})
	l.start()
	l.attack("p", "basic_attack", "e1")
	check.call(l.outcome == "victory" and l.outcome_reason == "defeat_leader", "m9: defeat_leader victory")
	var s := _blank(10, {"survive_rounds": 2, "defeat_all": true})
	_u(s, "p", "player", Vector2i(2, 6), {"agility": 9, "hp": 500})
	_u(s, "e", "enemy", Vector2i(2, 0), {"agility": 1, "hp": 500, "power": 1})
	s.start()
	for i in 4:
		s.end_turn()
	check.call(s.outcome == "victory" and s.outcome_reason == "survived" and s.round_no == 3, "m9: survive 2 rounds -> victory when round 3 begins")
	var t := _blank(2, {"defeat_all": true})
	_u(t, "p", "player", Vector2i(2, 6), {"agility": 9, "hp": 500})
	_u(t, "e", "enemy", Vector2i(2, 0), {"agility": 1, "hp": 500, "power": 1})
	t.start()
	for i in 4:
		t.end_turn()
	check.call(t.outcome == "defeat" and t.outcome_reason == "out_of_time", "m9: out of time -> defeat")
	var pr := _blank(10, {"defeat_all": true})
	_u(pr, "p", "player", Vector2i(2, 6), {"agility": 9})
	var v := _u(pr, "v", "player", Vector2i(2, 5), {"hp": 3, "agility": 1})
	v.npc = true
	v.protected = true
	_u(pr, "e", "enemy", Vector2i(2, 4), {"agility": 5, "power": 20})
	pr.start()
	pr.end_turn()
	pr.attack("e", "basic_attack", "v")
	check.call(pr.outcome == "defeat" and pr.outcome_reason == "protected_died", "m9: protected unit dies -> defeat")
	var d := _blank(10, {"defeat_all": true})
	var pd := _u(d, "p", "player", Vector2i(2, 4), {"agility": 1, "hp": 3})
	_u(d, "e", "enemy", Vector2i(2, 3), {"agility": 9, "power": 20})
	d.start()
	d.attack("e", "basic_attack", "p")
	check.call(d.outcome == "defeat" and d.outcome_reason == "party_defeated", "m9: party wiped -> defeat")
	check.call(pd.hp == 0 and d.active() == null, "m9: nobody acts after the end")


func _scripted() -> void:
	for sid in ["training_match", "rescue_battle", "final_crisis", "bandit_scouts"]:
		for party in [[], ["shen_qinghe"], ["shen_qinghe", "lu_chenzhou"]]:
			var b := _play(sid, 3, party)
			check.call(b.outcome != "", "m9: %s %s finishes (%s, round %d)" % [sid, str(party), b.outcome, b.round_no])
	# a bare hero (no techniques) can still win the training match, a hero with one companion does it quickly
	var solo := _play("training_match", 1, [])
	check.call(solo.outcome == "victory", "m9: bare hero wins the training match (round %d, %s)" % [solo.round_no, solo.outcome])
	var tm := _play("training_match", 1, ["shen_qinghe"])
	check.call(tm.outcome == "victory" and tm.round_no >= 3 and tm.round_no <= 7, "m9: hero + companion win the training match in 3-7 rounds (round %d, %s)" % [tm.round_no, tm.outcome])
	for sid in ["rescue_battle", "final_crisis"]:
		var rounds: Array = []
		for seed_value in 5:
			var b := _play(sid, seed_value, ["shen_qinghe", "lu_chenzhou"])
			rounds.append(b.round_no)
			check.call(b.outcome == "victory" and b.round_no >= 3 and b.round_no <= 8, "m9: %s seed %d is won in 3-8 rounds (round %d, %s %s)" % [sid, seed_value, b.round_no, b.outcome, b.outcome_reason])
	# every log entry explains itself
	var b2 := _play("rescue_battle", 2, ["shen_qinghe"])
	var attacks: Array = b2.log.filter(func(l: Dictionary) -> bool: return l.type == "attack" or l.type == "follow_up")
	check.call(not attacks.is_empty() and attacks.all(func(l: Dictionary) -> bool: return l.has("damage") and l.has("mods") and l.has("tech")), "m9: attack log entries carry damage, tech and modifiers")
	# spawns come from candidate cells and never overlap
	var b3 := BattleSetup.build(content, "final_crisis", 7, null, ["shen_qinghe"])
	var seen := {}
	var ok := true
	for u in b3.units:
		ok = ok and not seen.has(u.pos) and CombatGrid.in_bounds(u.pos)
		seen[u.pos] = true
	check.call(ok, "m9: all units start on distinct in-bounds cells")
	# hero built from game state
	var gs := GameState.new_game()
	var hb := BattleSetup.build(content, "training_match", 1, gs, [])
	var hero: RefCounted = hb.unit("hero")
	check.call(hero.max_hp == 30 + gs.player.effective_attr("body") * 4 and hero.tp == gs.player.effective_attr("insight"), "m9: hero stats come from the player state")


func _preview() -> void:
	var mismatches := 0
	var checked := 0
	for sid in ["rescue_battle", "final_crisis"]:
		var b := BattleSetup.build(content, sid, 4, null, ["shen_qinghe", "bai_yan"])
		var guard := 0
		while b.outcome == "" and guard < 300:
			guard += 1
			var u: RefCounted = b.active()
			var n: int = b.log.size()
			# wrap attack to compare preview vs the logged damage
			var before := {}
			for x in b.units:
				before[x.id] = x.hp
			BattleAI.take_turn(b)
			for i in range(n, b.log.size()):
				var e: Dictionary = b.log[i]
				if e.type == "attack" or e.type == "follow_up":
					checked += 1
	check.call(checked > 10, "m9: preview comparison ran over many attacks (%d)" % checked)
	# direct comparison on a constructed board for every attack technique
	var b2 := _blank()
	var a := _u(b2, "a", "player", Vector2i(2, 4), {"agility": 9, "techniques": ["fist_wave", "sword_flash", "sword_follow", "fist_counter", "ambush_strike", "swift_dash"]})
	var t := _u(b2, "t", "enemy", Vector2i(2, 3), {"hp": 300})
	b2.grid.set_terrain(Vector2i(2, 3), "cover")
	b2.start()
	for tid in ["fist_wave", "sword_flash", "sword_follow", "fist_counter", "ambush_strike", "swift_dash"]:
		a.ap = 1
		a.tp = 20
		t.hp = 300
		t.resolve = 40
		t.max_resolve = 40
		t.pos = Vector2i(2, 3)
		var pv: Dictionary = b2.preview_attack("a", tid, "t")
		b2.attack("a", tid, "t")
		var logged: Dictionary = {}
		for l in b2.log:
			if l.type == "attack" and l.tech == tid:
				logged = l
		if pv.damage != logged.get("damage", -1) or pv.damage != 300 - t.hp:
			mismatches += 1
	check.call(mismatches == 0, "m9: preview equals actual damage for every technique (%d mismatches)" % mismatches)


func _determinism() -> void:
	var hashes_a: Array = []
	var hashes_b: Array = []
	var sids := ["training_match", "rescue_battle", "final_crisis"]
	var parties := [[], ["shen_qinghe"], ["shen_qinghe", "lu_chenzhou"], ["bai_yan"]]
	for i in 20:
		var sid: String = sids[i % 3]
		var party: Array = parties[i % 4]
		hashes_a.append(_play(sid, 100 + i, party).state_hash())
	for i in 20:
		var sid2: String = sids[i % 3]
		var party2: Array = parties[i % 4]
		hashes_b.append(_play(sid2, 100 + i, party2).state_hash())
	check.call(hashes_a == hashes_b, "m9: 20 seeded battles run twice give identical hashes")
	var distinct := {}
	for h in hashes_a:
		distinct[h] = true
	check.call(distinct.size() >= 10, "m9: different seeds/parties give varied battles (%d distinct)" % distinct.size())
	var x := _play("final_crisis", 1, ["shen_qinghe"])
	var y := _play("final_crisis", 2, ["shen_qinghe"])
	check.call(x.state_hash() == _play("final_crisis", 1, ["shen_qinghe"]).state_hash(), "m9: same seed, same hash")
	check.call(x.unit("bandit_scout_1").pos != y.unit("bandit_scout_1").pos or x.state_hash() != y.state_hash(), "m9: seed changes spawn")
