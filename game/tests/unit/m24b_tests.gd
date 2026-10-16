extends RefCounted
## M24b tests: Year 2 quarter 6 (weeks 76 to 90): Yanmen, Xiao Hanchuan, the pass battle, Su Dai's and Li Shan's stage 2.

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
	_xiao()
	_arcs()
	content.free()


func _fresh(seed_value: int) -> RefCounted:
	game.new_game(seed_value)
	var s: RefCounted = game.state
	for h in content.day_hooks:
		s.calendar.events_fired.append(str(h.id))
	s.calendar.events_fired.append("prologue_crisis")
	s.world.add_lead("linjiang_token")
	s.world.add_lead("cangwu_invite")
	s.world.add_lead("yanmen_road")
	return s


func _data() -> void:
	check.call(["ym_fort", "ym_road", "ym_pass", "ym_field"].all(func(id: String) -> bool: return content.area(id).region == "yanmen"), "m24b: four Yanmen areas")
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 80
	check.call(WorldRules.area_status(s, content, "ym_fort").state == "locked", "m24b: Yanmen is locked without the letter's lead")
	s.world.add_lead("yanmen_road")
	check.call(WorldRules.area_status(s, content, "ym_fort").state == "open", "m24b: and opens with it")
	s.calendar.week = 70
	check.call(WorldRules.area_status(s, content, "ym_fort").state == "locked", "m24b: but not before week 76")
	for b in ["y2_xiao_spar", "y2_snow_pass", "y2_pass_battle"]:
		check.call(not content.scenario(b).is_empty(), "m24b: scenario %s exists" % b)


func _chain() -> void:
	var s: RefCounted = _fresh(90)
	s.calendar.week = 77
	var ev := _play("ym_road", "shelter")
	check.call(ev == "y2_road_north" and s.world.has_lead("fort_road") and s.world.scheduled.has("y2_xiao_hanchuan"), "m24b: the storm scene plays and schedules Xiao (got '%s')" % ev)
	_jump("y2_xiao_hanchuan")
	ev = _play("ym_fort", "show")
	check.call(ev == "y2_xiao_hanchuan" and s.world.has_lead("fort_trust") and s.relationships.get_score("xiao_hanchuan") >= 3, "m24b: Xiao questions the hero at the gate (got '%s')" % ev)
	_jump("y2_fort_orders")
	ev = _play("ym_fort", "tell")
	check.call(ev == "y2_fort_orders" and s.relationships.has_flag("orders_exposed"), "m24b: the garrison's orders scene plays (got '%s')" % ev)
	_jump("y2_snow_pass")
	ev = _play("ym_pass", "fight")
	check.call(ev == "y2_snow_pass" and s.relationships.has_flag("pass_raid_won"), "m24b: the snow pass escort is fought (got '%s')" % ev)
	_jump("y2_pass_battle")
	ev = _play("ym_field", "fight")
	check.call(ev == "y2_pass_battle" and s.relationships.has_flag("pass_won"), "m24b: the battle for the pass is won (got '%s')" % ev)
	game.battle = null


func _xiao() -> void:
	var c: Dictionary = content.companion("xiao_hanchuan")
	check.call(not c.is_empty() and not content.look_of("xiao_hanchuan").is_empty() and c.battle_abilities.size() == 2, "m24b: Xiao has data, a look and two abilities")
	check.call(not content.duo_for("xiao_hanchuan").is_empty(), "m24b: Xiao has a duo technique")
	var s: RefCounted = GameState.new_game(5)
	s.calendar.week = 76
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("xiao_hanchuan") == "unknown", "m24b: Xiao is not met before week 78")
	s.calendar.week = 82
	RelationshipRules.refresh(s, content)
	check.call(s.relationships.get_status("xiao_hanchuan") == "available", "m24b: Xiao is met by week 82")
	var g: RefCounted = _fresh(91)
	g.calendar.week = 84
	g.relationships.add_score("xiao_hanchuan", 4)
	var ev := ""
	for i in 4:
		ev = _play("ym_fort", "")
		if ev == "arc_xiao_hanchuan_1":
			break
	check.call(ev == "arc_xiao_hanchuan_1" and ArcRules.stage(g, "xiao_hanchuan") == 1, "m24b: Xiao's stage 1 plays (got '%s')" % ev)
	game.battle = null


func _arcs() -> void:
	var s: RefCounted = _fresh(92)
	s.calendar.week = 82
	s.relationships.add_score("su_dai", 9)
	s.relationships.arcs["su_dai"] = {"stage": 1}
	var ev := ""
	for i in 4:
		ev = _play("ym_road", "")
		if ev == "arc_su_dai_2":
			break
	check.call(ev == "arc_su_dai_2" and ArcRules.stage(s, "su_dai") == 2 and s.world.has_lead("song_second_verse"), "m24b: Su Dai's stage 2 plays (got '%s')" % ev)
	s.relationships.add_score("li_shan", 9)
	s.relationships.arcs["li_shan"] = {"stage": 1}
	ev = ""
	for i in 4:
		ev = _play("ym_road", "")
		if ev == "arc_li_shan_2":
			break
	check.call(ev == "arc_li_shan_2" and ArcRules.stage(s, "li_shan") == 2 and s.world.has_lead("northern_ore"), "m24b: Li Shan's stage 2 plays (got '%s')" % ev)
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
