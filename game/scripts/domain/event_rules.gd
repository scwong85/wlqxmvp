extends RefCounted
## Day hooks: story beats that fire when a day starts. A hook due on day N is still due on any later
## day until acknowledged, so it can never be skipped by loading or jumping time.


static func pending(state: RefCounted, content: Object) -> Array:
	var out: Array = []
	for h in content.day_hooks:
		if int(h.day) <= state.calendar.day and not state.calendar.events_fired.has(h.id):
			out.append(h)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.day) < int(b.day))
	return out


static func mark_fired(state: RefCounted, hook_id: String) -> bool:
	if hook_id == "" or state.calendar.events_fired.has(hook_id):
		return false
	state.calendar.events_fired.append(hook_id)
	return true


## The week is over and the final crisis is waiting to be resolved.
static func crisis_pending(state: RefCounted) -> bool:
	return state.calendar.finished
