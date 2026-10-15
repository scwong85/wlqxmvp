extends RefCounted
## M11 tests: companion abilities and bond abilities in battle, companion only when active, result application
## (rewards, penalties, flags, medicine), saving and resuming an interrupted battle, schema migration.

const Battle = preload("res://scripts/domain/combat/battle.gd")
const CombatUnit = preload("res://scripts/domain/combat/combat_unit.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const BattleResult = preload("res://scripts/domain/combat/battle_result.gd")
const GameState = preload("res://scripts/domain/game_state.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const ContentService = preload("res://scripts/services/content_service.gd")
const SaveService = preload("res://scripts/services/save_service.gd")

var check: Callable
var loc: Node
var content: Node


func run(check_fn: Callable, loc_service: Node) -> void:
	check = check_fn
	loc = loc_service
	content = ContentService.new()
	content.load_all()
	_abilities()
	_bond_abilities()
	_active_only()
	_results()
	_snapshot()
	_session_resume()


func _pair(techs: Array, foe_hp: int = 100) -> Array:
	var b := Battle.new(content)
	b.max_rounds = 10
	b.objective = {"defeat_all": true}
	var a := _mk("a", "player", Vector2i(2, 4), 9, techs, 60)
	var ally := _mk("ally", "player", Vector2i(2, 5), 3, [], 60)
	var foe := _mk("foe", "enemy", Vector2i(2, 2), 1, [], foe_hp)
	b.units.append_array([a, ally, foe])
	b.start()
	return [b, a, ally, foe]


func _mk(id: String, team: String, pos: Vector2i, agility: int, techs: Array, hp: int) -> RefCounted:
	var u := CombatUnit.new()
	u.id = id
	u.team = team
	u.pos = pos
	u.max_hp = hp
	u.hp = hp
	u.agility = agility
	u.tp = 20
	u.max_resolve = 10
	u.resolve = 10
	u.techniques = techs
	return u


func _abilities() -> void:
	# every companion's two battle abilities exist as technique data and execute
	var seen := 0
	for cid in content.companion_ids():
		for ab in content.companion(cid).battle_abilities:
			var t: Dictionary = content.combat_tech(str(ab))
			check.call(not t.is_empty(), "m11: %s ability %s exists as technique data" % [cid, ab])
			var p := _pair([str(ab)])
			var b: RefCounted = p[0]
			var ally: RefCounted = p[2]
			var foe: RefCounted = p[3]
			ally.hp = 30
			ally.resolve = 2
			ally.add_status("bleed", 2)
			foe.pos = Vector2i(2, 3)
			foe.broken = str(ab) == "ambush_strike"
			var target: String = "ally" if t.kind == "support" else "foe"
			var hp_f: int = foe.hp
			var r: Dictionary = b.support("a", str(ab), target) if t.kind == "support" else b.attack("a", str(ab), target)
			check.call(r.ok, "m11: ability %s executes (%s)" % [ab, r.get("reason", "")])
			match str(ab):
				"herb_poultice":
					check.call(ally.hp == 42, "m11: herb poultice heals 12")
				"calming_incense":
					check.call(ally.resolve == 7 and ally.statuses.is_empty(), "m11: calming incense restores resolve and cleanses")
				"swift_dash":
					check.call(hp_f - foe.hp > 0, "m11: swift dash hits")
				"ambush_strike":
					check.call(hp_f - foe.hp > 12, "m11: ambush strike punishes a broken foe")
				"binding_script":
					check.call(foe.has_status("slow"), "m11: binding script slows")
				"counter_notes":
					check.call(foe.has_status("weaken"), "m11: counter notes weakens")
			seen += 1
	check.call(seen == 6, "m11: six companion abilities covered")


func _bond_abilities() -> void:
	# gentle hands
	var p := _pair(["gentle_hands"])
	var b: RefCounted = p[0]
	var a: RefCounted = p[1]
	var ally: RefCounted = p[2]
	ally.hp = 20
	ally.add_status("bleed", 2)
	check.call(b.support("a", "gentle_hands", "ally").ok and ally.hp == 30 and ally.statuses.is_empty(), "m11: gentle hands heals 10 and cleanses")
	check.call(a.ap == 1, "m11: a bond ability costs no action")
	check.call(b.support("a", "gentle_hands", "ally").reason == "already_used", "m11: once per battle")
	check.call(b.guard("a").ok, "m11: the normal action is still available afterwards")
	# courier's shortcut
	var p2 := _pair(["couriers_shortcut"])
	var b2: RefCounted = p2[0]
	var a2: RefCounted = p2[1]
	var mp0: int = a2.mp
	check.call(b2.support("a", "couriers_shortcut", "a").ok and a2.mp == mp0 + 3 and a2.ap == 1, "m11: courier's shortcut gives +3 movement for free")
	check.call(b2.support("a", "couriers_shortcut", "ally").reason in ["out_of_range", "already_used"], "m11: it is a self ability and works once")
	# margin notes
	var p3 := _pair(["margin_notes"])
	var b3: RefCounted = p3[0]
	var a3: RefCounted = p3[1]
	var foe3: RefCounted = p3[3]
	var res0: int = foe3.resolve
	check.call(b3.attack("a", "margin_notes", "foe").ok and foe3.has_status("weaken") and foe3.resolve < res0 and a3.ap == 1, "m11: margin notes marks a foe for free")
	check.call(b3.attack("a", "margin_notes", "foe").reason == "already_used", "m11: margin notes once per battle")
	# can_use mirrors the rules
	check.call(not b3.can_use(a3, "margin_notes") and b3.can_use(a3, "basic_attack"), "m11: can_use reports used bond abilities")
	# the AI uses them sensibly
	var p4 := _pair(["gentle_hands"])
	p4[2].hp = 20
	check.call(BattleAI.free_actions(p4[0]).size() == 1 and BattleAI.free_actions(p4[0])[0].tech == "gentle_hands", "m11: AI heals a hurt ally with the bond ability")
	var p5 := _pair(["margin_notes"])
	check.call(BattleAI.free_actions(p5[0]).size() == 1, "m11: AI marks a foe in range")
	p5[3].add_status("weaken", 2)
	check.call(BattleAI.free_actions(p5[0]).is_empty(), "m11: AI does not re-mark a weakened foe")


func _state_with(active: String, score: int) -> RefCounted:
	var st: RefCounted = GameState.new_game(1)
	st.relationships.set_status("shen_qinghe", "joined")
	st.relationships.scores["shen_qinghe"] = score
	if active != "":
		PartySystem.set_active(st, active)
	return st


func _active_only() -> void:
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	var saves: Node = Engine.get_main_loop().root.get_node("Saves")
	var old_dir: String = saves.dir
	saves.dir = "user://m11_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	game.state = _state_with("", 9)
	game.start_battle("bandit_scouts", "practice")
	check.call(game.battle.unit("shen_qinghe") == null, "m11: a joined companion who is not active stays out of the fight")
	game.state = _state_with("shen_qinghe", 9)
	game.start_battle("bandit_scouts", "practice")
	var shen: RefCounted = game.battle.unit("shen_qinghe")
	check.call(shen != null and shen.team == "player" and shen.techniques.has("herb_poultice"), "m11: the active companion fights beside the hero")
	check.call(shen.techniques.has("gentle_hands"), "m11: a strong bond unlocks the bond ability")
	game.state = _state_with("shen_qinghe", 6)
	game.start_battle("bandit_scouts", "practice")
	check.call(not game.battle.unit("shen_qinghe").techniques.has("gentle_hands"), "m11: a weak bond does not")
	saves.dir = old_dir
	game.battle = null


func _results() -> void:
	var sc: Dictionary = content.scenario("bandit_scouts")
	var st := _state_with("shen_qinghe", 6)
	st.resources.add("medicine", 2)
	var coins0: int = st.resources.get_amount("coins")
	var score0: int = st.relationships.get_score("shen_qinghe")
	var res: Dictionary = BattleResult.apply(st, sc, "victory", {"medicine": 1}, content)
	check.call(st.resources.get_amount("coins") == coins0 + 8 and st.relationships.get_score("shen_qinghe") == score0 + 1, "m11: victory pays coins and strengthens the bond with the active companion")
	check.call(st.relationships.has_flag("scouts_beaten") and res.flags == ["scouts_beaten"], "m11: victory sets its story flag")
	check.call(st.resources.get_amount("medicine") == 1, "m11: medicine used in the fight is spent")
	var st2 := _state_with("", 6)
	var stam0: int = st2.player.stamina
	var res2: Dictionary = BattleResult.apply(st2, sc, "defeat", {}, content)
	check.call(st2.player.stamina == stam0 - 3 and st2.relationships.has_flag("scouts_won") and not st2.relationships.has_flag("scouts_beaten"), "m11: defeat costs stamina and sets its own flag")
	var st3 := _state_with("", 6)
	BattleResult.apply(st3, sc, "victory", {}, content)
	check.call(st3.relationships.get_score("shen_qinghe") == 6, "m11: with no active companion the bond reward is skipped")
	var st4 := _state_with("shen_qinghe", 6)
	var res4: Dictionary = BattleResult.apply(st4, sc, "", {}, content)
	check.call(res4.deltas.is_empty() and not st4.relationships.has_flag("scouts_beaten"), "m11: an abandoned fight pays nothing")
	# the result round-trips through a save
	var svc := SaveService.new()
	svc.dir = "user://m11_saves/"
	DirAccess.make_dir_recursive_absolute(svc.dir)
	svc.write_slot("m11.json", st, "en")
	var back: Dictionary = svc.read_slot("m11.json")
	check.call(back.ok and back.state.relationships.has_flag("scouts_beaten") and back.state.resources.get_amount("coins") == st.resources.get_amount("coins"), "m11: battle results survive a save and load")
	svc.delete_slot("m11.json")
	# every scenario has data for both outcomes except the plain training match
	for s in content.scenarios:
		if s.id != "training_match":
			check.call(s.has("on_victory") and s.has("on_defeat"), "m11: scenario %s defines both results" % s.id)


func _finish(b: RefCounted) -> void:
	var g := 0
	while b.outcome == "" and g < 300:
		g += 1
		BattleAI.take_turn(b)


func _snapshot() -> void:
	var b: RefCounted = BattleSetup.build(content, "rescue_battle", 11, null, ["shen_qinghe"])
	for i in 7:
		BattleAI.take_turn(b)
	var snap: Dictionary = JSON.parse_string(JSON.stringify(b.to_dict()))  # through real JSON text
	var restored: RefCounted = BattleSetup.rebuild(content, snap)
	check.call(restored != null and restored.state_hash() == b.state_hash(), "m11: a battle restored from JSON is identical")
	check.call(restored.active() != null and restored.active().id == b.active().id, "m11: the same unit is up after restoring")
	_finish(b)
	_finish(restored)
	check.call(b.state_hash() == restored.state_hash() and b.outcome == restored.outcome, "m11: restored and original battles finish identically")
	# mid-turn: after a move and with a follow-up pending
	var c: RefCounted = BattleSetup.build(content, "training_match", 3, null, ["shen_qinghe"])
	c.pending_followups.append({"unit": "shen_qinghe", "target": "training_fighter_1"})
	var r2: RefCounted = BattleSetup.rebuild(content, JSON.parse_string(JSON.stringify(c.to_dict())))
	check.call(r2.pending_followups.size() == 1 and r2.state_hash() == c.state_hash(), "m11: pending follow-ups and action points survive")
	check.call(BattleSetup.rebuild(content, {}) == null and BattleSetup.rebuild(content, {"scenario": "nope"}) == null, "m11: empty or unknown snapshots are refused")
	var bad: Dictionary = JSON.parse_string(JSON.stringify(b.to_dict()))
	bad.units = []
	check.call(BattleSetup.rebuild(content, bad) == null, "m11: a snapshot with no units is refused")
	bad = JSON.parse_string(JSON.stringify(c.to_dict()))
	bad.units[0].pos = [9, 9]
	check.call(BattleSetup.rebuild(content, bad) == null, "m11: a snapshot with a unit off the board is refused")
	var svc := SaveService.new()
	check.call(svc.migrate({"exploration": {}}, 4).get("battle", null) == {}, "m11: migration v4 -> v5 adds an empty battle snapshot")
	check.call(GameState.SCHEMA_VERSION >= 5 and GameState.from_dict({}).battle.is_empty(), "m11: schema 5 and tolerant loading")


func _session_resume() -> void:
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	var saves: Node = Engine.get_main_loop().root.get_node("Saves")
	var old_dir: String = saves.dir
	saves.dir = "user://m11_saves/"
	DirAccess.make_dir_recursive_absolute(saves.dir)
	game.state = _state_with("shen_qinghe", 9)
	game.state.exploration.active = true
	game.state.exploration.pending_battle = "bandit_scouts"
	check.call(game.start_battle("bandit_scouts", "exploration"), "m11: story battle starts")
	check.call(not game.state.battle.is_empty(), "m11: a story battle is saved the moment it starts")
	var u: RefCounted = game.battle.active()
	for i in 4:
		BattleAI.take_turn(game.battle)
		game.save_battle_progress()
	var hash_before: String = game.battle.state_hash()
	# "close the game": load the autosave into a fresh session
	var loaded: Dictionary = saves.load_latest()
	check.call(loaded.ok, "m11: the autosave loads")
	game.state = loaded.state
	game.battle = null
	check.call(game.has_saved_battle(), "m11: after loading, an interrupted battle is waiting")
	check.call(game.resume_battle() and game.battle.state_hash() == hash_before, "m11: resuming restores exactly the saved battle")
	check.call(game.battle_ctx.from == "exploration" and game.state.exploration.pending_battle == "bandit_scouts", "m11: the story trigger is still pending while fighting")
	# finishing settles once and clears everything
	_finish(game.battle)
	var res: Dictionary = game.apply_battle_result()
	check.call(game.state.battle.is_empty() and game.state.exploration.pending_battle == "", "m11: the result clears the snapshot and the trigger")
	check.call(game.apply_battle_result().deltas.is_empty(), "m11: a result is applied only once")
	check.call(game.state.relationships.has_flag("scouts_beaten") or game.state.relationships.has_flag("scouts_won"), "m11: the result flag is set (%s)" % game.battle.outcome)
	var again: Dictionary = saves.load_latest()
	check.call(again.ok and again.state.battle.is_empty(), "m11: the saved game no longer holds the battle")
	game.finish_battle()
	# a damaged snapshot is dropped instead of trapping the player
	game.state.battle = {"scenario": "bandit_scouts", "units": []}
	check.call(game.has_saved_battle() and not game.resume_battle() and game.state.battle.is_empty(), "m11: an unusable snapshot is discarded")
	for f in DirAccess.get_files_at(saves.dir):
		DirAccess.remove_absolute(saves.dir.path_join(f))
	saves.dir = old_dir
	game.battle = null
