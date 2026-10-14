extends RefCounted
## M3/M4 rule tests: derived values, skill checks, content validation, availability, performing
## activities, day transitions, event hooks, technique unlocks, a full seven-day playthrough, and
## schema v1 -> v2 save migration.

const GameState = preload("res://scripts/domain/game_state.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")
const SkillCheck = preload("res://scripts/domain/skill_check.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const TechniqueRules = preload("res://scripts/domain/technique_rules.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")
const DayRules = preload("res://scripts/domain/day_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")
const SaveService = preload("res://scripts/services/save_service.gd")

var check: Callable
var content: Node
var loc: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	_derived_values()
	_skill_check()
	_content_validation()
	_availability()
	_perform()
	_rewards_and_clamping()
	_day_transition()
	_event_hooks()
	_techniques_and_paths()
	_full_week()
	_migration()
	content.free()


func _g(seed_value: int = 7) -> RefCounted:
	return GameState.new_game(seed_value)


func _same(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(a, "", true) == JSON.stringify(b, "", true)


func _act(id: String) -> Dictionary:
	return content.activity(id)


func _derived_values() -> void:
	var g := _g()
	check.call(CultivationRules.max_health(g.player) == 75, "derived: health = 50 + body*5 (75 at body 5)")
	check.call(CultivationRules.max_stamina(g.player) == 20, "derived: stamina = 10 + body + insight (20)")
	check.call(g.player.stamina == 20, "derived: new game starts with full stamina")
	g.player.add_attr("body", 5)
	g.player.add_attr("insight", 3)
	g.player.add_attr("agility", 2)
	check.call(CultivationRules.max_health(g.player) == 100, "derived: health follows body")
	check.call(CultivationRules.max_stamina(g.player) == 28, "derived: stamina follows body and insight")
	check.call(CultivationRules.initiative(g.player, 2) == 9, "derived: initiative = agility + modifiers")
	check.call(CultivationRules.technique_points(g.player, 1) == 9, "derived: technique points = insight + bonus")
	g.player.stamina = 500
	CultivationRules.clamp_stamina(g.player)
	check.call(g.player.stamina == 28, "derived: stamina clamps to the maximum")


func _skill_check() -> void:
	var a: Dictionary = SkillCheck.check(5, 6, 123, "training:1:1")
	var b: Dictionary = SkillCheck.check(5, 6, 123, "training:1:1")
	check.call(_same(a, b), "skill check: same seed and key give the same result")
	check.call(SkillCheck.chance(5, 6) == 48 and SkillCheck.chance(8, 6) == 84, "skill check: chance = 60 + 12 per point")
	check.call(SkillCheck.chance(99, 1) == 95 and SkillCheck.chance(1, 99) == 5, "skill check: chance clamps to 5..95")
	var wins := 0
	for i in 2000:
		if SkillCheck.check(6, 6, 99, "k%d" % i).success:
			wins += 1
	check.call(wins > 1100 and wins < 1300, "skill check: success rate near 60%% over 2000 rolls (got %d)" % wins)
	var differs := false
	for i in 50:
		if SkillCheck.roll(1, "x") != SkillCheck.roll(2, "x"):
			differs = true
	check.call(differs or SkillCheck.roll(1, "x") != SkillCheck.roll(2, "x"), "skill check: seed changes the roll")


func _content_validation() -> void:
	var errs: Array[String] = content.validate(func(k: String) -> bool: return loc.has_key(k, "zh_CN"))
	for e in errs:
		print("  content problem: ", e)
	check.call(errs.is_empty(), "content: activities, paths, techniques and hooks validate (%d problems)" % errs.size())
	check.call(content.activities.size() == 12, "content: all 12 planned activities exist")
	check.call(content.paths.size() == 3 and content.techniques.size() == 6, "content: 3 paths and 6 techniques")
	# English may lag, but a name must never be missing in Mandarin; check English coverage too (we ship both).
	var en_missing := 0
	for a in content.activities:
		if not loc.has_key(a.name_key, "en") or not loc.has_key(a.desc_key, "en"):
			en_missing += 1
	check.call(en_missing == 0, "content: every activity has English text")

	# The validator must actually catch mistakes.
	var bad := ContentService.new()
	bad.activities = [
		{"id": "x", "name_key": "nope", "desc_key": "nope", "min_day": 9, "cost": {"gems": 1}, "rewards": []},
		{"id": "x", "name_key": "activity.rest", "desc_key": "activity.rest.desc", "rewards": [{"type": "attr", "id": "luck", "amount": 1}]},
	]
	bad.day_hooks = [{"id": "h", "day": 0, "trigger": "never", "payload": {}}]
	var bad_errs: Array[String] = bad.validate(func(k: String) -> bool: return loc.has_key(k, "zh_CN"))
	check.call(bad_errs.size() >= 8, "content: validator reports broken data (%d problems found)" % bad_errs.size())
	bad.free()


func _availability() -> void:
	var g := _g()
	check.call(ActivityRules.availability(g, _act("training")).ok, "availability: training open on day 1")
	var mining: Dictionary = ActivityRules.availability(g, _act("mining"))
	check.call(not mining.ok and mining.reasons == ["activity.blocked.day_gate"], "availability: mining is gated until day 2")
	var cooking: Dictionary = ActivityRules.availability(g, _act("cooking"))
	check.call(not cooking.ok and cooking.reasons == ["activity.blocked.resource"], "availability: cooking needs food")
	g.player.stamina = 2
	var tired: Dictionary = ActivityRules.availability(g, _act("training"))
	check.call(tired.reasons == ["activity.blocked.stamina"], "availability: not enough stamina")
	check.call(ActivityRules.availability(g, _act("rest")).ok, "availability: rest needs no stamina")
	g.calendar.finished = true
	check.call(ActivityRules.availability(g, _act("rest")).reasons.has("activity.blocked.finished"), "availability: nothing after day 7")
	check.call(ActivityRules.check_chance(_g(), _act("training")) == 48 and ActivityRules.check_chance(_g(), _act("rest")) == -1,
			"availability: check chance preview")


func _perform() -> void:
	var g := _g()
	var before: Dictionary = g.to_dict()
	var refused: Dictionary = ActivityRules.perform(g, _act("cooking"), content)
	check.call(not refused.ok and _same(before, g.to_dict()), "perform: a refused activity changes nothing")

	var r: Dictionary = ActivityRules.perform(g, _act("training"), content)
	check.call(r.ok and g.player.stamina == 15, "perform: stamina cost is paid (20 -> 15)")
	check.call(g.calendar.slot == 2 and g.calendar.day == 1, "perform: one slot is consumed")
	check.call(g.cultivation.practice_counts.get("training", 0) == 1, "perform: practice is recorded")
	check.call(r.grade in ["success", "partial"] and r.check.has("roll"), "perform: a check was rolled")
	var expected_power := 7 if r.grade == "success" else 6
	check.call(g.player.get_attr("power") == expected_power, "perform: %s grants power %d" % [r.grade, expected_power])
	check.call(r.cost == [{"id": "stamina", "amount": 5}], "perform: result lists what was paid")
	check.call(r.time.autosave_due and not r.time.new_day, "perform: autosave is due after a slot")

	# Same seed, same day and slot gives the same outcome; different seed can differ.
	var a := _g(11)
	var b := _g(11)
	var ra: Dictionary = ActivityRules.perform(a, _act("fishing"), content)
	var rb: Dictionary = ActivityRules.perform(b, _act("fishing"), content)
	check.call(_same(a.to_dict(), b.to_dict()) and ra.grade == rb.grade, "perform: deterministic for the same run seed")

	# Partial grade pays half, rounded up. Find a seed where training fails its check.
	var failed: RefCounted = null
	for s in 200:
		var t := _g(s)
		var res: Dictionary = ActivityRules.perform(t, _act("training"), content)
		if res.grade == "partial":
			failed = t
			break
	check.call(failed != null, "perform: a failing seed exists to test partial rewards")
	if failed != null:
		check.call(failed.player.get_attr("power") == 6 and failed.player.get_attr("body") == 6, "perform: partial pays half rounded up (power +1, body +1)")


func _rewards_and_clamping() -> void:
	var g := _g()
	g.player.attributes["power"] = 99
	var r: Dictionary = ActivityRules.perform(g, _act("training"), content)
	var power_deltas: Array = r.deltas.filter(func(d: Dictionary) -> bool: return d.type == "attr" and d.id == "power")
	check.call(power_deltas.is_empty(), "rewards: capped attribute reports no delta")
	var g2 := _g()
	g2.player.stamina = 17
	ActivityRules.perform(g2, _act("rest"), content)
	check.call(g2.player.stamina == 20, "rewards: stamina recovery stops at the maximum")
	var g3 := _g()
	var m: Dictionary = ActivityRules.perform(g3, _act("music"), content)
	check.call(g3.relationships.get_score("shen_qinghe") == 3 or g3.relationships.get_score("shen_qinghe") == 3, "rewards: music raises a relationship")
	check.call(m.deltas.any(func(d: Dictionary) -> bool: return d.type == "relationship"), "rewards: relationship change is in the result")
	var g4 := _g()
	g4.calendar.day = 2
	ActivityRules.perform(g4, _act("chess"), content)
	check.call(g4.resources.get_item("strategy_token") >= 1, "rewards: chess grants a strategy token (even on a partial)")
	var g5 := _g()
	g5.resources.add("food", 2)
	ActivityRules.perform(g5, _act("cooking"), content)
	check.call(g5.resources.get_amount("food") == 0, "rewards: cooking consumes food")
	# Practice without a path does not invent progress.
	var g6 := _g()
	ActivityRules.perform(g6, _act("technique_practice"), content)
	check.call(g6.cultivation.path_progress.is_empty(), "rewards: path progress needs a chosen path")


func _day_transition() -> void:
	var g := _g()
	g.player.stamina = 4
	var r1 := DayRules.end_slot(g)
	check.call(not r1.new_day and r1.recovered == 0 and g.player.stamina == 4, "day: no recovery between slots")
	var r2 := DayRules.end_slot(g)
	check.call(r2.new_day and r2.recovered == 10 and g.player.stamina == 14, "day: a new day restores half of max stamina (+10)")
	check.call(g.calendar.day == 2 and g.calendar.slot == 1, "day: rolls to day 2 slot 1")
	g.player.stamina = 19
	DayRules.end_slot(g)
	var r3 := DayRules.end_slot(g)
	check.call(g.player.stamina == 20 and r3.recovered == 1, "day: recovery never exceeds the maximum")


func _event_hooks() -> void:
	var g := _g()
	check.call(EventRules.pending(g, content).is_empty(), "events: nothing pending on day 1")
	g.calendar.day = 3
	var p3 := EventRules.pending(g, content)
	check.call(p3.size() == 1 and p3[0].id == "day3_recruit", "events: day 3 hook becomes due on day 3")
	check.call(p3[0].payload.type == "recruitment_opportunity", "events: day 3 payload is a recruitment stub")
	check.call(EventRules.mark_fired(g, "day3_recruit") and not EventRules.mark_fired(g, "day3_recruit"), "events: acknowledging works once")
	check.call(EventRules.pending(g, content).is_empty(), "events: a fired hook is not repeated")
	g.calendar.day = 6
	check.call(EventRules.pending(g, content).map(func(h): return h.id) == ["day6_prepare"], "events: day 6 hook due")
	g.calendar.day = 7
	var both := EventRules.pending(g, content).map(func(h): return h.id)
	check.call(both == ["day6_prepare", "day7_crisis"], "events: an unacknowledged hook is never skipped (day 6 still due on day 7)")
	check.call(not EventRules.crisis_pending(g), "events: crisis not pending before the week ends")
	g.calendar.finished = true
	check.call(EventRules.crisis_pending(g), "events: crisis is pending once the week is over")


func _techniques_and_paths() -> void:
	var g := _g()
	var t1: Dictionary = content.technique("fist_wave")
	var t2: Dictionary = content.technique("fist_counter")
	check.call(not TechniqueRules.meets(g, t1), "techniques: nothing unlocks without a chosen path")
	g.player.path_id = "xuan_fist"
	check.call(not TechniqueRules.meets(g, t1), "techniques: progress requirement not yet met")
	g.cultivation.add_progress("xuan_fist", 3)
	check.call(TechniqueRules.meets(g, t1), "techniques: unlocks at path progress 3")
	g.cultivation.add_progress("xuan_fist", 6)
	check.call(not TechniqueRules.meets(g, t2), "techniques: attribute requirement also applies (power 9)")
	g.player.attributes["power"] = 9
	check.call(TechniqueRules.meets(g, t2), "techniques: unlocks when progress and attribute are both met")
	var other: Dictionary = content.technique("sword_flash")
	g.cultivation.add_progress("green_sword", 10)
	check.call(not TechniqueRules.meets(g, other), "techniques: other paths' techniques stay locked")
	var learned := TechniqueRules.check_unlocks(g, content)
	check.call(learned == ["fist_wave", "fist_counter"] and g.player.techniques == ["fist_wave", "fist_counter"], "techniques: check_unlocks learns each once")
	check.call(TechniqueRules.check_unlocks(g, content).is_empty(), "techniques: nothing is learned twice")

	# Training toward the path's affinity advances the path.
	var h := _g()
	h.player.path_id = "xuan_fist"
	var r: Dictionary = ActivityRules.perform(h, _act("training"), content)
	var prog := int(h.cultivation.path_progress.get("xuan_fist", 0))
	check.call(prog >= 2, "paths: training power and body advances Mystic Flow Fist (progress %d)" % prog)
	check.call(r.deltas.any(func(d: Dictionary) -> bool: return d.type == "path_progress"), "paths: progress shows up in the result")
	var s := _g()
	s.player.path_id = "green_sword"
	ActivityRules.perform(s, _act("training"), content)
	check.call(int(s.cultivation.path_progress.get("green_sword", 0)) == 0, "paths: off-affinity training gives no progress")


## Plays seven days with a simple policy and checks the whole loop holds together.
func _full_week() -> void:
	var g := _g(5)
	var fired: Array = []
	var guard := 0
	while not g.calendar.finished and guard < 40:
		guard += 1
		for hook in EventRules.pending(g, content):
			EventRules.mark_fired(g, hook.id)
			fired.append(hook.id)
		var done := false
		for id in ["training", "fishing", "meditation", "rest"]:
			if ActivityRules.availability(g, _act(id)).ok:
				ActivityRules.perform(g, _act(id), content)
				done = true
				break
		if not done:
			ActivityRules.perform(g, _act("rest"), content)
	for hook in EventRules.pending(g, content):
		EventRules.mark_fired(g, hook.id)
		fired.append(hook.id)
	check.call(g.calendar.finished and g.calendar.day == 7, "week: 14 slots take the player from day 1 to the end of day 7")
	check.call(guard == 14, "week: exactly 14 activity slots were used (got %d)" % guard)
	check.call(fired == ["day3_recruit", "day6_prepare", "day7_crisis"], "week: hooks fired once each, in order")
	check.call(EventRules.crisis_pending(g), "week: final state is crisis pending")
	check.call(g.player.stamina >= 0 and g.player.stamina <= CultivationRules.max_stamina(g.player), "week: stamina stays within bounds")
	check.call(not ActivityRules.perform(g, _act("rest"), content).ok, "week: no activity can run after day 7")
	# Mid-week save and continue (M3-07).
	var h := _g(9)
	for i in 5:
		ActivityRules.perform(h, _act("rest"), content)
	EventRules.mark_fired(h, "day3_recruit")
	var restored = GameState.from_dict(JSON.parse_string(JSON.stringify(h.to_dict())))
	check.call(_same(h.to_dict(), restored.to_dict()) and restored.calendar.day == 3 and restored.calendar.slot == 2,
			"week: mid-day save restores day, slot, stamina, seed and fired events")
	var ra: Dictionary = ActivityRules.perform(h, _act("fishing"), content)
	var rb: Dictionary = ActivityRules.perform(restored, _act("fishing"), content)
	check.call(ra.grade == rb.grade and _same(h.to_dict(), restored.to_dict()), "week: a restored run continues with identical outcomes")


func _migration() -> void:
	var svc = SaveService.new()
	svc.dir = "user://unit_test_saves/"
	DirAccess.make_dir_recursive_absolute(svc.dir)
	for f in DirAccess.get_files_at(svc.dir):
		DirAccess.remove_absolute(svc.dir.path_join(f))
	# A schema v1 save exactly as M2 wrote it: no stamina, events_fired or run_seed.
	var v1_state := {
		"player": {"attributes": {"body": 8, "power": 5, "agility": 5, "insight": 6, "spirit": 5}, "path_id": "", "techniques": []},
		"calendar": {"day": 4, "slot": 2, "finished": false},
		"resources": {"amounts": {"coins": 33, "food": 1, "herbs": 0, "ore": 0, "medicine": 0}, "items": {}},
		"cultivation": {"path_progress": {}, "practice_counts": {}},
		"relationships": {"scores": {}, "status": {}, "flags": {}},
	}
	var env := {"schema_version": 1, "saved_at": 100, "locale": "zh_CN",
			"checksum": svc.checksum_of_dict(v1_state), "state": v1_state}
	var f := FileAccess.open(svc.dir + SaveService.MANUAL, FileAccess.WRITE)
	f.store_string(JSON.stringify(env))
	f.close()
	var r: Dictionary = svc.read_slot(SaveService.MANUAL)
	check.call(r.ok, "migration: a schema v1 save still loads")
	if r.ok:
		var s: RefCounted = r.state
		check.call(s.calendar.day == 4 and s.resources.get_amount("coins") == 33 and s.player.get_attr("body") == 8, "migration: v1 data is preserved")
		check.call(s.player.stamina == CultivationRules.max_stamina(s.player) and s.player.stamina == 24, "migration: stamina starts full (10 + 8 + 6 = 24)")
		check.call(s.calendar.events_fired.is_empty() and s.run_seed == 1, "migration: new fields get safe defaults")
		svc.write_slot(SaveService.MANUAL, s)
		var again: Dictionary = svc.read_slot(SaveService.MANUAL)
		var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(svc.dir + SaveService.MANUAL))
		check.call(again.ok and int(raw.schema_version) == GameState.SCHEMA_VERSION, "migration: re-saving writes the current schema version")
	check.call(svc.migrate({"a": 1}, GameState.SCHEMA_VERSION) == {"a": 1}, "migration: current-version data is left untouched")
	for fn in DirAccess.get_files_at(svc.dir):
		DirAccess.remove_absolute(svc.dir.path_join(fn))
	svc.free()
