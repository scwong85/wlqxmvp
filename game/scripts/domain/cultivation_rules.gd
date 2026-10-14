extends RefCounted
## Derived values from the five attributes (plan section 6). Pure functions.

static func max_health(p: RefCounted) -> int:
	return 50 + p.get_attr("body") * 5


static func max_stamina(p: RefCounted) -> int:
	return 10 + p.get_attr("body") + p.get_attr("insight")


static func initiative(p: RefCounted, modifiers: int = 0) -> int:
	return p.get_attr("agility") + modifiers


static func technique_points(p: RefCounted, training_bonus: int = 0) -> int:
	return p.get_attr("insight") + training_bonus


## Keeps current stamina inside 0..max (max can change when Body or Insight grows).
static func clamp_stamina(p: RefCounted) -> void:
	p.stamina = clampi(p.stamina, 0, max_stamina(p))
