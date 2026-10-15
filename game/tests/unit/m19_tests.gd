extends RefCounted
## M19 tests: activity clips, the minigame framework and fishing (replayed with scripted input), result scaling.

const ClipRules = preload("res://scripts/domain/clip_rules.gd")
const MinigameRules = preload("res://scripts/domain/minigame_rules.gd")
const FishingGame = preload("res://scripts/domain/minigames/fishing_game.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const GameState = preload("res://scripts/domain/game_state.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	_clips()
	_grades()
	_fishing()
	_perform_with_play()
	content.free()


func _clips() -> void:
	check.call(content.clips.size() == content.activities.size(), "m19: every activity has exactly one clip (%d)" % content.clips.size())
	var clip: Dictionary = content.clip_for("training")
	check.call(ClipRules.key_at(clip, 0.0).pose == "idle" and ClipRules.key_at(clip, 1.0).pose == "train" and ClipRules.key_at(clip, 2.3).face == "happy", "m19: a clip is sampled by time")
	check.call(ClipRules.key_at({}, 1.0).pose == "idle", "m19: an empty clip falls back to idle")
	var bad := {"id": "x", "bg": "nowhere", "duration": 9.0, "keys": [{"t": 1.0, "pose": "fly"}, {"t": 0.5, "pose": "idle", "face": "?"}]}
	check.call(ClipRules.problems(bad).size() >= 4, "m19: a bad clip is reported")
	for c in content.clips:
		check.call(ClipRules.problems(c).is_empty(), "m19: clip %s is valid" % c.id)
		check.call(float(c.duration) <= 3.0, "m19: clip %s is short enough to be skippable fluff (%.1fs)" % [c.id, float(c.duration)])


func _grades() -> void:
	check.call(MinigameRules.grade_of(0.95) == "perfect" and MinigameRules.grade_of(0.9) == "perfect" and MinigameRules.grade_of(0.7) == "good" and MinigameRules.grade_of(0.3) == "ok" and MinigameRules.grade_of(0.1) == "poor", "m19: scores map to grades")
	check.call(MinigameRules.multiplier_of("perfect") > MinigameRules.multiplier_of("good") and MinigameRules.multiplier_of("good") > MinigameRules.multiplier_of("ok") and MinigameRules.multiplier_of("ok") > MinigameRules.multiplier_of("poor"), "m19: better grades pay more")
	var q := MinigameRules.play_record("fishing", 0.0, true)
	check.call(q.grade == MinigameRules.QUICK_GRADE and q.quick and q.mult == 1.0, "m19: quick resolve pays like an average attempt")
	check.call(MinigameRules.seed_for(5, 3, 1, "fishing") == MinigameRules.seed_for(5, 3, 1, "fishing") and MinigameRules.seed_for(5, 3, 1, "fishing") != MinigameRules.seed_for(5, 3, 2, "fishing"), "m19: the seed depends on the run and the moment")
	check.call(MinigameRules.difficulty_for({"target_delta": -1}) == 0 and MinigameRules.difficulty_for({"target_delta": 1}) == 2 and MinigameRules.difficulty_for({}) == 1, "m19: the riskier approach is harder")
	check.call(MinigameRules.create("fishing") != null and MinigameRules.create("nope") == null, "m19: the registry creates known minigames only")
	var m: Dictionary = content.minigame_for("fishing")
	check.call(str(m.id) == "fishing" and content.minigame_for("rest").is_empty(), "m19: the registry maps fishing to its minigame")


## A simple player: hold when the fish is above the middle of the bar.
func _bot_play(seed_value: int, difficulty: int, use_bot: bool) -> RefCounted:
	var g: RefCounted = FishingGame.new()
	g.start({"difficulty": difficulty}, seed_value)
	var i := 0
	while not g.done and i < 60 * 30:
		i += 1
		if use_bot:
			g.set_input("hold", g.fish > g.hook + g.bar * 0.5)
		g.step(1.0 / 60.0)
	return g


func _fishing() -> void:
	var a := _bot_play(11, 1, true)
	var b := _bot_play(11, 1, true)
	check.call(a.result() == b.result() and a.progress == b.progress and a.time_left == b.time_left, "m19: the same seed and inputs replay identically")
	var caught := {0: 0, 1: 0, 2: 0}
	var idle_fail := 0
	var total := 20
	for sd in range(1, total + 1):
		for d in [0, 1, 2]:
			if _bot_play(sd, d, true).caught:
				caught[d] += 1
		var idle := _bot_play(sd, 1, false)
		if idle.done and not idle.caught and idle.result().score < 0.3:
			idle_fail += 1
	check.call(caught[0] >= 16, "m19: a competent player usually lands easy fish (%d/%d)" % [caught[0], total])
	check.call(caught[1] >= 12, "m19: and normal fish (%d/%d)" % [caught[1], total])
	check.call(caught[2] >= 4 and caught[2] <= caught[0], "m19: hard fish are harder but possible (%d/%d)" % [caught[2], total])
	check.call(idle_fail == total, "m19: doing nothing never catches anything (%d/%d)" % [idle_fail, total])
	var g: RefCounted = FishingGame.new()
	g.start({"difficulty": 1}, 3)
	for i in range(60 * 40):
		g.set_input("hold", (i / 30) % 2 == 0)
		g.step(1.0 / 60.0)
		var s: Dictionary = g.snapshot()
		if not (s.hook >= 0.0 and s.hook <= 1.0 - s.bar + 0.0001 and s.fish >= 0.0 and s.fish <= 1.0 and s.progress >= 0.0 and s.progress <= 1.0):
			check.call(false, "m19: fishing state stays in range")
			return
	check.call(g.done and g.result().score >= 0.0 and g.result().score <= 1.0, "m19: a long wiggly play stays in range and ends")
	var t: RefCounted = FishingGame.new()
	t.start({"difficulty": 0}, 1)
	for i in range(60 * 21):
		t.step(1.0 / 60.0)
	check.call(t.done and t.time_left <= 0.0 or t.escaped or t.caught, "m19: the time limit ends the play")


func _perform_with_play() -> void:
	var def: Dictionary = content.activity("fishing")
	var base: RefCounted = GameState.new_game(9)
	base.calendar.week = 3
	var s1: RefCounted = GameState.new_game(9)
	s1.calendar.week = 3
	var r1: Dictionary = ActivityRules.perform(s1, def, content, "still_water", MinigameRules.play_record("fishing", 0.95))
	var s2: RefCounted = GameState.new_game(9)
	s2.calendar.week = 3
	var r2: Dictionary = ActivityRules.perform(s2, def, content, "still_water", MinigameRules.play_record("fishing", 0.0))
	var s3: RefCounted = GameState.new_game(9)
	s3.calendar.week = 3
	var r3: Dictionary = ActivityRules.perform(s3, def, content, "still_water", MinigameRules.play_record("fishing", 0.0, true))
	check.call(r1.ok and r1.has("play") and r1.grade == "success" and r1.check.is_empty(), "m19: a play record replaces the skill check")
	check.call(r2.grade == "partial", "m19: a poor play counts as a partial result")
	var food := func(r: Dictionary) -> int:
		var n := 0
		for d in r.deltas:
			if d.type == "resource" and d.id == "food":
				n += int(d.delta)
		return n
	check.call(food.call(r1) > food.call(r3) and food.call(r3) > food.call(r2), "m19: perfect pays more than quick resolve, which pays more than poor (%d > %d > %d)" % [food.call(r1), food.call(r3), food.call(r2)])
	check.call(food.call(r2) >= 1, "m19: even a poor play pays at least 1")
	var plain: Dictionary = ActivityRules.perform(GameState.new_game(9), def, content, "still_water")
	check.call(not plain.get("play", null) and plain.has("check"), "m19: without a play record the old skill check still applies")
