extends RefCounted
## M16 tests: the event engine (areas, fixed windows, random pools, follow-ups, leads, missed events, validator)
## and a random-walk fuzzer that plays whole campaigns through the Game API.

const GameState = preload("res://scripts/domain/game_state.gd")
const SaveService = preload("res://scripts/services/save_service.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const WorldState = preload("res://scripts/domain/world_state.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var game: Node
var saves: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	game = Engine.get_main_loop().root.get_node("Game")
	saves = Engine.get_main_loop().root.get_node("Saves")
	_state_and_migration()
	_areas()
	_fixed_and_followups()
	_random_and_cooldown()
	_effects_and_miss()
	_validator()
	var old_dir: String = saves.dir
	saves.dir = "user://m16_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	_fuzz()
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir
	game.battle = null


func _fresh(week: int = 6) -> RefCounted:
	var s: RefCounted = GameState.new_game(5)
	s.calendar.week = week
	return s


func _state_and_migration() -> void:
	var w: RefCounted = WorldState.new()
	w.done["a"] = 3
	w.missed.append("b")
	w.scheduled["c"] = {"from": 4, "to": 9}
	w.add_lead("l1")
	w.add_lead("l1")
	w.areas_open.append("x")
	var r: RefCounted = WorldState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	check.call(JSON.stringify(r.to_dict()) == JSON.stringify(w.to_dict()), "m16: world state survives a JSON round trip")
	check.call(w.leads.size() == 1 and w.has_lead("l1"), "m16: a lead is only recorded once")
	var svc: Node = SaveService.new()
	var m: Dictionary = svc.migrate({"calendar": {"week": 3, "slot": 1}}, 7)
	check.call(m.has("world") and m.world.done.is_empty(), "m16: a v7 save gains an empty world section")
	var st: RefCounted = GameState.from_dict(m)
	check.call(st.world.leads.is_empty(), "m16: and loads with it")
	svc.free()


func _areas() -> void:
	var s := _fresh(6)
	check.call(WorldRules.area_status(s, content, "valley_village").state == "open", "m16: the village is open from the start")
	check.call(WorldRules.area_status(s, content, "old_shrine").state == "locked", "m16: the shrine is locked until the story opens it")
	check.call(WorldRules.area_status(s, content, "ghost_town").state == "closed", "m16: an unknown area is closed")
	s.calendar.week = 50  # winter of year 1 (weeks 46-60)
	check.call(s.calendar.season() == 3, "m16: week 50 is winter")
	check.call(WorldRules.area_status(s, content, "herb_terraces").state == "locked", "m16: the terraces are closed in winter")
	s.calendar.week = 12
	check.call(WorldRules.area_status(s, content, "herb_terraces").state == "open", "m16: and open in spring")
	check.call(WorldRules.area_status(s, content, "ferry_dock").state == "locked", "m16: the ferry needs a lead")
	s.world.add_lead("ferry_rumor")
	check.call(WorldRules.area_status(s, content, "ferry_dock").state == "open", "m16: the lead opens the ferry %s" % str(WorldRules.area_status(s, content, "ferry_dock")))
	check.call(int(WorldRules.area_status(s, content, "ferry_dock").cost) == 2, "m16: the ferry costs two slots")
	WorldRules.apply_effect(s, {"type": "unlock_area", "id": "old_shrine"}, content)
	check.call(WorldRules.area_status(s, content, "old_shrine").state == "open", "m16: unlock_area opens the shrine")
	WorldRules.apply_effect(s, {"type": "lock_area", "id": "old_shrine"}, content)
	check.call(WorldRules.area_status(s, content, "old_shrine").state == "closed", "m16: lock_area closes it for good")
	var p: Dictionary = WorldRules.pick(s, content, "old_shrine")
	check.call(not p.ok and not p.reasons.is_empty(), "m16: a closed area cannot be visited and says why")


func _fixed_and_followups() -> void:
	var s := _fresh(5)
	var p: Dictionary = WorldRules.pick(s, content, "valley_village")
	check.call(p.ok and p.event.get("id", "") != "f_aftermath", "m16: before its window the aftermath event does not appear")
	s.calendar.week = 7
	p = WorldRules.pick(s, content, "valley_village")
	check.call(p.ok and str(p.event.get("id", "")) == "f_aftermath", "m16: inside its window a fixed event takes priority over random ones")
	var p2: Dictionary = WorldRules.pick(s, content, "valley_village")
	check.call(str(p2.event.get("id", "")) == str(p.event.get("id", "")), "m16: picking is deterministic for the same week and slot")
	check.call(WorldRules.pick(s, content, "river_bend").event.get("id", "").begins_with("f_") == false, "m16: a fixed event only shows in its own area")
	# Play it out: follow-ups get scheduled.
	game.new_game(21)
	game.state.calendar.week = 7
	var v: Dictionary = game.visit_area("valley_village")
	check.call(v.ok and v.event_id == "f_aftermath" and v.scene == "dialogue", "m16: visiting opens the fixed event scene")
	_finish_dialogue(false)
	var st: RefCounted = game.state
	check.call(st.world.done.has("f_aftermath") and st.world.scheduled.has("f_gossip"), "m16: finishing it records it and schedules the follow-up")
	var sch: Dictionary = st.world.scheduled.f_gossip
	check.call(int(sch.from) == st.calendar.week - 0 + 1 - 0 or int(sch.from) >= 8, "m16: the follow-up window opens after the current week")
	check.call(WorldRules.pick(st, content, "valley_village").event.get("id", "") != "f_aftermath", "m16: a finished fixed event does not repeat")
	st.calendar.week = int(sch.from)
	var v2: Dictionary = game.visit_area("valley_village")
	check.call(v2.event_id == "f_gossip", "m16: the follow-up plays when its window opens")
	_finish_dialogue(false)
	check.call(st.world.has_lead("shrine_rumor") and st.world.areas_open.has("old_shrine") and st.world.scheduled.has("f_shrine_first"), "m16: it grants a lead, opens the shrine and schedules the next scene")
	check.call(WorldRules.area_status(st, content, "old_shrine").state == "open", "m16: the shrine can now be visited")
	st.calendar.week = int(st.world.scheduled.f_shrine_first.from)
	var v3: Dictionary = game.visit_area("old_shrine")
	check.call(v3.event_id == "f_shrine_first", "m16: the shrine scene plays")
	_finish_dialogue(true)
	check.call(st.world.done.has("f_shrine_first") and st.world.has_lead("ferry_rumor"), "m16: finishing the shrine scene adds the ferry lead")
	game.battle = null


func _random_and_cooldown() -> void:
	var s := _fresh(20)
	var ids := {}
	for wk in range(20, 60):
		s.calendar.week = wk
		s.calendar.slot = 1 + wk % 2
		var p: Dictionary = WorldRules.pick(s, content, "valley_village")
		ids[str(p.event.get("id", "wander"))] = true
	check.call(ids.size() >= 2, "m16: over time the village gives varied results (%s)" % ", ".join(ids.keys()))
	var s2 := _fresh(20)
	WorldRules.complete_event(s2, content, "r_elder_lesson")
	check.call(int(s2.world.cooldown.r_elder_lesson) == 35, "m16: a repeatable event goes on cooldown")
	s2.calendar.week = 25
	check.call(not WorldRules._playable(s2, content, content.event("r_elder_lesson")), "m16: it cannot return during its cooldown")
	s2.calendar.week = 36
	check.call(WorldRules._playable(s2, content, content.event("r_elder_lesson")), "m16: and returns after it")
	var s3 := _fresh(20)
	s3.calendar.week = 20
	check.call(not WorldRules._playable(s3, content, content.event("r_winter_frost")), "m16: the winter event is out of season in spring")
	s3.calendar.week = 50
	check.call(WorldRules._playable(s3, content, content.event("r_winter_frost")), "m16: and playable in winter")


func _effects_and_miss() -> void:
	var s := _fresh(5)
	s.calendar.week = 8
	WorldRules.apply_effect(s, {"type": "schedule", "id": "f_gossip", "min": 2, "max": 5}, content)
	check.call(s.world.scheduled.f_gossip.from == 10 and s.world.scheduled.f_gossip.to == 13, "m16: schedule is relative to the current week")
	check.call(not WorldRules.apply_effect(s, {"type": "flag", "id": "x"}, content), "m16: other effects fall through")
	var s2 := _fresh(21)
	WorldRules.sweep_missed(s2, content)
	check.call(s2.world.missed.has("f_aftermath") and s2.world.missed.has("f_herb_lesson"), "m16: a passed window marks the event missed")
	check.call(s2.world.missed.has("f_spring_fair") and s2.relationships.has_flag("fair_missed"), "m16: missing the fair runs its on_miss effect")
	WorldRules.sweep_missed(s2, content)
	var n: int = s2.world.missed.size()
	WorldRules.sweep_missed(s2, content)
	check.call(s2.world.missed.size() == n, "m16: sweeping twice changes nothing")
	var s3 := _fresh(30)
	s3.world.scheduled["f_gossip"] = {"from": 31, "to": 33}
	WorldRules.sweep_missed(s3, content)
	check.call(not s3.world.missed.has("f_gossip"), "m16: a scheduled event is not missed before its window ends")
	s3.calendar.week = 34
	WorldRules.sweep_missed(s3, content)
	check.call(s3.world.missed.has("f_gossip"), "m16: but is missed after")
	var rep: Dictionary = WorldRules.flag_report(content)
	check.call(rep.unset.is_empty(), "m16: every flag that is read is set somewhere %s" % str(rep.unset))


func _validator() -> void:
	var has_key := func(k: String) -> bool: return Engine.get_main_loop().root.get_node("Loc").has_key(k)
	var c: Node = ContentService.new()
	c.load_all()
	check.call(c.validate(has_key).is_empty(), "m16: shipped content validates (%s)" % str(c.validate(has_key)))
	c.events.append({"id": "bad", "kind": "fixed", "area": "nowhere", "scene": {"dialogue": "none"}})
	c.events.append({"id": "bad2", "kind": "random", "area": "valley_village", "window": {"from": 9, "to": 3}, "scene": {"dialogue": "ev_r_village_chat"}})
	var errs: Array = c.validate(has_key)
	var joined := "\n".join(errs)
	check.call(joined.contains("event bad: unknown area") and joined.contains("event bad: a fixed event needs") and joined.contains("event bad: scene dialogue missing"), "m16: validator catches a bad fixed event")
	check.call(joined.contains("event bad2"), "m16: validator catches a reversed window")
	c.free()


# ---- helpers ----------------------------------------------------------------

func _finish_dialogue(win: bool) -> void:
	var guard := 0
	while guard < 30 and game.state.story.dialogue.size() > 0:
		guard += 1
		var dlg: Dictionary = game.current_dialogue()
		var node: Dictionary = DialogueSystem.current_node(game.state, dlg)
		var res: Dictionary
		if node.has("choices"):
			var pick := ""
			for c in DialogueSystem.choice_states(game.state, dlg, content):
				if c.available and pick == "":
					pick = c.id
			res = game.dialogue_choose(pick)
		else:
			res = game.dialogue_advance()
		if res.get("ended", false):
			var nxt: String = game.after_dialogue(res)
			if nxt == "battle":
				game.battle.outcome = "victory" if win else "defeat"
				game.finish_battle()
			return


func _fuzz() -> void:
	var seeds := [1, 2, 3, 4, 5, 6]
	var total_done := 0
	var total_missed := 0
	for sd in seeds:
		game.new_game(sd)
		game.battle = null
		var rng := RandomNumberGenerator.new()
		rng.seed = sd * 7919
		var steps := 0
		var visits := 0
		var ended := false
		var stuck := false
		while steps < 3000:
			steps += 1
			var dest: String = game.next_story_scene()
			if dest == "ending":
				ended = true
				break
			if dest == "dialogue":
				_fuzz_dialogue(rng)
				continue
			if dest == "battle":
				game.battle.outcome = "victory" if rng.randf() < 0.6 else "defeat"
				game.finish_battle()
				continue
			var pending: Array = game.pending_events()
			if not pending.is_empty():
				game.acknowledge_event(str(pending[0].id))
				continue
			if game.state.calendar.finished:
				stuck = true
				break
			if rng.randf() < 0.55:
				var open: Array = []
				for aid in WorldRules.area_ids(content):
					if WorldRules.area_status(game.state, content, aid).state == "open":
						open.append(aid)
				if not open.is_empty():
					var v: Dictionary = game.visit_area(str(open[rng.randi_range(0, open.size() - 1)]))
					visits += 1
					continue
			game.perform_activity("rest")
			if steps % 40 == 0 and game.battle == null and game.state.story.dialogue.is_empty():
				var before := JSON.stringify(game.state.to_dict())
				game.autosave()
				game.load_latest()
				check.call(JSON.stringify(game.state.to_dict()) == before, "m16: fuzz seed %d reloads identically at step %d" % [sd, steps])
		check.call(ended and not stuck, "m16: fuzz seed %d reaches the ending (steps %d, visits %d)" % [sd, steps, visits])
		var w: RefCounted = game.state.world
		WorldRules.sweep_missed(game.state, content)
		var unresolved: Array = []
		for ev in content.events:
			if str(ev.kind) == "fixed" and not w.done.has(str(ev.id)) and not w.missed.has(str(ev.id)):
				if ev.has("window") or w.scheduled.has(str(ev.id)):
					unresolved.append(str(ev.id))  # a dormant follow-up whose parent never happened is fine; anything else is a bug
		check.call(unresolved.is_empty(), "m16: fuzz seed %d leaves every fixed event done or missed %s" % [sd, str(unresolved)])
		total_done += w.done.size()
		total_missed += w.missed.size()
		print("FUZZ seed=%d steps=%d visits=%d done=%d missed=%d leads=%s ending=%s" % [sd, steps, visits, w.done.size(), w.missed.size(), str(w.leads), game.state.story.ending])
	check.call(total_done > 0, "m16: fuzz runs completed events (%d done, %d missed)" % [total_done, total_missed])
	game.battle = null


func _fuzz_dialogue(rng: RandomNumberGenerator) -> void:
	var dlg: Dictionary = game.current_dialogue()
	var inner := 0
	var res: Dictionary = {}
	while inner < 40:
		inner += 1
		var node: Dictionary = DialogueSystem.current_node(game.state, dlg)
		if node.has("choices"):
			var avail: Array = []
			for c in DialogueSystem.choice_states(game.state, dlg, content):
				if c.available:
					avail.append(c.id)
			if avail.is_empty():
				check.call(false, "m16: fuzz found a dialogue node with no available choice (%s/%s)" % [str(dlg.id), str(node.get("id", ""))])
				return
			res = game.dialogue_choose(str(avail[rng.randi_range(0, avail.size() - 1)]))
		else:
			res = game.dialogue_advance()
		if res.get("ended", false):
			break
	if not res.get("ended", false):
		check.call(false, "m16: fuzz dialogue %s never ended" % str(dlg.id))
		game.state.story.dialogue = {}
		return
	var nxt: String = game.after_dialogue(res)
	if nxt == "battle":
		game.battle.outcome = "victory" if rng.randf() < 0.6 else "defeat"
		game.finish_battle()
