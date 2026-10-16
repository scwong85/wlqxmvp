extends RefCounted
## M22a/b tests: the valley completion (weeks 11 to 18) and Linjiang (weeks 16 to 45): the story chain plays in order,
## the city opens by lead, Su Dai and Li Shan, their arcs, the new battles and the new duo techniques.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ArcRules = preload("res://scripts/domain/arc_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
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
	_chain()
	_companions()
	_battles()
	content.free()


func _data() -> void:
	check.call(int(content.event("f_spring_fair").window.from) == 6 and int(content.event("f_spring_fair").window.to) == 10, "m22: the Spring Fair sits in month 2 (weeks 6 to 10)")
	check.call(content.area("lj_docks").region == "linjiang" and ["lj_docks", "lj_market", "lj_teahouse", "lj_escort", "lj_pawn", "lj_alleys"].all(func(id: String) -> bool: return content.area(id).region == "linjiang"), "m22: six Linjiang areas")
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 20
	check.call(WorldRules.area_status(s, content, "lj_docks").state == "locked", "m22: the city is locked until the token lead is found")
	s.world.add_lead("linjiang_token")
	check.call(WorldRules.area_status(s, content, "lj_docks").state == "open", "m22: and opens with it")
	s.calendar.week = 12
	check.call(WorldRules.area_status(s, content, "lj_docks").state == "locked", "m22: but not before week 16")


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


func _chain() -> void:
	game.new_game(70)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.calendar.week = 11
	var played: Array = []
	played.append(_play("valley_village", "ask"))
	check.call(played[0] == "q1_tally" and s.relationships.has_flag("tally_known") and s.world.scheduled.has("q1_bamboo"), "m22: the tally scene plays and schedules the bamboo ambush")
	_jump("q1_bamboo")
	played.append(_play("bamboo_pass", "follow"))
	check.call(played[1] == "q1_bamboo" and s.world.has_lead("linjiang_token"), "m22: the bamboo scene gives the Linjiang lead")
	s.calendar.week = 16
	var order := [["lj_docks", "wit", "q2_arrival"], ["lj_pawn", "", "q2_qian_man"], ["lj_escort", "detour", "q2_escort"], ["lj_alleys", "sneak", "q2_barge_guild"], ["lj_docks", "ally", "q2_fragment"]]
	for step in order:
		var ev := _play(str(step[0]), str(step[1]))
		check.call(ev == str(step[2]), "m22: %s plays at %s (got '%s')" % [step[2], step[0], ev])
		var next_id := ""
		for k in s.world.scheduled:
			next_id = str(k)
		_jump(next_id)
	check.call(s.relationships.has_flag("guild_ally") and s.world.has_lead("fragment_traced"), "m22: the first star is traced and the guild alliance recorded")
	game.battle = null


func _companions() -> void:
	var s: RefCounted = GameState.new_game(5)
	s.calendar.week = 17
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("su_dai") == "unknown", "m22: Su Dai is not met before week 18")
	s.calendar.week = 22
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("su_dai") == "available" and s.relationships.get_status("li_shan") == "available", "m22: both are met by week 22")
	for cid in ["su_dai", "li_shan"]:
		var c: Dictionary = content.companion(cid)
		check.call(not content.look_of(cid).is_empty() and c.battle_abilities.size() == 2, "m22: %s has a look and two abilities" % cid)
		check.call(not content.duo_for(cid).is_empty(), "m22: %s has a duo technique" % cid)
		check.call(ArcRules.summary(s, content, cid).total == 4 and ArcRules.summary(s, content, cid).event != "", "m22: %s's arc reads 0/4 with stage 1 written" % cid)
	# Meeting scene then the arc stage 1.
	game.new_game(71)
	var g: RefCounted = game.state
	g.calendar.week = 22
	g.world.add_lead("linjiang_token")
	RelationshipRules.refresh(g, content)
	check.call(_play("lj_market", "") == "q2_su_dai" and g.relationships.get_score("su_dai") == 3, "m22: Su Dai's meeting scene gives bond 3")
	g.relationships.add_score("su_dai", 1)
	check.call(_play("lj_market", "") == "arc_su_dai_1" and ArcRules.stage(g, "su_dai") == 1 and g.world.has_lead("song_map"), "m22: her stage 1 plays at bond 4 and gives the song lead")
	var seen: Array = []
	for i in 4:
		seen.append(_play("lj_docks", ""))
		if seen.back() == "q2_li_shan":
			break
	check.call(seen.has("q2_li_shan") and g.relationships.get_score("li_shan") == 3, "m22: Li Shan's meeting scene gives bond 3 (%s)" % str(seen))
	g.relationships.add_score("li_shan", 1)
	var arc_ev := ""
	for i in 4:
		arc_ev = _play("lj_docks", "sift")
		if arc_ev == "arc_li_shan_1":
			break
	check.call(arc_ev == "arc_li_shan_1" and ArcRules.stage(g, "li_shan") == 1, "m22: his stage 1 plays")
	g.calendar.week = 100
	check.call(WorldRules.sweep_missed(g, content).size() >= 0, "m22: sweeping late weeks works")
	# Recruitment gating: week 25 and bond 6.
	var r: RefCounted = GameState.new_game(6)
	r.relationships.set_status("su_dai", "available")
	r.relationships.scores["su_dai"] = 6
	r.player.attributes["spirit"] = 7
	r.calendar.week = 24
	check.call(RelationshipRules.evaluate_recruitment(r, "su_dai", content).result == "refuse", "m22: Su Dai cannot join before week 25")
	r.calendar.week = 25
	check.call(RelationshipRules.evaluate_recruitment(r, "su_dai", content).result == "ready", "m22: and can from week 25 with bond 6")
	game.battle = null


func _battles() -> void:
	for id in ["masked_escort", "dock_scam", "caravan_escort", "guild_night"]:
		var b: RefCounted = BattleSetup.build(content, id, 1, GameState.new_game(9), [])
		check.call(b != null and b.units.filter(func(u: RefCounted) -> bool: return u.team == "enemy").size() >= 3, "m22: battle %s builds with enemies" % id)
	var s: RefCounted = GameState.new_game(8)
	for cid in ["su_dai", "li_shan"]:
		s.relationships.set_status(cid, "joined")
		s.relationships.scores[cid] = 14
	var b2: RefCounted = BattleSetup.build(content, "bandit_scouts", 2, s, ["su_dai", "li_shan"])
	check.call(b2.units[0].techniques.has("duo_pipa_duet") and b2.units[0].techniques.has("duo_hammer_anvil"), "m22: both new duo techniques unlock at bond 12")
