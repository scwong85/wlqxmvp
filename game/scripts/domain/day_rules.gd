extends RefCounted
## Time passing. One call per used activity slot.

const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")


## Advances the calendar. On a new day, recovers half of max stamina (rounded up).
## Returns {advanced, new_week, finished, recovered, autosave_due, expired_buffs}.
static func end_slot(state: RefCounted) -> Dictionary:
	var adv: Dictionary = state.calendar.advance_slot()
	var out := {"advanced": adv.advanced, "new_week": adv.new_week, "finished": adv.finished,
			"recovered": 0, "autosave_due": adv.advanced, "expired_buffs": []}
	if adv.advanced:
		out.expired_buffs = state.player.tick_buffs()
	if adv.new_week:
		var max_st: int = CultivationRules.max_stamina(state.player)
		var before: int = state.player.stamina
		state.player.stamina = mini(max_st, before + ceili(max_st / 2.0))
		out.recovered = state.player.stamina - before
	return out
