extends RefCounted
## Week hooks: story beats that fire when a week starts. A hook due in week N is still due in any later
## week until acknowledged, so it can never be skipped by loading or jumping time.


static func pending(state: RefCounted, content: Object) -> Array:
	var out: Array = []
	for h in content.day_hooks:
		if int(h.week) <= state.calendar.week and not state.calendar.events_fired.has(h.id):
			out.append(h)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.week) < int(b.week))
	return out


static func mark_fired(state: RefCounted, hook_id: String) -> bool:
	if hook_id == "" or state.calendar.events_fired.has(hook_id):
		return false
	state.calendar.events_fired.append(hook_id)
	return true


## The opening month is over and its climax (the bandit chief's attack) is waiting to be played.
static func crisis_pending(state: RefCounted) -> bool:
	return state.calendar.slots_used() >= state.calendar.PROLOGUE_WEEKS * state.calendar.SLOTS and not state.calendar.events_fired.has(PROLOGUE_CRISIS)


const PROLOGUE_CRISIS := "prologue_crisis"
