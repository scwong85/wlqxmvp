extends RefCounted
## M7 tests: companion data, preferred-activity bonus, meeting, recruitment (join / refuse / unavailable),
## departure and rejoin, one-active-companion party rules, save round trip, and a seven-day lifecycle.

const GameState = preload("res://scripts/domain/game_state.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node
var loc: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	_data()
	_preferred_bonus()
	_meeting()
	_recruitment()
	_departure_and_rejoin()
	_party()
	_persistence()
	_lifecycle()
	content.free()


func _g(seed_value: int = 7) -> RefCounted:
	var g := GameState.new_game(seed_value)
	RelationshipRules.refresh(g, content)
	return g


func _data() -> void:
	check.call(content.companions.size() >= 3 and content.companion_ids().slice(0, 3) == ["shen_qinghe", "lu_chenzhou", "bai_yan"], "companions: the original three companions exist")
	check.call(content.validate(loc.has_key).is_empty(), "companions: data validates with every translation key")
	# The validator really catches broken data.
	var saved: Array = content.companions
	var broken: Dictionary = (saved[0] as Dictionary).duplicate(true)
	broken.erase("recruit")
	broken.role = "wizard"
	broken.battle_abilities = ["herb_poultice"]
	broken.preferred_activities = ["flying"]
	content.companions = [broken]
	var errs: Array[String] = content.validate(loc.has_key)
	var text := " ".join(errs)
	check.call(text.contains("missing field 'recruit'") and text.contains("unknown role") and text.contains("two battle abilities") and text.contains("unknown preferred activity 'flying'"), "companions: validator reports missing field, role, ability count and unknown activity")
	content.companions = saved
	for id in content.companion_ids():
		var c: Dictionary = content.companion(id)
		check.call(c.battle_abilities.size() == 2 and c.relationship_ability != "" and c.portrait != "", "companions: %s has two battle abilities, a bond ability and a portrait" % id)


func _preferred_bonus() -> void:
	var g := _g()
	g.calendar.week = 2
	RelationshipRules.refresh(g, content)
	# Hunting is liked by Lu only; he is available on day 2.
	var r: Dictionary = ActivityRules.perform(g, content.activity("hunting"), content, "hare")
	check.call(g.relationships.get_score("lu_chenzhou") == 1 and g.relationships.get_score("shen_qinghe") == 0, "bonus: liked activity gives +1 bond to that companion only")
	var has_delta := false
	for d in r.deltas:
		if d.type == "relationship" and d.id == "lu_chenzhou":
			has_delta = true
	check.call(has_delta, "bonus: the bond change shows in the result")
	# Meditation is liked by Shen and Bai.
	var m := _g()
	m.calendar.week = 2
	RelationshipRules.refresh(m, content)
	ActivityRules.perform(m, content.activity("meditation"), content)
	check.call(m.relationships.get_score("shen_qinghe") == 1 and m.relationships.get_score("bai_yan") == 1, "bonus: shared preference rewards both")
	# Not met yet or gone: no bonus.
	var u := _g()
	ActivityRules.perform(u, content.activity("training"), content, "heavy_strike")
	check.call(u.relationships.get_score("lu_chenzhou") == 0, "bonus: an unmet companion gives no bonus")
	m.relationships.set_status("bai_yan", "unavailable")
	ActivityRules.perform(m, content.activity("meditation"), content)
	check.call(m.relationships.get_score("bai_yan") == 1, "bonus: an unavailable companion gives no bonus")


func _meeting() -> void:
	var g := GameState.new_game(3)
	check.call(g.relationships.get_status("shen_qinghe") == "unknown", "meeting: everyone starts unknown")
	var met := RelationshipRules.refresh(g, content)
	check.call(met == ["shen_qinghe"] and g.relationships.get_status("shen_qinghe") == "available", "meeting: Shen is met on day 1")
	check.call(RelationshipRules.refresh(g, content).is_empty(), "meeting: refresh is idempotent")
	g.calendar.week = 2
	check.call(RelationshipRules.refresh(g, content) == ["lu_chenzhou", "bai_yan"], "meeting: Lu and Bai are met on day 2")
	# Meeting also happens through activities.
	var h := GameState.new_game(3)
	var r: Dictionary = ActivityRules.perform(h, content.activity("rest"), content)
	check.call(r.met == ["shen_qinghe"], "meeting: the first activity result reports who was met")


func _ready_state(npc: String, day: int) -> RefCounted:
	var g := _g()
	g.calendar.week = day
	RelationshipRules.refresh(g, content)
	g.relationships.add_score(npc, int(content.companion(npc).recruit.score_min))
	for attr in content.companion(npc).recruit.attr_min:
		g.player.attributes[attr] = int(content.companion(npc).recruit.attr_min[attr])
	return g


func _recruitment() -> void:
	for npc in content.companion_ids():
		var day: int = int(content.companion(npc).recruit.week_min)
		var g := _ready_state(npc, day)
		check.call(RelationshipRules.evaluate_recruitment(g, npc, content).result == "ready", "recruit %s: ready when all conditions hold" % npc)
		var r: Dictionary = RelationshipRules.recruit(g, npc, content)
		check.call(r.ok and g.relationships.get_status(npc) == "joined" and g.relationships.active == npc, "recruit %s: joins and becomes active" % npc)
		check.call(RelationshipRules.evaluate_recruitment(g, npc, content).result == "unavailable", "recruit %s: cannot be invited twice" % npc)
		# Refuse cases, one condition at a time.
		var low := _ready_state(npc, day)
		low.relationships.add_score(npc, -1)
		var ev: Dictionary = RelationshipRules.evaluate_recruitment(low, npc, content)
		check.call(ev.result == "refuse" and ev.reasons[0].key == "recruit.reason.score", "recruit %s: refuses when the bond is one short" % npc)
		var early := _ready_state(npc, day - 1)
		check.call(RelationshipRules.evaluate_recruitment(early, npc, content).reasons.any(func(x: Dictionary) -> bool: return x.key == "recruit.reason.day"), "recruit %s: refuses before day %d" % [npc, day])
		var weak := _ready_state(npc, day)
		var attr: String = content.companion(npc).recruit.attr_min.keys()[0]
		weak.player.attributes[attr] = 1
		check.call(RelationshipRules.evaluate_recruitment(weak, npc, content).reasons.any(func(x: Dictionary) -> bool: return x.key == "recruit.reason.attr"), "recruit %s: refuses when %s is too low" % [npc, attr])
		var before := JSON.stringify(low.to_dict(), "", true)
		RelationshipRules.recruit(low, npc, content)
		check.call(before == JSON.stringify(low.to_dict(), "", true), "recruit %s: a refused invitation changes nothing" % npc)
	# Unavailable: not met yet, or story flag.
	var fresh := GameState.new_game(1)
	check.call(RelationshipRules.evaluate_recruitment(fresh, "shen_qinghe", content).result == "unavailable", "recruit: an unmet companion is unavailable")
	var flagged := _ready_state("lu_chenzhou", 3)
	flagged.relationships.set_flag("lu_confined")
	check.call(RelationshipRules.evaluate_recruitment(flagged, "lu_chenzhou", content).result == "unavailable", "recruit: a story flag makes a companion unavailable")
	check.call(RelationshipRules.evaluate_recruitment(flagged, "nobody", content).result == "unavailable", "recruit: unknown ids are unavailable, not a crash")
	# Declining is remembered and harmless.
	var d := _ready_state("shen_qinghe", 3)
	RelationshipRules.decline(d, "shen_qinghe")
	check.call(d.relationships.has_flag("declined_shen_qinghe") and RelationshipRules.evaluate_recruitment(d, "shen_qinghe", content).result == "ready", "recruit: declining sets a flag and can be revisited")


func _departure_and_rejoin() -> void:
	var g := _ready_state("shen_qinghe", 3)
	RelationshipRules.recruit(g, "shen_qinghe", content)
	check.call(RelationshipRules.check_departures(g, content).is_empty(), "depart: a happy companion stays")
	g.relationships.add_score("shen_qinghe", -50)
	var left := RelationshipRules.check_departures(g, content)
	check.call(left == ["shen_qinghe"] and g.relationships.get_status("shen_qinghe") == "left" and g.relationships.active == "", "depart: a bond below the limit makes them leave and frees the active slot")
	# Rejoin after the bond recovers.
	g.relationships.add_score("shen_qinghe", 60)
	check.call(RelationshipRules.evaluate_recruitment(g, "shen_qinghe", content).result == "ready", "rejoin: a left companion can be invited again once the bond recovers")
	check.call(RelationshipRules.recruit(g, "shen_qinghe", content).ok and g.relationships.active == "shen_qinghe", "rejoin: and takes the active slot again")
	# Story-flag departure is permanent while the flag stands.
	var b := _ready_state("bai_yan", 4)
	RelationshipRules.recruit(b, "bai_yan", content)
	b.relationships.set_flag("bai_expelled")
	check.call(RelationshipRules.check_departures(b, content) == ["bai_yan"], "depart: a story flag makes them leave")
	check.call(RelationshipRules.evaluate_recruitment(b, "bai_yan", content).result == "unavailable", "depart: and they cannot rejoin while the flag stands")
	# A companion who never joined cannot "depart".
	var n := _g()
	check.call(RelationshipRules.check_departures(n, content).is_empty() and n.relationships.get_status("shen_qinghe") == "available", "depart: only joined companions can leave")


func _party() -> void:
	var g := _ready_state("shen_qinghe", 4)
	g.relationships.add_score("lu_chenzhou", 6)
	g.player.attributes["agility"] = 6
	g.relationships.add_score("bai_yan", 8)
	g.player.attributes["insight"] = 7
	RelationshipRules.recruit(g, "shen_qinghe", content)
	RelationshipRules.recruit(g, "lu_chenzhou", content)
	check.call(PartySystem.roster(g, content) == ["shen_qinghe", "lu_chenzhou"], "party: several companions can be in the roster")
	check.call(PartySystem.active(g) == "shen_qinghe", "party: the first to join is active; the second takes the other place")
	check.call(PartySystem.party(g) == ["shen_qinghe", "lu_chenzhou"], "party: two companions fight together")
	check.call(PartySystem.set_active(g, "lu_chenzhou") and PartySystem.party(g).size() == 2, "party: adding someone already in the party changes nothing (never more than two)")
	check.call(not PartySystem.set_active(g, "bai_yan") and PartySystem.party(g).size() == 2, "party: cannot activate someone who has not joined")
	check.call(PartySystem.dismiss(g, "lu_chenzhou") and PartySystem.party(g) == ["shen_qinghe"] and g.relationships.get_status("lu_chenzhou") == "left", "party: dismissing a companion frees the place")
	check.call(not PartySystem.dismiss(g, "lu_chenzhou"), "party: cannot dismiss someone who is not in the party")


func _persistence() -> void:
	var g := _ready_state("shen_qinghe", 3)
	RelationshipRules.recruit(g, "shen_qinghe", content)
	var back := GameState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check.call(back.relationships.active == "shen_qinghe" and back.relationships.get_status("shen_qinghe") == "joined", "persist: party and status survive a save round trip")
	# Saves from before M7 have no active field; a save naming a non-member is repaired.
	var old: Dictionary = g.to_dict()
	old.relationships.erase("active")
	check.call(GameState.from_dict(old).relationships.active == "", "persist: older saves load with no active companion")
	var bad: Dictionary = g.to_dict()
	bad.relationships.status["shen_qinghe"] = "available"
	check.call(GameState.from_dict(bad).relationships.active == "", "persist: an active companion who is not joined is cleared on load")


## M7-10: one scripted week through the real rules. Bonds come from preferred activities and visits.
func _lifecycle() -> void:
	var g := _g(21)
	g.player.path_id = "green_sword"
	var log: Array = []
	var plan := [
		["music", "for_shen"], ["social_visit", "chat_shen"],          # day 1-2 (visit needs day 2; below we skip if blocked)
	]
	# Day 1: Shen is met. Play music for her and meditate (she likes meditation).
	ActivityRules.perform(g, content.activity("music"), content, "for_shen")
	ActivityRules.perform(g, content.activity("meditation"), content)
	check.call(g.relationships.get_score("shen_qinghe") == 4, "week: day 1 music + a liked activity = bond 4")
	# Day 2: visit her, and meditate again.
	ActivityRules.perform(g, content.activity("social_visit"), content, "chat_shen")
	check.call(g.calendar.week == 2 and g.relationships.get_score("shen_qinghe") == 8, "week: day 2 visit gives bond 8")
	ActivityRules.perform(g, content.activity("rest"), content)
	check.call(g.calendar.week == 3 and RelationshipRules.evaluate_recruitment(g, "shen_qinghe", content).result == "ready", "week: on day 3 Shen is ready (the first recruitment chance)")
	check.call(RelationshipRules.recruit(g, "shen_qinghe", content).ok, "week: Shen joins")
	# Lu is not ready (never visited): the day-3 hook can show a refusal for him.
	check.call(RelationshipRules.evaluate_recruitment(g, "lu_chenzhou", content).result == "refuse", "week: Lu refuses until his bond grows")
	# Day 3-4: neglect is harmless, but a story betrayal makes Shen leave (the second chance: lose a companion).
	g.relationships.set_flag("shen_betrayed_patients")
	var r: Dictionary = ActivityRules.perform(g, content.activity("rest"), content)
	check.call(r.departed == ["shen_qinghe"] and PartySystem.active(g) == "", "week: the story flag makes Shen leave at the end of the slot")
	# Day 5: the story is repaired, bond recovers, and she can be invited again.
	g.relationships.flags["shen_betrayed_patients"] = false
	g.relationships.add_score("shen_qinghe", 2)
	check.call(RelationshipRules.recruit(g, "shen_qinghe", content).ok, "week: Shen rejoins after the story is repaired")
	var saved := JSON.stringify(g.to_dict(), "", true)
	var loaded := GameState.from_dict(JSON.parse_string(saved))
	check.call(JSON.stringify(loaded.to_dict(), "", true) == saved, "week: final state round-trips through a save exactly")
	log.append(plan.size())
