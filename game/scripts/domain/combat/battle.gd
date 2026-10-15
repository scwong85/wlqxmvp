extends RefCounted
## One battle: turn order, actions, statuses, objectives and the explainable log.
## No engine nodes and no randomness. Every action returns {ok, reason} and, when it works, changes the state
## and appends events to `log`. The log records the reason for every number (modifiers, sources).

const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")
const CombatRules = preload("res://scripts/domain/combat/combat_rules.gd")

const HAZARD_DAMAGE := 3
const BLEED_DAMAGE := 2

var content: Object
var grid: RefCounted = CombatGrid.new()
var units: Array = []             # CombatUnit, in a fixed creation order
var order: Array = []             # ids acting this round
var turn_index: int = 0
var round_no: int = 1
var scenario_id: String = ""
var seed_value: int = 0
var objective: Dictionary = {}
var max_rounds: int = 10
var items: Dictionary = {}        # item resource -> count
var outcome: String = ""          # "", "victory", "defeat"
var outcome_reason: String = ""
var pending_followups: Array = [] # [{unit, target}]
var log: Array = []


func _init(content_ref: Object = null) -> void:
	content = content_ref


# ---------------------------------------------------------------- queries

func unit(id: String) -> RefCounted:
	for u in units:
		if u.id == id:
			return u
	return null


func active() -> RefCounted:
	if outcome != "" or turn_index >= order.size():
		return null
	return unit(str(order[turn_index]))


func alive_units(team: String = "") -> Array:
	var out: Array = []
	for u in units:
		if u.alive() and (team == "" or u.team == team):
			out.append(u)
	return out


func occupied() -> Dictionary:
	var d := {}
	for u in units:
		if u.alive():
			d[u.pos] = u.id
	return d


func unit_at(p: Vector2i) -> RefCounted:
	for u in units:
		if u.alive() and u.pos == p:
			return u
	return null


func technique_ids(u: RefCounted) -> Array:
	var out: Array = ["basic_attack"]
	for t in u.techniques:
		if not out.has(t):
			out.append(t)
	return out


func _tech_for(u: RefCounted, tech_id: String) -> Dictionary:
	if not technique_ids(u).has(tech_id):
		return {}
	return content.combat_tech(tech_id)


## Cells the active unit can walk to right now: {cell: cost}.
func move_options(u: RefCounted) -> Dictionary:
	var occ := occupied()
	occ.erase(u.pos)
	return grid.reachable(u.pos, u.mp, occ)


# ---------------------------------------------------------------- setup / round flow

## Called once after the units are placed.
func start() -> void:
	round_no = 1
	_emit({"type": "battle_start", "scenario": scenario_id})
	_begin_round()
	_enter_turn_loop(false)


func _begin_round() -> void:
	var live := alive_units()
	var team_rank := {"player": 0, "enemy": 1}
	var keyed: Array = []
	for i in live.size():
		var u: RefCounted = live[i]
		keyed.append({"id": u.id, "ag": u.initiative(), "team": int(team_rank.get(u.team, 2)), "i": units.find(u)})
	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.ag != b.ag:
			return a.ag > b.ag
		if a.team != b.team:
			return a.team < b.team
		return a.i < b.i)
	order = keyed.map(func(k: Dictionary) -> String: return k.id)
	turn_index = 0
	_emit({"type": "round_start", "order": order.duplicate()})


## Starts turns until a unit that can act is found (or the battle ends).
func _enter_turn_loop(advance_first: bool) -> void:
	var advance := advance_first
	var guard := 0
	while outcome == "" and guard < 500:
		guard += 1
		if advance:
			turn_index += 1
			if turn_index >= order.size():
				round_no += 1
				if _check_round_limit():
					return
				_begin_round()
		advance = true
		var u: RefCounted = active()
		if u == null:
			return
		if not u.alive():
			continue
		if _begin_turn(u):
			return
		_finish_turn(u)


## True when the unit can act this turn.
func _begin_turn(u: RefCounted) -> bool:
	u.guarding = false
	u.ap = 0
	u.mp = 0
	_emit({"type": "turn_start", "unit": u.id})
	if u.has_status("bleed"):
		_hurt(u, BLEED_DAMAGE, "bleed")
		if not u.alive() or outcome != "":
			return false
	if u.broken:
		u.broken = false
		u.resolve = u.max_resolve
		_emit({"type": "recover", "unit": u.id})
		return false
	if u.npc:
		return false
	u.ap = 1
	u.mp = CombatRules.movement_points(u, content)
	return true


func _finish_turn(u: RefCounted) -> void:
	if u.alive() and grid.terrain_at(u.pos) == "hazard":
		_hurt(u, HAZARD_DAMAGE, "hazard")
	var keep: Array = []
	for s in u.statuses:
		s.turns = int(s.turns) - 1
		if int(s.turns) > 0:
			keep.append(s)
		else:
			_emit({"type": "status_end", "unit": u.id, "status": s.id})
	u.statuses = keep
	pending_followups.clear()
	u.ap = 0
	u.mp = 0
	_emit({"type": "turn_end", "unit": u.id})


func end_turn() -> Dictionary:
	var u := active()
	if u == null:
		return _no("battle_over")
	_finish_turn(u)
	_enter_turn_loop(true)
	return _ok()


# ---------------------------------------------------------------- actions

func move(unit_id: String, cell: Vector2i) -> Dictionary:
	var u := _acting(unit_id)
	if u == null:
		return _no("not_your_turn")
	if cell == u.pos:
		return _no("same_cell")
	var options := move_options(u)
	if not options.has(cell):
		return _no("unreachable")
	var cost: int = options[cell]
	var from: Vector2i = u.pos
	u.pos = cell
	u.mp -= cost
	_emit({"type": "move", "unit": u.id, "from": [from.x, from.y], "to": [cell.x, cell.y], "cost": cost})
	return _ok()


func preview_attack(unit_id: String, tech_id: String, target_id: String) -> Dictionary:
	var u := unit(unit_id)
	var t := unit(target_id)
	if u == null or t == null:
		return _no("unknown_unit")
	var tech := _tech_for(u, tech_id)
	if tech.is_empty() or tech.get("kind", "") != "attack":
		return _no("bad_technique")
	if not t.alive() or t.team == u.team:
		return _no("bad_target")
	if CombatGrid.distance(u.pos, t.pos) > int(tech.range):
		return _no("out_of_range")
	var r := CombatRules.attack_result(self, u, tech, t)
	r["ok"] = true
	return r


func attack(unit_id: String, tech_id: String, target_id: String) -> Dictionary:
	var u := _acting(unit_id)
	if u == null:
		return _no("not_your_turn")
	if u.ap < 1:
		return _no("no_action")
	var tech := _tech_for(u, tech_id)
	if tech.is_empty():
		return _no("bad_technique")
	var cost := int(tech.get("cost", 0))
	if u.tp < cost:
		return _no("no_technique_points")
	var pv := preview_attack(unit_id, tech_id, target_id)
	if not pv.ok:
		return pv
	u.tp -= cost
	u.ap -= 1
	_do_attack(u, tech, unit(target_id), false)
	return _ok()


func preview_support(unit_id: String, tech_id: String, target_id: String) -> Dictionary:
	var u := unit(unit_id)
	var t := unit(target_id)
	if u == null or t == null:
		return _no("unknown_unit")
	var tech := _tech_for(u, tech_id)
	if tech.is_empty() or tech.get("kind", "") != "support":
		return _no("bad_technique")
	if not t.alive() or t.team != u.team:
		return _no("bad_target")
	if CombatGrid.distance(u.pos, t.pos) > int(tech.range):
		return _no("out_of_range")
	var r := CombatRules.support_result(tech, t)
	r["ok"] = true
	return r


func support(unit_id: String, tech_id: String, target_id: String) -> Dictionary:
	var u := _acting(unit_id)
	if u == null:
		return _no("not_your_turn")
	if u.ap < 1:
		return _no("no_action")
	var tech := _tech_for(u, tech_id)
	if tech.is_empty():
		return _no("bad_technique")
	var cost := int(tech.get("cost", 0))
	if u.tp < cost:
		return _no("no_technique_points")
	var pv := preview_support(unit_id, tech_id, target_id)
	if not pv.ok:
		return pv
	u.tp -= cost
	u.ap -= 1
	_apply_support(u, tech_id, tech, unit(target_id), pv)
	return _ok()


func guard(unit_id: String) -> Dictionary:
	var u := _acting(unit_id)
	if u == null:
		return _no("not_your_turn")
	if u.ap < 1:
		return _no("no_action")
	u.ap -= 1
	u.guarding = true
	_emit({"type": "guard", "unit": u.id})
	return _ok()


func use_item(unit_id: String, item_id: String, target_id: String) -> Dictionary:
	var u := _acting(unit_id)
	if u == null:
		return _no("not_your_turn")
	if u.ap < 1:
		return _no("no_action")
	var item: Dictionary = content.combat_item(item_id)
	var t := unit(target_id)
	if item.is_empty() or t == null or not t.alive() or t.team != u.team:
		return _no("bad_target")
	if int(items.get(str(item.resource), 0)) < 1:
		return _no("no_item")
	if CombatGrid.distance(u.pos, t.pos) > int(item.range):
		return _no("out_of_range")
	var healed := mini(int(item.heal), t.max_hp - t.hp)
	if healed <= 0:
		return _no("nothing_to_heal")
	items[str(item.resource)] = int(items[str(item.resource)]) - 1
	u.ap -= 1
	t.hp += healed
	_emit({"type": "item", "unit": u.id, "target": t.id, "item": item_id, "heal": healed})
	return _ok()


## Free basic attack for an ally next to a target that was just Broken. Costs no action.
func follow_up(unit_id: String, target_id: String) -> Dictionary:
	var found := -1
	for i in pending_followups.size():
		if pending_followups[i].unit == unit_id and pending_followups[i].target == target_id:
			found = i
	if found < 0:
		return _no("no_follow_up")
	var u := unit(unit_id)
	var t := unit(target_id)
	if u == null or t == null or not u.alive() or not t.alive():
		pending_followups.remove_at(found)
		return _no("bad_target")
	var tech: Dictionary = content.combat_tech("basic_attack")
	if CombatGrid.distance(u.pos, t.pos) > int(tech.range):
		pending_followups.remove_at(found)
		return _no("out_of_range")
	pending_followups.remove_at(found)
	u.followed_round = round_no
	_do_attack(u, tech, t, true)
	return _ok()


func pending_for(unit_id: String) -> Array:
	var out: Array = []
	for f in pending_followups:
		if f.unit == unit_id:
			out.append(f.target)
	return out


# ---------------------------------------------------------------- effects

func _do_attack(u: RefCounted, tech: Dictionary, t: RefCounted, is_follow_up: bool) -> void:
	var r := CombatRules.attack_result(self, u, tech, t)
	var was_broken: bool = t.broken
	_emit({"type": "follow_up" if is_follow_up else "attack", "unit": u.id, "target": t.id, "tech": str(tech.id),
			"damage": r.damage, "resolve_damage": r.resolve_damage, "mods": r.mods})
	if r.push_to != null:
		var from: Vector2i = t.pos
		t.pos = r.push_to
		_emit({"type": "push", "unit": t.id, "from": [from.x, from.y], "to": [t.pos.x, t.pos.y]})
	elif r.collision:
		_emit({"type": "collision", "unit": t.id})
	t.hp = maxi(0, t.hp - int(r.damage))
	if not was_broken:
		t.resolve = maxi(0, t.resolve - int(r.resolve_damage))
	if t.hp == 0:
		_emit({"type": "kill", "unit": t.id, "by": u.id})
		_check_outcome()
		return
	if not was_broken and t.resolve == 0:
		t.broken = true
		_emit({"type": "break", "unit": t.id, "by": u.id})
		if not is_follow_up:
			_offer_follow_ups(u, t)
	if r.status != null and t.alive():
		t.add_status(str(r.status.id), int(r.status.turns))
		_emit({"type": "status", "unit": t.id, "status": str(r.status.id), "turns": int(r.status.turns)})
	_check_outcome()


func _offer_follow_ups(attacker: RefCounted, target: RefCounted) -> void:
	for ally in units:
		if ally == attacker or not ally.alive() or ally.team != attacker.team or ally.npc:
			continue
		if ally.followed_round == round_no:
			continue
		if CombatGrid.distance(ally.pos, target.pos) <= 1:
			pending_followups.append({"unit": ally.id, "target": target.id})
			_emit({"type": "follow_up_offer", "unit": ally.id, "target": target.id})


func _apply_support(u: RefCounted, tech_id: String, tech: Dictionary, t: RefCounted, r: Dictionary) -> void:
	t.hp += int(r.heal)
	t.resolve += int(r.resolve_gain)
	if tech.get("cleanse", false):
		t.statuses.clear()
	_emit({"type": "support", "unit": u.id, "target": t.id, "tech": tech_id, "heal": r.heal,
			"resolve": r.resolve_gain, "cleansed": r.cleansed})


## Plain damage (bleed, hazard). Can kill.
func _hurt(u: RefCounted, amount: int, source: String) -> void:
	u.hp = maxi(0, u.hp - amount)
	_emit({"type": "damage", "unit": u.id, "amount": amount, "source": source})
	if u.hp == 0:
		_emit({"type": "kill", "unit": u.id, "by": source})
		_check_outcome()


# ---------------------------------------------------------------- objectives

func _check_outcome() -> void:
	if outcome != "":
		return
	for u in units:
		if u.protected and not u.alive():
			_end("defeat", "protected_died")
			return
	var any_player := false
	for u in units:
		if u.team == "player" and not u.npc and u.alive():
			any_player = true
	if not any_player:
		_end("defeat", "party_defeated")
		return
	if objective.get("defeat_all", false) and alive_units("enemy").is_empty():
		_end("victory", "defeat_all")
		return
	if objective.get("defeat_leader", false):
		var leader_alive := false
		for u in units:
			if u.leader and u.alive():
				leader_alive = true
		if not leader_alive:
			_end("victory", "defeat_leader")
			return


## Called when a new round starts. True if the battle ended.
func _check_round_limit() -> bool:
	var finished := round_no - 1
	if objective.has("survive_rounds") and finished >= int(objective.survive_rounds):
		_end("victory", "survived")
		return true
	if finished >= max_rounds:
		_end("defeat", "out_of_time")
		return true
	return false


func _end(result: String, reason: String) -> void:
	outcome = result
	outcome_reason = reason
	pending_followups.clear()
	_emit({"type": "outcome", "result": result, "reason": reason})


# ---------------------------------------------------------------- helpers

func _acting(unit_id: String) -> RefCounted:
	if outcome != "":
		return null
	var u := active()
	if u == null or u.id != unit_id or not u.alive() or u.npc:
		return null
	return u


func _ok() -> Dictionary:
	return {"ok": true, "reason": ""}


func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


func _emit(e: Dictionary) -> void:
	e["round"] = round_no
	log.append(e)


func to_dict() -> Dictionary:
	var us: Array = []
	for u in units:
		us.append(u.to_dict())
	return {"scenario": scenario_id, "seed": seed_value, "round": round_no, "turn_index": turn_index, "order": order,
			"units": us, "grid": grid.to_dict(), "items": items, "outcome": outcome, "reason": outcome_reason,
			"log": log}


## Stable fingerprint of the whole battle, including the log. Equal seeds must give equal hashes.
func state_hash() -> String:
	return str(JSON.stringify(to_dict(), "", true).hash())
