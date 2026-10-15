extends RefCounted
## M8 tests: route graph validation, gating, seeded checks, effects (clues, flags, battles, rewards),
## time passing at the end of a route, recruitment hooks, persistence, and branch coverage of Bamboo Pass.

const GameState = preload("res://scripts/domain/game_state.gd")
const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const SaveService = preload("res://scripts/services/save_service.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var loc: Node
var route: Dictionary


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	route = content.route("bamboo_pass")
	_graph()
	_validator_catches()
	_start_rules()
	_gating()
	_checks_deterministic()
	_effects()
	_route_end_time()
	_recruit_hooks()
	_persistence()
	_branch_coverage()
	_playthroughs()
	content.free()


func _g(seed_value: int = 7) -> RefCounted:
	var g := GameState.new_game(seed_value)
	g.calendar.day = 2
	RelationshipRules.refresh(g, content)
	return g


func _at(node_id: String, seed_value: int = 7) -> RefCounted:
	var g := _g(seed_value)
	g.player.stamina = 20
	g.exploration.active = true
	g.exploration.route = "bamboo_pass"
	g.exploration.node = node_id
	g.exploration.history = [node_id]
	return g


func _graph() -> void:
	var nodes: Array = route.nodes
	check.call(nodes.size() >= 6 and nodes.size() <= 10, "route: Bamboo Pass has 6-10 nodes (%d)" % nodes.size())
	check.call(content.validate(loc.has_key).is_empty(), "route: whole content set validates (%s)" % str(content.validate(loc.has_key).slice(0, 3)))
	var ends := nodes.filter(func(n: Dictionary) -> bool: return n.get("type", "") == "end")
	check.call(ends.size() == 2, "route: two distinct endings")
	var start := ExplorationSystem.node_of(route, "start")
	check.call(start.choices.size() == 3, "route: the start offers the three paths from the design")


func _validator_catches() -> void:
	var saved: Array = content.routes
	var base: Dictionary = route
	var cases := {
		"orphan": func(r: Dictionary) -> void:
			r.nodes.append({"id": "lonely", "text_key": r.nodes[0].text_key, "type": "end"}),
		"dead end": func(r: Dictionary) -> void:
			r.nodes.append({"id": "pit", "text_key": r.nodes[0].text_key, "choices": []})
			r.nodes[0].choices[0].next = "pit",
		"missing next": func(r: Dictionary) -> void:
			r.nodes[0].choices[0].next = "nowhere",
		"missing key": func(r: Dictionary) -> void:
			r.nodes[0].text_key = "exploration.nope",
		"no open choice": func(r: Dictionary) -> void:
			for c in r.nodes[0].choices:
				c["gate"] = {"attr_min": {"body": 5}},
		"bad check": func(r: Dictionary) -> void:
			r.nodes[1].choices[1].check.attr = "luck",
		"bad effect": func(r: Dictionary) -> void:
			r.nodes[2].choices[0].effects.append({"type": "clue", "id": "no_translation_clue"}),
		"loop with no exit": func(r: Dictionary) -> void:
			r.nodes.append({"id": "a", "text_key": r.nodes[0].text_key, "choices": [{"id": "x", "label_key": r.nodes[0].choices[0].label_key, "next": "b"}]})
			r.nodes.append({"id": "b", "text_key": r.nodes[0].text_key, "choices": [{"id": "y", "label_key": r.nodes[0].choices[0].label_key, "next": "a"}]})
			r.nodes[0].choices[0].next = "a",
	}
	for name in cases:
		var copy: Dictionary = base.duplicate(true)
		cases[name].call(copy)
		content.routes = [copy]
		var errs: Array[String] = content.validate(loc.has_key)
		check.call(not errs.is_empty(), "validator: catches '%s'" % name)
	content.routes = saved


func _start_rules() -> void:
	var g := _g()
	g.calendar.day = 1
	var early := ExplorationSystem.route_availability(g, route)
	check.call(not early.ok and early.reasons[0].key == "activity.blocked.day_gate", "start: not before day 2")
	g.calendar.day = 2
	g.player.stamina = 3
	check.call(not ExplorationSystem.route_availability(g, route).ok, "start: needs 4 stamina")
	g.player.stamina = 20
	var before := JSON.stringify(g.to_dict(), "", true)
	var r: Dictionary = ExplorationSystem.start(g, route, content)
	check.call(r.ok and g.exploration.active and g.exploration.node == "start" and g.player.stamina == 16, "start: pays 4 stamina and enters the start node")
	check.call(g.calendar.day == 2 and g.calendar.slot == 1, "start: no time passes until the route ends")
	check.call(not ExplorationSystem.route_availability(g, route).ok and ExplorationSystem.route_availability(g, route).reasons[0].key == "explore.blocked.active", "start: cannot begin a second route while exploring")
	var refused := ExplorationSystem.start(_g(), route, content)
	check.call(refused.ok, "start: sanity, a fresh state can start")
	var blocked := _g()
	blocked.calendar.day = 1
	var snap := JSON.stringify(blocked.to_dict(), "", true)
	ExplorationSystem.start(blocked, route, content)
	check.call(snap == JSON.stringify(blocked.to_dict(), "", true), "start: a refused start changes nothing")
	var fin := _g()
	fin.calendar.finished = true
	check.call(not ExplorationSystem.route_availability(fin, route).ok, "start: not after the week is over")
	check.call(before != "", "start: ok")


func _gating() -> void:
	var g := _at("start")
	g.player.attributes["body"] = 5
	var cs: Array = ExplorationSystem.choice_states(g, route, content)
	var ridge: Dictionary = cs.filter(func(c: Dictionary) -> bool: return c.id == "ridge")[0]
	check.call(not ridge.available and ridge.reasons[0].key == "explore.gate.attr" and ridge.reasons[0].params.need == 6, "gate: the ridge needs body 6")
	var snap := JSON.stringify(g.to_dict(), "", true)
	var refused: Dictionary = ExplorationSystem.choose(g, route, "ridge", content)
	check.call(not refused.ok and snap == JSON.stringify(g.to_dict(), "", true), "gate: a gated choice is refused and changes nothing")
	g.player.attributes["body"] = 6
	check.call(ExplorationSystem.choose(g, route, "ridge", content).ok and g.exploration.node == "ridge", "gate: opens at body 6")
	# Buffs count toward gates.
	var b := _at("start")
	b.player.add_buff("t", "body", 1, 3)
	check.call(ExplorationSystem.choose(b, route, "ridge", content).ok, "gate: a buff can open a gate")
	# Clue gate at the end gate.
	var c := _at("gate")
	var deci: Dictionary = ExplorationSystem.choice_states(c, route, content).filter(func(x: Dictionary) -> bool: return x.id == "decipher")[0]
	check.call(not deci.available and deci.reasons[0].key == "explore.gate.clues", "gate: deciphering needs two clues")
	c.exploration.add_clue("a")
	c.exploration.add_clue("b")
	check.call(ExplorationSystem.choose(c, route, "decipher", content).ok, "gate: opens with two clues")
	# Cost gate: sharing food.
	var f := _at("courier")
	f.resources.amounts["food"] = 0
	check.call(not ExplorationSystem.choose(f, route, "share_food", content).ok, "gate: sharing food needs food")
	f.resources.amounts["food"] = 1
	var r: Dictionary = ExplorationSystem.choose(f, route, "share_food", content)
	check.call(r.ok and f.resources.get_amount("food") == 0 and r.cost == [{"id": "food", "amount": 1}], "gate: the food is spent and reported")
	# Table of gate kinds on a synthetic gate.
	var gate := {"attr_min": {"insight": 9}, "bond_min": {"bai_yan": 5}, "flag": "x", "flag_not": "y", "item": {"strategy_token": 1}}
	var t := _g()
	check.call(ExplorationSystem.gate_reasons(t, gate, content).size() == 4, "gate: attribute, bond, item and flag each report a reason")
	t.player.attributes["insight"] = 9
	t.relationships.add_score("bai_yan", 5)
	t.relationships.set_flag("x")
	t.resources.add_item("strategy_token", 1)
	check.call(ExplorationSystem.gate_reasons(t, gate, content).is_empty(), "gate: all satisfied gives no reasons")
	t.relationships.set_flag("y")
	check.call(ExplorationSystem.gate_reasons(t, gate, content).size() == 1, "gate: flag_not blocks when the flag is set")


func _checks_deterministic() -> void:
	var a := _at("old_road", 11)
	var b := _at("old_road", 11)
	var ra: Dictionary = ExplorationSystem.choose(a, route, "tracks", content)
	var rb: Dictionary = ExplorationSystem.choose(b, route, "tracks", content)
	check.call(ra.grade == rb.grade and JSON.stringify(a.to_dict(), "", true) == JSON.stringify(b.to_dict(), "", true), "check: same seed gives the same outcome and state")
	var seen := {}
	for s in 100:
		var g := _at("old_road", s)
		seen[ExplorationSystem.choose(g, route, "tracks", content).grade] = true
	check.call(seen.has("success") and seen.has("failure"), "check: both outcomes occur across seeds")
	var chance: int = ExplorationSystem.choice_states(_at("old_road"), route, content).filter(func(x: Dictionary) -> bool: return x.id == "tracks")[0].chance
	check.call(chance == 48, "check: the displayed chance matches the rules (insight 5 vs 6 = 48)")


func _effects() -> void:
	# Success path of the stream: herbs and a clue.
	for s in 200:
		var g := _at("stream", s)
		var r: Dictionary = ExplorationSystem.choose(g, route, "search", content)
		if r.grade == "success":
			check.call(g.resources.get_amount("herbs") == 2 and g.exploration.clues == ["torn_letter"] and r.clues == ["torn_letter"], "effects: success gives herbs and the torn-letter clue")
			check.call(r.text_key == "exploration.bamboo_pass.stream.search.success" and r.next == "gate", "effects: the outcome text and next node are reported")
			break
	for s2 in 200:
		var f := _at("stream", s2)
		var rf: Dictionary = ExplorationSystem.choose(f, route, "search", content)
		if rf.grade == "failure":
			check.call(f.player.stamina == 18 and f.exploration.clues.is_empty(), "effects: failure costs 2 stamina and finds no clue")
			break
	# Clues are unique across repeats.
	var c := _at("lookout")
	ExplorationSystem.choose(c, route, "map_camp", content)
	c.exploration.node = "lookout"
	ExplorationSystem.choose(c, route, "talk_scholar", content)
	check.call(c.exploration.clues == ["camp_map"], "effects: the same clue is only counted once")
	check.call(c.relationships.get_score("bai_yan") == 3, "effects: bond change applies")
	# Flags and battles.
	var fl := _at("courier")
	fl.resources.amounts["food"] = 1
	ExplorationSystem.choose(fl, route, "share_food", content)
	check.call(fl.relationships.has_flag("helped_courier") and fl.relationships.get_score("lu_chenzhou") == 3, "effects: a flag is set and the bond grows")
	for s3 in 200:
		var bt := _at("camp_edge", s3)
		var rb: Dictionary = ExplorationSystem.choose(bt, route, "sneak", content)
		if rb.grade == "failure":
			check.call(bt.exploration.pending_battle == "bandit_scouts" and rb.battle == "bandit_scouts", "effects: a failed sneak triggers the scouts battle")
			break
	# Unknown effect types do nothing harmful.
	var res := {"deltas": [], "clues": [], "flags": [], "battle": ""}
	ExplorationSystem.apply_effect(_g(), {"type": "unknown", "id": "x", "amount": 1}, content, res)
	check.call(res.deltas.is_empty(), "effects: unknown types are ignored")


func _route_end_time() -> void:
	var g := _at("gate")
	g.calendar.day = 3
	var slot_before: int = g.calendar.slot
	var r: Dictionary = ExplorationSystem.choose(g, route, "pass_through", content)
	check.call(r.ended and not g.exploration.active and g.exploration.completed == ["bamboo_pass"], "end: the route completes")
	check.call((g.calendar.slot != slot_before) or g.calendar.day == 4, "end: finishing uses one slot")
	check.call(g.resources.get_amount("coins") == 23, "end: the ending node pays its reward")
	check.call(not ExplorationSystem.route_availability(g, route).ok and ExplorationSystem.route_availability(g, route).reasons.any(func(x: Dictionary) -> bool: return x.key == "explore.blocked.done"), "end: a route can only be done once")
	var w := _at("gate")
	w.exploration.add_clue("a")
	w.exploration.add_clue("b")
	ExplorationSystem.choose(w, route, "decipher", content)
	check.call(w.relationships.has_flag("pass_secret_known") and w.exploration.clues.size() == 3 and w.player.get_attr("insight") == 6, "end: the wise ending sets the secret flag, a third clue and +1 insight")
	# Ending on day 7 slot 2 finishes the week.
	var last := _at("gate")
	last.calendar.day = 7
	last.calendar.slot = 2
	var rl: Dictionary = ExplorationSystem.choose(last, route, "pass_through", content)
	check.call(rl.time.finished and last.calendar.finished, "end: ending on the last slot finishes the week")
	# Choosing when not exploring is refused.
	var idle := _g()
	check.call(not ExplorationSystem.choose(idle, route, "old_road", content).ok, "end: choosing while not exploring is refused")


func _recruit_hooks() -> void:
	var g := _at("old_road")
	var r: Dictionary = ExplorationSystem.choose(g, route, "greet", content)
	check.call(r.recruit == "lu_chenzhou" and g.exploration.pending_recruit == "lu_chenzhou", "recruit: the courier node raises a pending invitation for Lu")
	g.relationships.set_status("lu_chenzhou", "joined")
	g.exploration.node = "old_road"
	ExplorationSystem.choose(g, route, "greet", content)
	check.call(g.exploration.pending_recruit == "", "recruit: no prompt for someone already in the party")
	var h := _at("ridge")
	var rh: Dictionary = ExplorationSystem.choose(h, route, "look_down", content)
	check.call(rh.recruit == "bai_yan", "recruit: the lookout raises Bai's invitation (he will likely refuse)")
	h.relationships.set_flag("bai_expelled")
	h.exploration.node = "ridge"
	check.call(ExplorationSystem.choose(h, route, "look_down", content).recruit == "", "recruit: an unavailable companion raises no prompt")


func _persistence() -> void:
	var g := _at("stream", 5)
	ExplorationSystem.choose(g, route, "rest", content)
	g.exploration.add_clue("torn_letter")
	var back := GameState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check.call(back.exploration.active and back.exploration.node == "gate" and back.exploration.clues == ["torn_letter"], "persist: a mid-route save resumes on the same node with its clues")
	check.call(JSON.stringify(back.to_dict(), "", true) == JSON.stringify(g.to_dict(), "", true), "persist: exploration state round-trips exactly")
	var half := {"exploration": {"active": true, "route": "", "node": ""}}
	check.call(not GameState.from_dict(half).exploration.active, "persist: a half-written active route is dropped")
	var junk := GameState.from_dict({"exploration": {"clues": [1, "ok", "ok"], "completed": "x", "history": [3]}})
	check.call(junk.exploration.clues == ["ok"] and junk.exploration.completed.is_empty(), "persist: junk values are filtered out")
	var svc := SaveService.new()
	var old: Dictionary = GameState.new_game(4).to_dict()
	old.erase("exploration")
	var m := svc.migrate(old, 3)
	check.call(m.exploration.active == false and GameState.SCHEMA_VERSION >= 4, "migration v3->v4: exploration gets an inactive default")
	svc.free()


## M8-11: every (node, choice, outcome) in Bamboo Pass is executed at least once.
func _branch_coverage() -> void:
	var total := 0
	var covered := 0
	var missed: Array = []
	for n in route.nodes:
		for c in n.get("choices", []):
			var outcomes: Array = ["none"] if not c.has("check") else ["success", "failure"]
			for oc in outcomes:
				total += 1
				var hit := false
				for s in 300:
					var g := _at(n.id, s)
					g.player.attributes["body"] = 9
					g.resources.amounts["food"] = 5
					g.exploration.add_clue("a")
					g.exploration.add_clue("b")
					var r: Dictionary = ExplorationSystem.choose(g, route, str(c.id), content)
					if r.ok and r.grade == oc:
						hit = true
						break
				if hit:
					covered += 1
				else:
					missed.append("%s/%s/%s" % [n.id, c.id, oc])
	check.call(covered == total, "coverage: %d of %d branches executed %s" % [covered, total, str(missed)])
	print("BRANCH_COVERAGE %d/%d" % [covered, total])


func _playthroughs() -> void:
	# A cautious run: old road, greet, travel on, gate, plain ending.
	var g := _g(9)
	g.player.stamina = 30
	ExplorationSystem.start(g, route, content)
	for step in ["old_road", "greet", "travel_on", "pass_through"]:
		var r: Dictionary = ExplorationSystem.choose(g, route, step, content)
		check.call(r.ok, "playthrough A: '%s' works" % step)
	check.call(not g.exploration.active and g.exploration.history == ["start", "old_road", "courier", "gate", "end_plain"], "playthrough A: history lists the nodes visited")
	# A thorough run: ridge, lookout, talk, gate with clues, wise ending.
	var h := _g(9)
	h.player.stamina = 30
	h.player.attributes["body"] = 6
	ExplorationSystem.start(h, route, content)
	for step2 in ["ridge", "look_down", "talk_scholar"]:
		check.call(ExplorationSystem.choose(h, route, step2, content).ok, "playthrough B: '%s' works" % step2)
	check.call(ExplorationSystem.choose(h, route, "decipher", content).ok == false, "playthrough B: one clue is not enough for the gate")
	h.exploration.add_clue("extra")
	check.call(ExplorationSystem.choose(h, route, "decipher", content).ok and h.relationships.has_flag("pass_secret_known"), "playthrough B: two clues open the wise ending")
