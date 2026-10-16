extends RefCounted
## M23 tests: the mining and music minigames (scripted play), registration, and the tournament realm gate.

const GameState = preload("res://scripts/domain/game_state.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const MinigameRules = preload("res://scripts/domain/minigame_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	var content: Node = ContentService.new()
	content.load_all()
	check.call(not content.minigame_for("mining").is_empty() and not content.minigame_for("music").is_empty(), "m23: mining and music are registered minigames")
	_mining()
	_music()
	var s: RefCounted = GameState.new_game(3)
	s.calendar.week = 40
	var req: Dictionary = content.event("q3_tournament_1").requires
	s.cultivation.realm = 1
	check.call(not WorldRules.requires_reasons(s, req, content).is_empty(), "m23: the first bout needs realm 2")
	s.cultivation.realm = 2
	s.world.add_lead("cangwu_invite")
	check.call(WorldRules.requires_reasons(s, req, content).is_empty(), "m23: and plays at realm 2")
	content.free()


func _mining() -> void:
	# Perfect play: strike each time the marker is on the vein.
	var g: RefCounted = MinigameRules.create("mining")
	g.start({"difficulty": 0}, 5)
	var guard := 0
	while not g.done and guard < 6000:
		guard += 1
		g.set_input("hold", false)
		g.step(1.0 / 120.0)
		if absf(g.marker - g.vein) < 0.01:
			g.set_input("hold", true)
	check.call(g.done and g.result().score >= 0.8, "m23: perfect mining scores high (%s)" % str(g.result().score))
	# Never tapping scores zero when the time runs out.
	var h: RefCounted = MinigameRules.create("mining")
	h.start({"difficulty": 2}, 5)
	guard = 0
	while not h.done and guard < 4000:
		guard += 1
		h.step(1.0 / 60.0)
	check.call(h.done and h.result().score == 0.0, "m23: idle mining scores zero and still ends")
	# Deterministic for a seed.
	var a: RefCounted = MinigameRules.create("mining")
	var b: RefCounted = MinigameRules.create("mining")
	a.start({}, 9)
	b.start({}, 9)
	check.call(a.vein == b.vein, "m23: mining is deterministic for a seed")


func _music() -> void:
	var g: RefCounted = MinigameRules.create("music")
	g.start({"difficulty": 1}, 7)
	var idx := 0
	var guard := 0
	while not g.done and guard < 8000:
		guard += 1
		g.set_input("hold", false)
		g.step(1.0 / 120.0)
		if idx < g.times.size() and g.t >= float(g.times[idx]):
			g.set_input("hold", true)
			idx += 1
	check.call(g.done and g.result().score >= 0.9, "m23: on-beat music scores high (%s)" % str(g.result().score))
	var h: RefCounted = MinigameRules.create("music")
	h.start({"difficulty": 0}, 7)
	guard = 0
	while not h.done and guard < 8000:
		guard += 1
		h.step(1.0 / 60.0)
	check.call(h.done and h.result().score == 0.0, "m23: silent music scores zero and still ends")
