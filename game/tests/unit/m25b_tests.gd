extends RefCounted
## M25b tests: Year 3 quarter 10 (weeks 136 to 150): the vault areas, the stars of the companions, the second gate, the Xuan-Mask, the ninth star,
## the collapse, stage 4 for Su Dai, Li Shan and Xiao Hanchuan, and a 150-week random walk.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var game: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	_data()
	_areas()
	_scenes()
	_stage4()
	_fuzz()
	content.free()


func _fresh(seed_value: int, week: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	for l in ["linjiang_token", "cangwu_invite", "penglai_route", "yanmen_road", "vault_second_gate"]:
		s.world.add_lead(l)
	s.calendar.week = week
	return s


func _data() -> void:
	for id in ["y3b_fragments", "y3b_star_song", "y3b_star_forge", "y3b_star_pattern", "y3b_second_gate", "y3b_xuan_mask", "y3b_ninth_star", "y3b_vault_collapse", "arc_su_dai_4", "arc_li_shan_4", "arc_xiao_hanchuan_4"]:
		check.call(not content.event(id).is_empty(), "m25b: event %s exists" % id)
	for b in ["y3_vault_guardian", "y3_vault_collapse"]:
		check.call(not content.scenario(b).is_empty(), "m25b: scenario %s exists" % b)
	for a in ["sv_stair", "sv_hall", "sv_door"]:
		check.call(not content.area(a).is_empty(), "m25b: area %s exists" % a)
	for cid in ["su_dai", "li_shan", "xiao_hanchuan", "xie_wujiu", "xia_zhi", "shen_qinghe", "lu_chenzhou", "bai_yan"]:
		check.call(ArcRules.arc_of(content, cid).stages.size() == 4, "m25b: %s has all four arc stages" % cid)
	var randoms: Array = content.events.filter(func(e: Dictionary) -> bool: return str(e.id).begins_with("ry10_"))
	check.call(randoms.size() == 8, "m25b: eight random templates for the quarter")


func _areas() -> void:
	var s: RefCounted = _fresh(300, 120)
	check.call(WorldRules.area_status(s, content, "sv_stair").state != "open", "m25b: the vault stair is closed before week 136")
	s.calendar.week = 137
	check.call(WorldRules.area_status(s, content, "sv_stair").state == "open", "m25b: the vault stair opens at week 136 with the lead")
	check.call(WorldRules.area_status(s, content, "sv_hall").state != "open", "m25b: the star hall stays closed until the second gate is open")
	s.relationships.set_flag("second_gate_open")
	check.call(WorldRules.area_status(s, content, "sv_hall").state == "open" and WorldRules.area_status(s, content, "sv_door").state == "open", "m25b: the hall and door open with the second gate")


func _scene(area: String, week: int, flags: Array, pick: String, expect: String, label: String, extra: Callable = Callable()) -> RefCounted:
	var s: RefCounted = _fresh(301, week)
	for f in flags:
		s.relationships.set_flag(str(f))
	if extra.is_valid():
		extra.call(s)
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == expect:
			break
	check.call(ev == expect, "m25b: %s plays (got '%s')" % [label, ev])
	game.battle = null
	return s


func _scenes() -> void:
	var s := _scene("lj_teahouse", 137, [], "", "y3b_fragments", "the star count")
	check.call(s.relationships.has_flag("fragments_counted"), "m25b: the count is recorded")
	s = _scene("lj_market", 140, [], "", "y3b_star_song", "the star in the song", func(st: RefCounted) -> void: st.relationships.add_score("su_dai", 10))
	check.call(s.relationships.has_flag("star_song"), "m25b: Su Dai's star is found")
	s = _fresh(304, 140)
	s.relationships.set_flag("song_sold")
	s.relationships.add_score("su_dai", 10)
	for i in 3:
		_play("lj_market", "")
	check.call(not s.relationships.has_flag("star_song"), "m25b: a sold song yields no star")
	game.battle = null
	s = _scene("lj_docks", 140, [], "", "y3b_star_forge", "the star under the furnace", func(st: RefCounted) -> void: st.relationships.add_score("li_shan", 10))
	check.call(s.relationships.has_flag("star_forge"), "m25b: Li Shan's star is found")
	s = _scene("cw_library", 140, [], "", "y3b_star_pattern", "the star in the script", func(st: RefCounted) -> void: st.relationships.add_score("bai_yan", 10))
	check.call(s.relationships.has_flag("star_pattern"), "m25b: Bai Yan's star is found")
	s = _scene("sv_stair", 140, [], "tally", "y3b_second_gate", "the second gate (tally)")
	check.call(s.relationships.has_flag("second_gate_open") and s.relationships.has_flag("vault_tally_used"), "m25b: the tally opens the gate")
	s = _scene("sv_stair", 140, [], "force", "y3b_second_gate", "the second gate (force)")
	check.call(s.relationships.has_flag("second_gate_open") and s.relationships.has_flag("guardian_won"), "m25b: forcing the gate wins the guardian fight")
	for pick in ["accept", "refuse", "deceive"]:
		s = _scene("sv_hall", 144, ["second_gate_open"], pick, "y3b_xuan_mask", "the Xuan-Mask (%s)" % pick)
		var f: String = {"accept": "xuan_pact", "refuse": "xuan_refused", "deceive": "xuan_deceived"}[pick]
		check.call(s.relationships.has_flag(f), "m25b: the Xuan-Mask's offer '%s' sets %s" % [pick, f])
	s = _scene("sv_door", 146, ["second_gate_open"], "", "y3b_ninth_star", "the ninth star")
	check.call(s.relationships.has_flag("ninth_star_read") and s.world.has_lead("manual_truth"), "m25b: the ninth fragment is read")
	s = _scene("sv_door", 148, ["second_gate_open", "ninth_star_read"], "hold", "y3b_vault_collapse", "the collapse (hold)")
	check.call(s.relationships.has_flag("star_kept"), "m25b: holding the door keeps the star")
	s = _scene("sv_door", 148, ["second_gate_open", "ninth_star_read"], "run", "y3b_vault_collapse", "the collapse (run)")
	check.call(s.relationships.has_flag("star_lost"), "m25b: running loses the star")


func _stage4_case(cid: String, area: String, week: int, outcome: String, pick: String, expect_bond: String, bond_score: int) -> void:
	var s: RefCounted = _fresh(303, week)
	s.relationships.add_score(cid, bond_score)
	s.relationships.arcs[cid] = {"stage": 3, "outcome": outcome, "bond": ""}
	if outcome != "":
		s.relationships.set_flag("arcout_%s_%s" % [cid, outcome])
	for n in [1, 2, 3]:
		s.world.done["arc_%s_%d" % [cid, n]] = 1
	var ev := ""
	for i in 4:
		ev = _play(area, pick)
		if ev == "arc_%s_4" % cid:
			break
	var rec: Dictionary = s.relationships.arcs.get(cid, {})
	check.call(ev == "arc_%s_4" % cid and ArcRules.stage(s, cid) == 4 and str(rec.get("bond", "")) == expect_bond, "m25b: %s stage 4 (%s, '%s') records bond '%s' (got '%s', %s)" % [cid, outcome, pick, expect_bond, ev, str(rec)])
	game.battle = null


func _stage4() -> void:
	_stage4_case("su_dai", "lj_market", 142, "redeemed", "romance", "romance", 20)
	_stage4_case("su_dai", "lj_market", 142, "alternate", "sworn", "sworn", 20)
	_stage4_case("li_shan", "lj_docks", 140, "redeemed", "sworn", "sworn", 20)
	_stage4_case("li_shan", "lj_docks", 140, "alternate", "friend", "friend", 12)
	_stage4_case("xiao_hanchuan", "ym_fort", 144, "redeemed", "romance", "romance", 20)
	_stage4_case("xiao_hanchuan", "ym_fort", 144, "alternate", "rival", "rival", 8)
	for cid in ["su_dai", "li_shan", "xiao_hanchuan"]:
		var area: String = {"su_dai": "lj_market", "li_shan": "lj_docks", "xiao_hanchuan": "ym_fort"}[cid]
		var s: RefCounted = _fresh(302, 144)
		s.relationships.add_score(cid, 8)
		s.relationships.arcs[cid] = {"stage": 3, "outcome": "lost", "bond": ""}
		s.relationships.set_flag("arcout_%s_lost" % cid)
		for n in [1, 2, 3]:
			s.world.done["arc_%s_%d" % [cid, n]] = 1
		var ev := ""
		for i in 4:
			ev = _play(area, "")
			if ev == "arc_%s_4" % cid:
				break
		var returns: String = {"su_dai": "su_returns", "li_shan": "li_returns", "xiao_hanchuan": "xiao_returns"}[cid]
		check.call(ev == "arc_%s_4" % cid and ArcRules.stage(s, cid) == 4 and s.relationships.has_flag(returns) and ArcRules.bond_type(s, cid) == "", "m25b: %s's farewell closes a lost arc (got '%s')" % [cid, ev])
		game.battle = null


## A random walk through years 1 to 3 up to week 150.
func _fuzz() -> void:
	game.new_game(32)
	var s: RefCounted = game.state
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var guard := 0
	var seen := {}
	while s.calendar.week <= 150 and guard < 5000 and not s.calendar.finished:
		guard += 1
		if s.player.stamina < 8:
			game.perform_activity("rest")
			continue
		var open: Array = []
		for a in content.areas:
			if WorldRules.area_status(s, content, str(a.id)).state == "open":
				open.append(str(a.id))
		if open.is_empty() or rng.randf() < 0.25:
			game.perform_activity("training")
			continue
		var ev := _play(str(open[rng.randi() % open.size()]), "")
		if ev != "":
			seen[ev] = true
	check.call(s.calendar.week > 150 or guard >= 5000, "m25b: fuzz reaches week %d (%d steps)" % [s.calendar.week, guard])
	var y3: Array = seen.keys().filter(func(k: String) -> bool: return k.begins_with("y3") or k.begins_with("ry9_") or k.begins_with("ry10_") or k.ends_with("_4"))
	check.call(y3.size() >= 3, "m25b: the walk meets some year-3 scenes (%d)" % y3.size())
	game.battle = null


## Visits an area and plays whatever event is offered, picking `pick` where there is a choice. Returns the event id.
func _play(area: String, pick: String) -> String:
	var v: Dictionary = game.visit_area(area)
	if not v.ok or v.event_id == "":
		return ""
	var guard := 0
	while guard < 30 and game.state.story.dialogue.size() > 0:
		guard += 1
		var dlg: Dictionary = game.current_dialogue()
		var node: Dictionary = DialogueSystem.current_node(game.state, dlg)
		var res: Dictionary
		if node.has("choices"):
			var choice := ""
			var first := ""
			for c in DialogueSystem.choice_states(game.state, dlg, content):
				if c.available and first == "":
					first = c.id
				if c.available and c.id == pick:
					choice = c.id
			res = game.dialogue_choose(choice if choice != "" else first)
		else:
			res = game.dialogue_advance()
		if res.get("ended", false):
			var nxt: String = game.after_dialogue(res)
			if nxt == "battle":
				game.battle.outcome = "victory"
				game.finish_battle()
			break
	return str(v.event_id)


func _jump(event_id: String) -> void:
	var sch: Variant = game.state.world.scheduled.get(event_id)
	if sch != null:
		game.state.calendar.week = maxi(game.state.calendar.week, int(sch.from))
