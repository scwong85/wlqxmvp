extends RefCounted
## The companion invitation dialog, shared by the training screen (day-3 hook) and exploration encounters.
## `build` returns {} when the companion cannot be invited at all; otherwise {overlay, accept, decline}
## (accept is null when the conditions are not met yet). `on_done` is called after either button.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")


static func reason_text(reasons: Array) -> String:
	var out: Array = []
	for r in reasons:
		var params: Dictionary = (r.params as Dictionary).duplicate()
		if params.has("attr"):
			params["attr"] = Loc.t("attr." + str(params.attr))
		if params.has("npc"):
			params["npc"] = Loc.t("npc." + str(params.npc))
		out.append(Loc.t(r.key, params))
	return Loc.t("ui.list_sep").join(out)


static func build(npc_id: String, on_done: Callable) -> Dictionary:
	var ev: Dictionary = RelationshipRules.evaluate_recruitment(Game.state, npc_id, Content)
	if ev.result == "unavailable":
		return {}
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var name_text: String = Loc.t("npc." + npc_id)
	var title := UiKit.make_label(28)
	title.text = Loc.t("recruit.title", {"name": name_text})
	box.add_child(title)
	var body := UiKit.make_label(24)
	body.text = Loc.t("recruit.body_ready", {"name": name_text}) if ev.result == "ready" else Loc.t("recruit.body_refuse", {"name": name_text, "list": reason_text(ev.reasons)})
	box.add_child(body)
	var accept: Button = null
	if ev.result == "ready":
		accept = UiKit.make_button(Vector2(0, 60))
		accept.text = Loc.t("recruit.accept")
		accept.add_theme_font_size_override("font_size", 24)
		accept.pressed.connect(func() -> void:
			Game.recruit_companion(npc_id)
			on_done.call())
		box.add_child(accept)
	var decline := UiKit.make_button(Vector2(0, 60))
	decline.text = Loc.t("recruit.decline")
	decline.add_theme_font_size_override("font_size", 24)
	decline.pressed.connect(func() -> void:
		Game.decline_companion(npc_id)
		on_done.call())
	box.add_child(decline)
	print("RECRUIT_PROMPT %s %s" % [npc_id, ev.result])
	return {"overlay": overlay, "accept": accept, "decline": decline}
