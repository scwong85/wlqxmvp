extends RefCounted
## Minigame results to activity outcomes: grade and reward multiplier, the quick-resolve value, and seeds.

const FishingGame = preload("res://scripts/domain/minigames/fishing_game.gd")

const MiningGame = preload("res://scripts/domain/minigames/mining_game.gd")
const MusicGame = preload("res://scripts/domain/minigames/music_game.gd")

const GRADES := ["poor", "ok", "good", "perfect"]
const THRESHOLDS := {"perfect": 0.9, "good": 0.6, "ok": 0.3}
const MULTIPLIERS := {"poor": 0.5, "ok": 1.0, "good": 1.25, "perfect": 1.5}
const QUICK_GRADE := "ok"        # skipping the minigame pays like an average attempt


static func create(minigame_id: String) -> RefCounted:
	match minigame_id:
		"fishing":
			return FishingGame.new()
		"mining":
			return MiningGame.new()
		"music":
			return MusicGame.new()
	return null


static func grade_of(score: float) -> String:
	for g in ["perfect", "good", "ok"]:
		if score >= float(THRESHOLDS[g]):
			return g
	return "poor"


static func multiplier_of(grade: String) -> float:
	return float(MULTIPLIERS.get(grade, 1.0))


## The play record handed to ActivityRules.perform.
static func play_record(minigame_id: String, score: float, quick: bool = false) -> Dictionary:
	var grade := QUICK_GRADE if quick else grade_of(score)
	return {"minigame": minigame_id, "score": snappedf(score, 0.01), "grade": grade, "mult": multiplier_of(grade), "quick": quick}


## Difficulty from the chosen option (the riskier option is harder).
static func difficulty_for(def: Dictionary) -> int:
	var d := int(def.get("target_delta", 0))
	return clampi(d + 1, 0, 2)


static func seed_for(run_seed: int, week: int, slot: int, activity_id: String) -> int:
	return hash("%d:%d:%d:%s" % [run_seed, week, slot, activity_id])
