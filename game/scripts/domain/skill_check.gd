extends RefCounted
## Deterministic skill checks. The same (run seed, key, attribute, target) always gives the same result,
## so saves reload into identical outcomes and tests never flake.

const BASE_CHANCE := 60
const PER_POINT := 12
const MIN_CHANCE := 5
const MAX_CHANCE := 95


static func chance(attr_value: int, target: int) -> int:
	return clampi(BASE_CHANCE + (attr_value - target) * PER_POINT, MIN_CHANCE, MAX_CHANCE)


static func roll(seed_value: int, key: String) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%s" % [seed_value, key])
	return rng.randi_range(1, 100)


## Returns {success, roll, chance}. Success when roll <= chance.
static func check(attr_value: int, target: int, seed_value: int, key: String) -> Dictionary:
	var c := chance(attr_value, target)
	var r := roll(seed_value, key)
	return {"success": r <= c, "roll": r, "chance": c}
