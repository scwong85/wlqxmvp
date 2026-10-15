extends RefCounted
## Life skills: levels that grow from how often the matching hobby was practised. Derived from practice counts,
## so nothing extra is saved. Every third level adds +1 to that activity's first reward.

const SKILLS := {"fishing": ["fishing"], "mining": ["mining"], "medicine": ["herb_gathering"], "music": ["music"], "chess": ["chess"], "cooking": ["cooking"]}
## Practice count needed for level 1..10.
const COUNT_FOR_LEVEL := [0, 2, 5, 9, 14, 20, 28, 38, 50, 65]
const MAX_LEVEL := 10


static func skill_ids() -> Array:
	return SKILLS.keys()


static func count(state: RefCounted, skill_id: String) -> int:
	var n := 0
	for a in SKILLS.get(skill_id, []):
		n += int(state.cultivation.practice_counts.get(a, 0))
	return n


static func level_for_count(n: int) -> int:
	var lv := 1
	for i in COUNT_FOR_LEVEL.size():
		if n >= int(COUNT_FOR_LEVEL[i]):
			lv = i + 1
	return lv


static func level(state: RefCounted, skill_id: String) -> int:
	return level_for_count(count(state, skill_id))


## The skill an activity trains, or "".
static func skill_of_activity(activity_id: String) -> String:
	for s in SKILLS:
		if (SKILLS[s] as Array).has(activity_id):
			return s
	return ""


## Extra amount added to the activity's first positive reward.
static func reward_bonus(state: RefCounted, activity_id: String) -> int:
	var s := skill_of_activity(activity_id)
	if s == "":
		return 0
	return level(state, s) / 3
